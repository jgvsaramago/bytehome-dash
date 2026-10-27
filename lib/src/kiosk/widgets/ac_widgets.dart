import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../data/house_models.dart';
import '../data/dates.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import 'house_widgets.dart';
import 'kiosk_widgets.dart';

String acModeIcon(AcMode m) => switch (m) {
  AcMode.heat => KIcons.flame,
  AcMode.cool => KIcons.snow,
  AcMode.fan || AcMode.auto => KIcons.fan,
};

/// Holds a target temperature locally while the −/+ buttons are being
/// tapped and sends it once they settle, so quick taps don't each race a
/// round trip to HA (and the AC beeping for every half degree).
mixin KDebouncedTarget<T extends StatefulWidget> on State<T> {
  double? pending;
  Timer? _timer;

  void bump(double from, double delta, double min, double max, Future<void> Function(double) send) {
    final next = ((pending ?? from) + delta).clamp(min, max).toDouble();
    setState(() => pending = next);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 700), () async {
      try {
        await send(next);
      } catch (e) {
        KToast.error(e);
        if (mounted) setState(() => pending = null);
        return;
      }
      // Keep showing the sent value until HA echoes it back (or give up).
      _timer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => pending = null);
      });
    });
  }

  void settleIfEchoed(double? actual) {
    if (pending != null && actual != null && (actual - pending!).abs() < 0.01 && !(_timer?.isActive ?? false)) pending = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// One AC unit as a control row: power badge (showing the mode), name and
/// current temperature, −/+ target stepper and, while on, the mode chips.
class KAcRow extends ConsumerStatefulWidget {
  const KAcRow({super.key, required this.unit});

  final AcUnit unit;

  @override
  ConsumerState<KAcRow> createState() => _KAcRowState();
}

class _KAcRowState extends ConsumerState<KAcRow> with KDebouncedTarget {
  @override
  void didUpdateWidget(KAcRow old) {
    super.didUpdateWidget(old);
    settleIfEchoed(widget.unit.target);
  }

  Future<void> _run(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      KToast.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
    final actions = ref.read(acActionsProvider);
    final target = pending ?? u.target;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      // On: the mode's tint blended 45 % into the modal surface; off: `sub`.
      decoration: BoxDecoration(color: u.on ? Color.lerp(u.mode.tint, KColors.card, 0.55) : KColors.sub, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Row(
            children: [
              KPress(
                onTap: () => _run(() => actions.power(u, !u.on)),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: u.on ? u.mode.tint : KColors.chipAlt, borderRadius: BorderRadius.circular(18)),
                  child: Center(child: KIcon(u.on ? acModeIcon(u.mode) : KIcons.power, size: 28, color: u.on ? u.mode.ink : KColors.faint, stroke: 2)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KText.s(20, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text([l10n.acNowTemp(fmtDeg(u.current)), if (u.on) u.mode.label].join(' · '), style: KText.s(16, color: KColors.muted)),
                  ],
                ),
              ),
              if (u.on)
                Row(
                  children: [
                    KStepButton(plus: false, size: 52, onTap: () => bump(u.target ?? 21, -u.step, u.min, u.max, (t) => actions.target(u, t))),
                    SizedBox(
                      width: 80,
                      child: Text(
                        fmtDeg(target),
                        textAlign: TextAlign.center,
                        style: KText.d(28, color: u.mode.ink),
                      ),
                    ),
                    KStepButton(plus: true, size: 52, onTap: () => bump(u.target ?? 21, u.step, u.min, u.max, (t) => actions.target(u, t))),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    l10n.commonOff,
                    style: KText.s(17, weight: FontWeight.w600, color: KColors.faint),
                  ),
                ),
            ],
          ),
          if (u.on && u.modes.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 70, top: 10),
              child: Row(
                children: [
                  for (final m in u.modes) ...[
                    KChip(
                      label: m.label,
                      on: u.mode == m,
                      height: 48,
                      fontSize: 16,
                      padX: 16,
                      onBg: m.color,
                      onTap: u.mode == m ? null : () => _run(() => actions.mode(u, m)),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A room's AC in its modal (the design's "Modal de uma divisão"): the
/// power badge, "Ar condicionado" with its mode and the room's
/// temperature, the −/+ target — or "Ligar" while off — and the modes.
class KRoomAcBlock extends ConsumerStatefulWidget {
  const KRoomAcBlock({super.key, required this.unit});

  final AcUnit unit;

  @override
  ConsumerState<KRoomAcBlock> createState() => _KRoomAcBlockState();
}

class _KRoomAcBlockState extends ConsumerState<KRoomAcBlock> with KDebouncedTarget {
  @override
  void didUpdateWidget(KRoomAcBlock old) {
    super.didUpdateWidget(old);
    settleIfEchoed(widget.unit.target);
  }

  void _run(Future<void> Function() f) => f().catchError(KToast.error);

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
    final actions = ref.read(acActionsProvider);
    final target = pending ?? u.target;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KCircleButton(
                icon: u.on ? acModeIcon(u.mode) : KIcons.power,
                size: 56,
                iconSize: 28,
                bg: u.on ? u.mode.tint : KColors.chipAlt,
                fg: u.on ? u.mode.ink : KColors.muted,
                border: null,
                onTap: () => _run(() => actions.power(u, !u.on)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.acTitle, style: KText.s(24, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text([u.on ? u.mode.label : l10n.commonOff, l10n.acNowLower(fmtDeg(u.current))].join(' · '), style: KText.s(17, color: KColors.muted)),
                  ],
                ),
              ),
              if (u.on) ...[
                KStepButton(plus: false, size: 64, onTap: () => bump(u.target ?? 21, -u.step, u.min, u.max, (t) => actions.target(u, t))),
                SizedBox(
                  width: 96,
                  child: Text(
                    fmtDeg(target),
                    textAlign: TextAlign.center,
                    style: KText.d(34, color: u.mode.ink),
                  ),
                ),
                KStepButton(plus: true, size: 64, onTap: () => bump(u.target ?? 21, u.step, u.min, u.max, (t) => actions.target(u, t))),
              ] else
                KButton.primary(
                  label: l10n.acTurnOn,
                  height: 56,
                  fontSize: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  onTap: () => _run(() => actions.power(u, true)),
                ),
            ],
          ),
          if (u.on && u.modes.length > 1) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                for (final m in u.modes) ...[
                  KChip(
                    label: m.label,
                    on: u.mode == m,
                    height: 56,
                    fontSize: 20,
                    padX: 22,
                    offBg: KColors.tile,
                    onBg: m.color,
                    onTap: u.mode == m ? null : () => _run(() => actions.mode(u, m)),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Início's "Ar condicionado" card: one thermostat for the whole group, in
/// the same anatomy as "Água quente" — title and state chip, the power tile
/// (switches every unit), the average target across the units that are on
/// with −/+ shifting all of them, and a footer opening the climate modal.
class KAcSummaryCard extends ConsumerStatefulWidget {
  const KAcSummaryCard({super.key, required this.units, required this.onSeeAll});

  final List<AcUnit> units;
  final VoidCallback onSeeAll;

  @override
  ConsumerState<KAcSummaryCard> createState() => _KAcSummaryCardState();
}

class _KAcSummaryCardState extends ConsumerState<KAcSummaryCard> with KDebouncedTarget {
  double? get _avgTarget {
    final on = widget.units.where((u) => u.on && u.target != null).toList();
    if (on.isEmpty) return null;
    return (on.fold<double>(0, (a, u) => a + u.target!) / on.length * 2).round() / 2;
  }

  @override
  void didUpdateWidget(KAcSummaryCard old) {
    super.didUpdateWidget(old);
    settleIfEchoed(_avgTarget);
  }

  @override
  Widget build(BuildContext context) {
    final units = widget.units;
    final on = units.where((u) => u.on).toList();
    final actions = ref.read(acActionsProvider);
    final currents = units.map((u) => u.current).whereType<double>().toList();
    final avgCurrent = currents.isEmpty ? null : currents.reduce((a, b) => a + b) / currents.length;
    final avg = pending ?? _avgTarget;
    final anyOn = on.isNotEmpty;
    // All off: the last targets asked for, faded — the chip already says off.
    final targets = units.map((u) => u.target).whereType<double>().toList();
    final allTarget = targets.isEmpty ? null : (targets.reduce((a, b) => a + b) / targets.length * 2).round() / 2;
    final mode = anyOn ? on.first.mode : null;
    final (chip, chipBg, chipFg, chipDot) = switch (mode) {
      null => (l10n.commonOff, KColors.chipAlt, KColors.ink2, KColors.faint),
      AcMode.heat => (l10n.acHeating, KColors.orangeTint, KColors.orangeInk, KColors.orange),
      AcMode.cool => (l10n.acCooling, KColors.blueTint, KColors.blueInk, KColors.blue),
      AcMode.fan => (l10n.acVentilating, KColors.greenTint, KColors.greenInk, KColors.green),
      AcMode.auto => (l10n.commonAuto, KColors.purpleTint, KColors.purple, KColors.purple),
    };
    final summary = units.isEmpty ? l10n.acNoUnits : (anyOn ? l10n.acOnOfTotal(on.length, units.length) : l10n.acAllOff);

    Future<void> shiftAll(double target) => Future.wait([for (final u in on) actions.target(u, target)]);

    return Container(
      // The footer's 48 px touch target overhangs its 20 px line by 14 at
      // the bottom, so the bottom padding gives those 14 back.
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
      decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 34,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.acTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(24, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                KStateChip(label: chip, bg: chipBg, fg: chipFg, dot: chipDot, blink: anyOn),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                KPress(
                  onTap: units.isEmpty
                      ? null
                      : () async {
                          try {
                            if (anyOn) {
                              await actions.allOff(units);
                            } else {
                              await Future.wait([for (final u in units) actions.power(u, true)]);
                            }
                          } catch (e) {
                            KToast.error(e);
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: anyOn ? mode!.tint : KColors.tile, borderRadius: BorderRadius.circular(18)),
                    child: Center(child: KIcon(KIcons.power, size: 30, color: anyOn ? mode!.ink : KColors.faint, stroke: 2)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fmtDeg(anyOn ? avg : allTarget),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: KText.d(44, height: 1, color: anyOn ? KColors.ink : KColors.faint),
                        ),
                        Text(
                          anyOn ? l10n.acHouseTemp(fmtDeg(avgCurrent)) : l10n.acHouseTempNoHeating(fmtDeg(avgCurrent)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KText.s(16, height: 1.25, color: KColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                if (anyOn) ...[
                  const SizedBox(width: 16),
                  KStepButton(plus: false, size: 52, onTap: () => bump(_avgTarget ?? 21, -0.5, 16, 30, shiftAll)),
                  const SizedBox(width: 8),
                  KStepButton(plus: true, size: 52, onTap: () => bump(_avgTarget ?? 21, 0.5, 16, 30, shiftAll)),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(15, height: 4 / 3, color: KColors.muted),
                  ),
                ),
                const SizedBox(width: 10),
                KTextAction(label: l10n.houseSeeAll, onTap: widget.onSeeAll),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
