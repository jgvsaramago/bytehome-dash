import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import 'kiosk_widgets.dart';

enum KioskPage {
  home(KIcons.navHome),
  calendar(KIcons.calendar),
  tasks(KIcons.tasks),
  meals(KIcons.meals),
  lists(KIcons.list),
  house(KIcons.house),
  music(KIcons.music),

  /// Not in the bar: opened by tapping the header's clock.
  settings(KIcons.settings);

  const KioskPage(this.icon);

  final String icon;

  String get label => switch (this) {
    KioskPage.home => l10n.navHome,
    KioskPage.calendar => l10n.navCalendar,
    KioskPage.tasks => l10n.navTasks,
    KioskPage.meals => l10n.navMeals,
    KioskPage.lists => l10n.navLists,
    KioskPage.house => l10n.navHouse,
    KioskPage.music => l10n.navMusic,
    KioskPage.settings => l10n.navSettings,
  };
}

/// The bottom bar: seven labelled destinations, then the assistant button.
/// Definições isn't here — the header's clock opens it.
///
/// The theme's `surface` at 78 % over a frosted blur of whatever passes beneath it.
/// Only Casa scrolls under the bar ([blur]); over the other pages' plain
/// background the same tint is painted flat, without the cost of a
/// backdrop blur on the Pi.
///
/// As in the design (`flex: 1 1 auto`), each destination is its own
/// content width plus an equal share of the room left over, so the pills
/// fill the bar edge to edge.
class KioskNavBar extends StatelessWidget {
  const KioskNavBar({super.key, required this.selected, required this.onSelect, required this.onAssistant, this.blur = false});

  final KioskPage selected;
  final ValueChanged<KioskPage> onSelect;
  final VoidCallback onAssistant;
  final bool blur;

  /// The design's `surface` at 78 %.
  static Color get _tint => KColors.card.withValues(alpha: 0.78);

  /// The top hairline: 8 % ink in the light, 8 % white in the dark.
  static Color get _edge => (KColors.isDark ? KColors.onAccent : KColors.dark).withValues(alpha: 0.08);

  static const _gap = 8.0;
  static const _icon = 30.0;
  static const _iconGap = 12.0;
  static const _padX = 12.0;
  static const _assistant = 88.0;
  static const _divider = 1.5 + 2 * 6;

  static final _pages = [
    for (final p in KioskPage.values)
      if (p != KioskPage.settings) p,
  ];

  static double _contentWidth(KioskPage p) {
    final tp = TextPainter(
      text: TextSpan(
        text: p.label,
        style: KText.s(22, weight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return _padX * 2 + _icon + _iconGap + tp.width;
  }

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      height: 128,
      width: double.infinity,
      decoration: BoxDecoration(
        color: blur ? _tint : Color.alphaBlend(_tint, KColors.page),
        border: Border(top: BorderSide(color: _edge)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 56),
      child: LayoutBuilder(
        builder: (context, box) {
          final widths = [for (final p in _pages) _contentWidth(p)];
          final fixed = widths.fold<double>(0, (a, w) => a + w) + _gap * (_pages.length + 1) + _divider + _assistant;
          final extra = ((box.maxWidth - fixed) / _pages.length).clamp(0.0, double.infinity);
          return Center(
            // Scale-down only as a guard: at the design's sizes the row fits.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  for (var i = 0; i < _pages.length; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    _NavItem(page: _pages[i], width: widths[i] + extra, selected: _pages[i] == selected, onTap: () => onSelect(_pages[i])),
                  ],
                  const SizedBox(width: _gap),
                  Container(width: 1.5, height: 56, margin: const EdgeInsets.symmetric(horizontal: 6), color: KColors.navBorder),
                  const SizedBox(width: _gap),
                  KCircleButton(
                    icon: KIcons.wave,
                    size: _assistant,
                    iconSize: 36,
                    stroke: 2.2,
                    bg: KColors.accent,
                    fg: KColors.onAccent,
                    border: null,
                    shadow: [BoxShadow(color: KColors.accent.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                    onTap: onAssistant,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (!blur) return bar;
    return ClipRect(
      child: BackdropFilter(
        // blur(28px) saturate(180%)
        filter: ImageFilter.compose(outer: const ColorFilter.matrix(_saturate180), inner: ImageFilter.blur(sigmaX: 14, sigmaY: 14)),
        child: bar,
      ),
    );
  }

  static const _saturate180 = <double>[
    1.6296, -0.5720, -0.0576, 0, 0, //
    -0.1704, 1.2280, -0.0576, 0, 0, //
    -0.1704, -0.5720, 1.7424, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.page, required this.width, required this.selected, required this.onTap});

  final KioskPage page;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? KColors.onAccent : KColors.ink2;
    return KPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: kEase,
        width: width,
        height: 88,
        decoration: BoxDecoration(color: selected ? KColors.accent : Colors.transparent, borderRadius: BorderRadius.circular(44)),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KIcon(page.icon, size: KioskNavBar._icon, color: fg, stroke: 1.9),
            const SizedBox(width: KioskNavBar._iconGap),
            Text(
              page.label,
              maxLines: 1,
              style: KText.s(22, weight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
