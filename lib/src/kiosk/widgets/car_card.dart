import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../data/house_models.dart';
import '../data/dates.dart';
import '../modals/history_modal.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import 'house_widgets.dart';

/// One car (the design's "Carro" component, "Opção F"): the same anatomy as
/// the "Água quente" and "Ar condicionado" cards — name and state chip, then
/// the car (or fuel pump) tile, battery or tank % with range and a detail
/// line, over a level bar. Electric: the charging state, the bar striped and
/// moving while charging, with the charge-limit marker; "Bateria baixa"
/// under 20%. Fuel: locked or not; red under 15% (reserve).
class KCarCard extends StatelessWidget {
  const KCarCard({super.key, required this.car, Color? background, this.radius = 24}) : _background = background;

  final CarInfo car;

  /// `sub` inside a section (Início, the default); a section-level surface
  /// when it stands on the page on its own (Casa).
  final Color? _background;
  final double radius;

  @override
  Widget build(BuildContext context) {
    // A white background means "on its own" (section level): the card
    // surface in the current theme, never a literal white in the dark.
    final onPage = _background == Colors.white || _background == KColors.card;
    final background = onPage ? KColors.card : (_background ?? KColors.sub);
    final b = car.level;
    final fuel = car.isFuel;
    final low = b != null && b < (fuel ? 15 : 20);
    final charging = !fuel && car.state == EvState.charging;
    final (chipLabel, chipBg, chipFg, chipIcon) = fuel
        ? switch (car.locked) {
            true => (l10n.carLocked, KColors.chipAlt, KColors.ink2, KIcons.lock),
            false => (l10n.carUnlocked, KColors.amberTint, KColors.amberInk, KIcons.lockOpen),
            null => (l10n.carNoState, KColors.chipAlt, KColors.ink2, null),
          }
        : charging
        ? (l10n.carCharging, KColors.greenTint, KColors.greenInk, null)
        : low
        ? (l10n.carBatteryLow, KColors.redTint, KColors.redInk, null)
        : switch (car.state) {
            EvState.waiting => (l10n.carWaitingToCharge, KColors.amberTint, KColors.amberInk, null),
            EvState.unplugged => (l10n.carUnplugged, KColors.chipAlt, KColors.ink2, null),
            _ => (l10n.carNoState, KColors.chipAlt, KColors.ink2, null),
          };
    final chipDot = charging ? KColors.green : (chipBg == KColors.redTint ? KColors.red : (car.state == EvState.waiting ? KColors.amber : KColors.faint));
    final updated = car.updated == null ? null : l10n.carUpdatedAt(KDates.hm(car.updated!));
    final where = car.place ?? updated;
    final detail = fuel
        ? [?where, if (low) l10n.carRefuelSoon].join(' · ')
        : charging
        ? [if (car.powerKw != null) '${fmtDec(car.powerKw!)} kW', if (car.limit != null) l10n.carChargeLimit(car.limit!.round())].join(' · ')
        : [?where, if (low) l10n.carPlugIn].join(' · ');
    // The fill runs from a paler shade to the state's colour: light → dark
    // on the light theme; in the dark one dim → bright (the state's -fg),
    // so the end of the fill stays the brightest point on the dark track.
    final dark = KColors.isDark;
    final end = low
        ? (dark ? KColors.redInk : KColors.red)
        : fuel
        ? KColors.ink2
        : charging
        ? (dark ? KColors.greenInk : KColors.green)
        : car.state == EvState.waiting
        ? (dark ? KColors.amberInk : KColors.amber)
        : (dark ? KColors.muted : KColors.faint);
    final start = Color.lerp(end, KColors.card, dark ? 0.45 : 0.4)!;
    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  car.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KText.s(22, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              KStateChip(label: chipLabel, bg: chipBg, fg: chipFg, dot: chipDot, blink: charging, icon: chipIcon, showDot: !fuel),
            ],
          ),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: onPage ? KColors.chip : KColors.tile, borderRadius: BorderRadius.circular(16)),
                child: Center(child: KIcon(fuel ? KIcons.fuel : KIcons.car, size: 28, color: KColors.ink2, stroke: 1.7)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        KHistoryTap(
                          target: car.levelId == null || b == null
                              ? null
                              : HistoryTarget(
                                  entityId: car.levelId!,
                                  label: fuel ? l10n.carFuelHistory(car.name) : l10n.carBatteryHistory(car.name),
                                  unit: '%',
                                  kind: fuel ? HistoryKind.percent : HistoryKind.battery,
                                ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: b == null ? '--' : '${b.round()}',
                                  children: [
                                    TextSpan(
                                      text: '%',
                                      style: KText.d(22, color: low ? KColors.red : KColors.ink),
                                    ),
                                  ],
                                ),
                                style: KText.d(40, color: low ? KColors.red : KColors.ink, height: 1),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                car.rangeKm == null ? '— km' : '${car.rangeKm!.round()} km',
                                style: KText.s(17, weight: FontWeight.w600, color: KColors.ink2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            detail.isEmpty ? '' : KDates.cap(detail),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: KText.s(15, color: KColors.muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _BatteryBar(
                      value: (b ?? 0) / 100,
                      limit: fuel || car.limit == null ? null : car.limit! / 100,
                      gradient: LinearGradient(colors: [start, end]),
                      striped: charging,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatteryBar extends StatefulWidget {
  const _BatteryBar({required this.value, required this.limit, required this.gradient, required this.striped});

  final double value;
  final double? limit;
  final Gradient gradient;
  final bool striped;

  @override
  State<_BatteryBar> createState() => _BatteryBarState();
}

class _BatteryBarState extends State<_BatteryBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    if (widget.striped) _c.repeat();
  }

  @override
  void didUpdateWidget(_BatteryBar old) {
    super.didUpdateWidget(old);
    if (widget.striped && !_c.isAnimating) _c.repeat();
    if (!widget.striped && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A 12 px track holding a 10 px fill; the limit marker stands 3 px proud
    // of the track above and below.
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: KColors.border, borderRadius: BorderRadius.circular(6)),
              ),
            ),
            Positioned(
              left: 0,
              top: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: kEase,
                // Explicit height: while charging the only child is the stripe
                // painter, which has no size of its own and would collapse
                // the fill to 0 px.
                width: box.maxWidth * widget.value.clamp(0.0, 1.0),
                height: 10,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(gradient: widget.gradient, borderRadius: BorderRadius.circular(5)),
                // Its own layer, repainted straight from the controller: the
                // stripes move every frame, the rest of the page shouldn't
                // have to be redrawn with them.
                child: widget.striped ? RepaintBoundary(child: CustomPaint(painter: _StripePainter(_c))) : null,
              ),
            ),
            if (widget.limit != null)
              Positioned(
                left: box.maxWidth * widget.limit!.clamp(0.0, 1.0) - 1.5,
                top: -3,
                bottom: -3,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(color: KColors.ink.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  _StripePainter(this.clock) : super(repaint: clock);

  final Animation<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    // White stripes over the coloured fill, the same in both themes.
    final paint = Paint()..color = const Color(0x4DFFFFFF);
    for (double x = -28 + t * 28; x < size.width + 28; x += 14 * 2) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + 7, size.height)
        ..lineTo(x + 7 + size.height, 0)
        ..lineTo(x + size.height, 0)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.clock != clock;
}
