import 'package:flutter/material.dart';

import '../../theme/theme_mode_controller.dart';

/// Colour tokens for the 22" vertical kiosk ("Calendário Familiar + Casa
/// Inteligente"), from the design's "Regras de estilo" and "Regras do modo
/// escuro" boards. Same names in both themes, different values: each is a
/// getter reading [isDark], and `ThemeSwitch` rebuilds the whole tree when
/// the mode changes so every widget re-reads them. Because they are getters,
/// none of them can appear in a `const` expression.
abstract final class KColors {
  static bool get isDark => ThemeModeController.instance.mode.value == Brightness.dark;

  static Color _t(int light, int dark) => Color(isDark ? dark : light);

  /// Level 0 · the screen (`bg`).
  static Color get page => _t(0xFFF3F1EC, 0xFF111214);

  /// Level 1 · section, modal, nav (`surface`). White in the light theme.
  static Color get card => _t(0xFFFFFFFF, 0xFF1B1D21);

  /// Level 2 · a card inside a section (`card`).
  static Color get sub => _t(0xFFF7F5F1, 0xFF202328);

  /// Level 3 · a block, tile or field sitting on a [sub] card (`tile`).
  static Color get tile => _t(0xFFFFFFFF, 0xFF2B2E33);
  static Color get ink => _t(0xFF17191C, 0xFFECECEF);

  /// `ink-2`.
  static Color get muted => _t(0xFF5F646B, 0xFFA3A7AE);

  /// `icon`.
  static Color get ink2 => _t(0xFF3B4046, 0xFFC9CCD1);
  static Color get ink3 => _t(0xFF4A4F55, 0xFFB5B9BF);

  /// `ink-3`.
  static Color get faint => _t(0xFF696E75, 0xFF979CA3);
  static Color get faint2 => _t(0xFF9A9EA4, 0xFF6E737A);

  /// `track`: outlines of secondary buttons, slider tracks.
  static Color get border => _t(0xFFE3DFD6, 0xFF34373D);
  static Color get divider => _t(0xFFEFECE6, 0xFF2B2E33);
  static Color get navBorder => _t(0xFFE6E2DA, 0xFF2B2E33);

  /// `disabled`.
  static Color get ring => _t(0xFFC9C4BA, 0xFF4A4E55);
  static Color get dashed => _t(0xFFD6D1C7, 0xFF3A3D43);
  static Color get disabledFg => _t(0xFFB9B4AA, 0xFF5A5E65);
  static Color get chip => _t(0xFFF3F1EC, 0xFF2B2E33);

  /// `neutral-bg`.
  static Color get chipAlt => _t(0xFFEFECE6, 0xFF2B2E33);

  /// Fills only (primary button, switches). Text and icons use [accentFg].
  static Color get accent => _t(0xFF1F4D45, 0xFF2E7A6D);

  /// The accent as text, icons and links on a surface.
  static Color get accentFg => _t(0xFF1F4D45, 0xFF6CB8A8);
  static Color get accentSoft => _t(0xFFE6EFEC, 0xFF1E3430);
  static Color get onAccentMuted => _t(0xFFD5E3DF, 0xFFCFE5E0);
  static Color get todayBg => _t(0xFFFBF3EC, 0xFF2A1F18);
  static Color get todayInk => _t(0xFF9A3412, 0xFFF0A06E);
  static Color get todayBorder => _t(0xFFF1D3BE, 0xFF4A2E1E);
  static Color get now => _t(0xFFC2410C, 0xFFE0743A);

  /// `danger-dot`; also a fill.
  static Color get red => _t(0xFFB42318, 0xFFE5544A);

  /// `danger-fg`.
  static Color get redInk => _t(0xFF912018, 0xFFF4877C);

  /// `danger-bg`.
  static Color get redTint => _t(0xFFFDE8E7, 0xFF3A1C1A);
  static Color get holidayBg => _t(0xFFFEF6F5, 0xFF2A1A19);

  /// `ok-dot`.
  static Color get green => _t(0xFF2B8A3E, 0xFF3FA75A);

  /// `ok-fg`.
  static Color get greenInk => _t(0xFF1E5E2B, 0xFF6CCB82);

  /// `ok-bg`.
  static Color get greenTint => _t(0xFFE1F3E5, 0xFF17301F);

  /// `info-dot`.
  static Color get blue => _t(0xFF1864AB, 0xFF4C8FD6);

  /// `info-fg`.
  static Color get blueInk => _t(0xFF1F5A93, 0xFF7DB3EA);

  /// `info-bg`.
  static Color get blueTint => _t(0xFFE1EEFB, 0xFF1A2A3B);

  /// `warm-dot`.
  static Color get orange => _t(0xFFC2410C, 0xFFE0743A);

  /// `warm-fg`.
  static Color get orangeInk => _t(0xFF9A3412, 0xFFF0A06E);

  /// `warm-bg`.
  static Color get orangeTint => _t(0xFFFDEBDD, 0xFF3A2518);
  static Color get purple => _t(0xFF5F3DC4, 0xFF9B82E8);
  static Color get purpleTint => _t(0xFFECE7FD, 0xFF2A2342);
  static Color get pink => _t(0xFFC2255C, 0xFFE0679A);
  static Color get pinkInk => _t(0xFFA61E4D, 0xFFF08DB4);
  static Color get pinkTint => _t(0xFFFCE7EF, 0xFF3A1C28);
  static Color get amber => _t(0xFFE8A33A, 0xFFE0A040);
  static Color get amberTint => _t(0xFFFFF1D6, 0xFF3A2E14);
  static Color get amberInk => _t(0xFF7A4A00, 0xFFF2C46D);

  /// Chart series.
  static Color get solar => _t(0xFFC98A2A, 0xFFE0A040);
  static Color get battery => _t(0xFF2F9E68, 0xFF5CC08C);
  static Color get grid => _t(0xFF2F7CC4, 0xFF4C8FD6);
  static Color get lightRoomBg => _t(0xFFFFF8EA, 0xFF2E2718);
  static Color get lightBtnBg => _t(0xFFFFE9BF, 0xFF4A3A1A);
  static Color get lightIconBg => _t(0xFFF2A93B, 0xFFF2A93B);
  static Color get lightIconFg => _t(0xFF3D2600, 0xFF3D2600);
  static Color get keyboardBg => _t(0xFFE4E0D8, 0xFF202328);
  static Color get keyboardKey => _t(0xFFFFFFFF, 0xFF3A3E45);
  static Color get keyboardFunc => _t(0xFFCFCAC0, 0xFF2B2E33);

  /// "Flutuar", "Fechar" and the floating panel's round buttons — set apart
  /// from the suggestions in the dark.
  static Color get keyboardCtl => _t(0xFFCFCAC0, 0xFF4F545C);
  static Color get keyboardSugg => isDark ? const Color(0x12FFFFFF) : const Color(0x99FFFFFF);

  /// Text and icons on an [accent] fill, and on images.
  static const onAccent = Color(0xFFFFFFFF);

  /// Pressed state overlay.
  static Color get pressed => isDark ? const Color(0x0FFFFFFF) : const Color(0x0D17191C);

  // Camera tiles, video and captions over images stay the same in both themes.
  static const camera = Color(0xFF2C3036);
  static const cameraText = Color(0xFFC9CDD2);
  static const dark = Color(0xFF17191C);

  static Color get scrim => isDark ? const Color(0x99000000) : const Color(0x7317191C);

  /// `shadow-float`: modals and toasts. In the dark a shadow doesn't show, so
  /// it gains a 1 px light outline instead.
  static List<BoxShadow> get shadowFloat => isDark
      ? const [BoxShadow(color: Color(0x0FFFFFFF), spreadRadius: 1), BoxShadow(color: Color(0x80000000), blurRadius: 30, offset: Offset(0, 10))]
      : const [BoxShadow(color: Color(0x1F17191C), blurRadius: 30, offset: Offset(0, 10))];
}

/// The person/calendar palette — one hue each for a family member, a
/// calendar, a task owner. Keyed by the names the sidebar panel stores in
/// HA (`blue`/`amber`/`green`/`accent`/`pink`). People get pink rather than
/// red so nobody reads as a holiday; an older saved `red` maps to pink too.
/// [red] stays for holiday calendars.
class KPersonColor {
  const KPersonColor(this.color, this.tint, this.ink);

  final Color color;
  final Color tint;
  final Color ink;

  static KPersonColor get blue => KPersonColor(KColors.blue, KColors.blueTint, KColors.isDark ? KColors.blueInk : KColors.blue);
  static KPersonColor get orange => KPersonColor(KColors.orange, KColors.orangeTint, KColors.orangeInk);
  static KPersonColor get green => KPersonColor(KColors.green, KColors.greenTint, KColors.greenInk);
  static KPersonColor get purple => KPersonColor(KColors.purple, KColors.purpleTint, KColors.purple);
  static KPersonColor get red => KPersonColor(KColors.red, KColors.redTint, KColors.redInk);
  static KPersonColor get pink => KPersonColor(KColors.pink, KColors.pinkTint, KColors.pinkInk);

  static List<KPersonColor> get cycle => [blue, orange, green, purple, pink];

  static KPersonColor fromKey(String? key) => switch (key) {
    'blue' => blue,
    'amber' || 'orange' => orange,
    'green' => green,
    'pink' || 'red' => pink,
    'accent' || 'purple' => purple,
    _ => blue,
  };
}

/// Type styles from the design's "Regras de escala" board. Sizes are in
/// design pixels — the whole UI is laid out on a fixed 1440-wide canvas
/// (see `KioskCanvas`), so these never need scaling at call sites.
abstract final class KText {
  static const sans = 'DM Sans';
  static const display = 'Outfit';

  static TextStyle s(double size, {FontWeight weight = FontWeight.w400, Color? color, double? height, double? spacing}) => TextStyle(
    fontFamily: sans,
    fontSize: size,
    fontWeight: weight,
    color: color ?? KColors.ink,
    height: height,
    letterSpacing: spacing,
    decoration: TextDecoration.none,
  );

  static TextStyle d(double size, {FontWeight weight = FontWeight.w500, Color? color, double? height, double? spacing}) => TextStyle(
    fontFamily: display,
    fontSize: size,
    fontWeight: weight,
    color: color ?? KColors.ink,
    height: height,
    letterSpacing: spacing,
    decoration: TextDecoration.none,
  );

  /// Small upper-case field label ("PARA QUEM", "DATA" ...).
  static TextStyle get label => s(15, weight: FontWeight.w700, color: KColors.muted, spacing: 1);

  static TextStyle get pageTitle => d(46, spacing: -1, height: 1.1);
  static TextStyle get modalTitle => d(40, spacing: -0.5);
  static TextStyle get cardTitle => d(34);
}

/// Shared motion curve — the design's `cubic-bezier(.2,.8,.2,1)`.
const kEase = Cubic(0.2, 0.8, 0.2, 1);
