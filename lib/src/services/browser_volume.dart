import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'browser_audio_streams.dart';

/// The in-app browser's own volume — only what sites play (videos, music),
/// separate from the screen's master volume in Definições. Kept across
/// openings and restarts.
class BrowserVolume {
  BrowserVolume._();

  static final instance = BrowserVolume._();

  static const _prefsVolume = 'browser_volume';
  static const _prefsMuted = 'browser_muted';

  final ValueNotifier<int> percent = ValueNotifier(70);
  final ValueNotifier<bool> muted = ValueNotifier(false);

  late final _streams = BrowserAudioStreams(_apply);
  int _open = 0;
  bool _loaded = false;

  /// A browser window opened: load the saved level, set any stream already
  /// playing and follow new ones until [release].
  Future<void> attach() async {
    _open++;
    _streams.watch();
    if (!_loaded) {
      _loaded = true;
      final p = await SharedPreferences.getInstance();
      percent.value = p.getInt(_prefsVolume) ?? percent.value;
      muted.value = p.getBool(_prefsMuted) ?? muted.value;
    }
    _apply();
  }

  void release() {
    if (_open > 0) _open--;
    if (_open == 0) _streams.unwatch();
  }

  Future<void> set(int value) async {
    percent.value = value.clamp(0, 100);
    muted.value = false;
    await _save();
    _apply();
  }

  Future<void> setMuted(bool value) async {
    muted.value = value;
    await _save();
    _apply();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_prefsVolume, percent.value);
    await p.setBool(_prefsMuted, muted.value);
  }

  void _apply() => _streams.apply(percent: percent.value, muted: muted.value);
}
