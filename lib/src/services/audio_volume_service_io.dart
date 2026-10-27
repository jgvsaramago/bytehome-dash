import 'dart:io';

/// Master volume: the volume of PipeWire's default sink, through `pactl`
/// (the app runs in the kiosk user's session, `XDG_RUNTIME_DIR` set by the
/// service, so it reaches that user's PipeWire). Following `@DEFAULT_SINK@`
/// rather than a named device means it keeps working when the default
/// changes (reSpeaker unplugged → HDMI).
///
/// Every call is guarded and reports failure rather than throwing: `pactl`
/// may be missing or PipeWire not running yet.
class AudioVolumeService {
  const AudioVolumeService();

  bool get isSupported => Platform.isLinux;

  /// `pactl get-sink-volume` prints e.g.
  /// `Volume: front-left: 26214 /  40% / -23.88 dB,   front-right: ...`;
  /// the first percentage is the volume (channels are kept in step).
  static final _percent = RegExp(r'(\d+)%');

  Future<int?> readPercent() async {
    try {
      final r = await Process.run('pactl', ['get-sink-volume', '@DEFAULT_SINK@']);
      if (r.exitCode != 0) return null;
      final m = _percent.firstMatch(r.stdout as String);
      return m == null ? null : int.parse(m.group(1)!).clamp(0, 100);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setPercent(int percent) async {
    try {
      final r = await Process.run('pactl', ['set-sink-volume', '@DEFAULT_SINK@', '${percent.clamp(0, 100)}%']);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
