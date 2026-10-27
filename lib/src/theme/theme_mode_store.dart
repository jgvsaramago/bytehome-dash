import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'theme_mode_controller.dart';

/// Persists the screen's theme choice (Definições → Aspeto) via
/// `shared_preferences`: a per-device trait of this one panel, like its
/// brightness, not shared dashboard configuration. A new key on purpose —
/// the old `theme_brightness` belonged to the retired Nocturne theme and
/// would otherwise bring a stale "dark" back.
class ThemeModeStore {
  ThemeModeStore();

  static const _key = 'kiosk_theme';

  Future<ThemeSettings?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return ThemeSettings(
        preference: ThemePreference.values.asNameMap()[m['preference']] ?? ThemePreference.light,
        bySun: m['bySun'] as bool? ?? true,
        darkAt: m['darkAt'] as int? ?? 20 * 60,
        lightAt: m['lightAt'] as int? ?? 7 * 60,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ThemeSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({'preference': s.preference.name, 'bySun': s.bySun, 'darkAt': s.darkAt, 'lightAt': s.lightAt}));
  }
}
