import 'package:flutter/material.dart';

import 'theme_mode_store.dart';

/// Light, dark, or automatic (by the sun or at fixed times) — Definições →
/// Aspeto, and the MQTT theme select in Home Assistant.
enum ThemePreference { light, dark, auto }

@immutable
class ThemeSettings {
  const ThemeSettings({this.preference = ThemePreference.light, this.bySun = true, this.darkAt = 20 * 60, this.lightAt = 7 * 60});

  final ThemePreference preference;

  /// Automatic follows HA's `sun.sun` when true, else [darkAt]/[lightAt]
  /// (minutes after midnight).
  final bool bySun;
  final int darkAt;
  final int lightAt;

  ThemeSettings copyWith({ThemePreference? preference, bool? bySun, int? darkAt, int? lightAt}) =>
      ThemeSettings(preference: preference ?? this.preference, bySun: bySun ?? this.bySun, darkAt: darkAt ?? this.darkAt, lightAt: lightAt ?? this.lightAt);
}

/// App-wide handle onto the theme — same shape as `ScreenPowerController`:
/// a `BuildContext`-free singleton so the MQTT publisher (commanded from
/// Home Assistant) can drive it too. [mode] is what's on screen; `KColors`
/// reads it, and `ThemeSwitch` rebuilds the whole tree when it changes.
class ThemeModeController {
  ThemeModeController._();

  static final instance = ThemeModeController._();

  final ValueNotifier<Brightness> mode = ValueNotifier(Brightness.light);
  final ValueNotifier<ThemeSettings> settings = ValueNotifier(const ThemeSettings());

  final _store = ThemeModeStore();

  /// Restores the saved choice — call once before `runApp`, so the first
  /// frame already paints in the right theme. Automatic starts from the
  /// fixed hours until the sun's times arrive from HA.
  Future<void> restore() async {
    final saved = await _store.read();
    if (saved == null) return;
    settings.value = saved;
    mode.value = switch (saved.preference) {
      ThemePreference.light => Brightness.light,
      ThemePreference.dark => Brightness.dark,
      ThemePreference.auto => darkAt(DateTime.now(), saved.darkAt, saved.lightAt) ? Brightness.dark : Brightness.light,
    };
  }

  /// Saves a new choice. Light and dark apply at once; automatic is applied
  /// by the shell's scheduler (it knows the sun and whether anyone is busy
  /// with the screen), apart from the very first switch into it.
  Future<void> update(ThemeSettings value, {Brightness? autoNow}) async {
    settings.value = value;
    switch (value.preference) {
      case ThemePreference.light:
        mode.value = Brightness.light;
      case ThemePreference.dark:
        mode.value = Brightness.dark;
      case ThemePreference.auto:
        if (autoNow != null) mode.value = autoNow;
    }
    await _store.save(value);
  }

  Future<void> setPreference(ThemePreference p) => update(
    settings.value.copyWith(preference: p),
    autoNow: p == ThemePreference.auto ? (darkAt(DateTime.now(), settings.value.darkAt, settings.value.lightAt) ? Brightness.dark : Brightness.light) : null,
  );

  /// Whether [now] falls in the dark window that starts at [from] and ends
  /// at [to] (minutes after midnight; the window may wrap midnight).
  static bool darkAt(DateTime now, int from, int to) {
    final m = now.hour * 60 + now.minute;
    return from > to ? (m >= from || m < to) : (m >= from && m < to);
  }
}
