import 'dart:io';

import 'device_stats.dart';

/// Reads the device's own vitals straight out of `/proc` and `/sys` — no extra
/// packages, since these are plain text files the kernel already exposes.
/// Every read is independently best-effort: a field that fails to parse
/// (a differently-laid-out `/proc/meminfo`, no thermal zone on this board,
/// ...) comes back null rather than taking the others down with it.
class DeviceStatsService {
  DeviceStatsService();

  bool get isSupported => Platform.isLinux;

  Future<DeviceStats> read() async {
    if (!Platform.isLinux) {
      return const DeviceStats(
        cpuTemperatureC: null,
        cpuLoadPercent: null,
        gpuLoadPercent: null,
        memoryUsedPercent: null,
        ipAddress: null,
        thermalThrottledNow: null,
        thermalThrottleFlags: null,
      );
    }

    final throttled = await _throttledRaw();
    return DeviceStats(
      cpuTemperatureC: await _cpuTemperatureC(),
      cpuLoadPercent: await _cpuLoadPercent(),
      gpuLoadPercent: await _gpuLoadPercent(),
      memoryUsedPercent: await _memoryUsedPercent(),
      ipAddress: await _ipAddress(),
      thermalThrottledNow: throttled == null ? null : (throttled & 0xF) != 0,
      thermalThrottleFlags: throttled == null ? null : _describeThrottled(throttled),
    );
  }

  /// Raw bitmask from `vcgencmd get_throttled` — only present on Raspberry
  /// Pi OS (backed by the VideoCore firmware, unrelated to the DRM/KMS
  /// display stack, so this works regardless of the display situation).
  /// Bits 0-3 (the only ones this reads) are the live state; the firmware
  /// also sets bits 16-19 as a "has this ever happened since boot" latch
  /// that only clears on reboot — deliberately not read here, since HA's
  /// own history on the resulting entities already answers "did this ever
  /// happen" without a bit that can never turn back off on its own. See
  /// https://www.raspberrypi.com/documentation/computers/os.html#get_throttled.
  Future<int?> _throttledRaw() async {
    try {
      final result = await Process.run('vcgencmd', ['get_throttled']);
      if (result.exitCode != 0) return null;
      final match = RegExp(r'throttled=0x([0-9a-fA-F]+)').firstMatch(result.stdout as String);
      if (match == null) return null;
      return int.parse(match.group(1)!, radix: 16);
    } catch (_) {
      return null; // vcgencmd isn't present outside Raspberry Pi OS
    }
  }

  static const _throttledFlagLabels = {0: 'under_voltage', 1: 'freq_capped', 2: 'throttled', 3: 'soft_temp_limit'};

  String _describeThrottled(int raw) {
    final active = [
      for (final entry in _throttledFlagLabels.entries)
        if ((raw >> entry.key) & 1 == 1) entry.value,
    ];
    return active.isEmpty ? 'none' : active.join(',');
  }

  Future<double?> _cpuTemperatureC() async {
    try {
      final raw = await File('/sys/class/thermal/thermal_zone0/temp').readAsString();
      return int.parse(raw.trim()) / 1000.0;
    } catch (_) {
      return null;
    }
  }

  /// Matches Touchkio's own `getProcessorUsage()` (`os.loadavg()[1] /
  /// os.cpus().length * 100`) exactly, column-for-column, so this app's
  /// reported CPU load is directly comparable to Touchkio's — both are the
  /// 5-minute load average as a percentage of total core count. Chosen
  /// deliberately over a true instantaneous reading (which this app used
  /// briefly) specifically so the two numbers mean the same thing side by
  /// side; it inherits load average's usual caveats (minutes-long lag,
  /// counts I/O-wait too) same as Touchkio's number does.
  Future<double?> _cpuLoadPercent() async {
    try {
      final raw = await File('/proc/loadavg').readAsString();
      final fiveMinuteAvg = double.parse(raw.trim().split(' ')[1]);
      final cores = Platform.numberOfProcessors;
      if (cores <= 0) return null;
      return (fiveMinuteAvg / cores) * 100;
    } catch (_) {
      return null;
    }
  }

  /// "<drm-client-id>/<engine>" → busy ns, from the previous read.
  final Map<String, int> _gpuPrev = {};
  DateTime? _gpuPrevAt;

  /// How busy the GPU was since the last read, from the kernel's per-client
  /// DRM accounting: `drm-engine-<engine>: <ns>` lines in `/proc/<pid>/fdinfo`
  /// for each open GPU device. Every modern driver keeps it — v3d on the Pi 5
  /// (engines bin, render, tfu, csd), panthor on the Rock 5B once its
  /// `profiling` switch is on (`device/setup.sh` turns it on at boot). The
  /// result is the busiest engine's share of the interval. Only this user's
  /// processes are readable, which on a kiosk is everything that draws:
  /// flutter-pi and the web view's WebKit processes. Null on the first read,
  /// and where no client reports engine time.
  Future<double?> _gpuLoadPercent() async {
    final now = DateTime.now();
    final current = <String, int>{};
    try {
      await for (final proc in Directory('/proc').list()) {
        final pid = proc.path.substring(6);
        if (int.tryParse(pid) == null) continue;
        try {
          await for (final fd in Directory('/proc/$pid/fdinfo').list()) {
            final info = await File(fd.path).readAsString();
            final client = RegExp(r'^drm-client-id:\s*(\d+)', multiLine: true).firstMatch(info)?.group(1);
            if (client == null) continue;
            for (final m in RegExp(r'^drm-engine-(?!capacity-)([\w-]+):\s*(\d+) ns', multiLine: true).allMatches(info)) {
              current['$client/${m.group(1)}'] = int.parse(m.group(2)!);
            }
          }
        } catch (_) {
          // Another user's process, or it exited mid-read.
        }
      }
    } catch (_) {
      return null;
    }
    final prevAt = _gpuPrevAt;
    final busyByEngine = <String, int>{};
    for (final e in current.entries) {
      // A client that appeared since the last read counts in full: all its
      // busy time falls inside the interval.
      final delta = e.value - (_gpuPrev[e.key] ?? 0);
      if (delta <= 0) continue;
      final engine = e.key.substring(e.key.indexOf('/') + 1);
      busyByEngine[engine] = (busyByEngine[engine] ?? 0) + delta;
    }
    _gpuPrev
      ..clear()
      ..addAll(current);
    _gpuPrevAt = now;
    if (prevAt == null || current.isEmpty) return null;
    final intervalNs = now.difference(prevAt).inMicroseconds * 1000;
    if (intervalNs <= 0) return null;
    final busiest = busyByEngine.values.fold(0, (a, b) => a > b ? a : b);
    return (busiest / intervalNs * 100).clamp(0, 100).toDouble();
  }

  Future<double?> _memoryUsedPercent() async {
    try {
      final lines = await File('/proc/meminfo').readAsLines();
      int? totalKb;
      int? availableKb;
      for (final line in lines) {
        if (line.startsWith('MemTotal:')) {
          totalKb = int.parse(RegExp(r'\d+').firstMatch(line)!.group(0)!);
        } else if (line.startsWith('MemAvailable:')) {
          availableKb = int.parse(RegExp(r'\d+').firstMatch(line)!.group(0)!);
        }
      }
      if (totalKb == null || availableKb == null || totalKb == 0) return null;
      return (totalKb - availableKb) / totalKb * 100;
    } catch (_) {
      return null;
    }
  }

  /// The address on the interface with the default route — a board with a
  /// second port on an isolated network (the intercom VLAN) would otherwise
  /// report whichever interface the kernel happens to list first.
  Future<String?> _ipAddress() async {
    try {
      final interfaces = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.IPv4);
      final defaultIface = await _defaultRouteInterface();
      interfaces.sort((a, b) => (a.name == defaultIface ? 0 : 1) - (b.name == defaultIface ? 0 : 1));
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// `/proc/net/route` lists the default route with destination 00000000.
  Future<String?> _defaultRouteInterface() async {
    try {
      for (final line in (await File('/proc/net/route').readAsLines()).skip(1)) {
        final cols = line.trim().split(RegExp(r'\s+'));
        if (cols.length > 1 && cols[1] == '00000000') return cols[0];
      }
    } catch (_) {}
    return null;
  }
}
