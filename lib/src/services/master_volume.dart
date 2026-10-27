import 'package:flutter/foundation.dart';

import 'audio_volume_service.dart';

/// App-wide master volume (PipeWire's default output), shared by the
/// Definições slider and the MQTT `number` entity so a change from either
/// side shows on the other.
class MasterVolume {
  MasterVolume._();

  static final instance = MasterVolume._();

  static const _service = AudioVolumeService();

  /// Last known volume, 0–100; null until first read (or unsupported).
  final ValueNotifier<int?> percent = ValueNotifier(null);

  bool get isSupported => _service.isSupported;

  /// Re-reads the system volume — picks up changes made outside the app.
  Future<void> refresh() async {
    final v = await _service.readPercent();
    if (v != null) percent.value = v;
  }

  Future<bool> set(int value) async {
    final v = value.clamp(0, 100);
    final ok = await _service.setPercent(v);
    if (ok) percent.value = v;
    return ok;
  }
}
