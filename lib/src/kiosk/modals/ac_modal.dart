import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../data/house_models.dart';
import '../data/dates.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/ac_widgets.dart';
import '../widgets/kiosk_widgets.dart';
import 'climate_modal.dart';

Future<void> showAcModal(BuildContext context, String entityId) => showKModal(context, (_) => AcModal(entityId: entityId));

/// One AC unit (the design's "AC de uma divisão"), opened from a row of
/// Casa's Ar Condicionado card: the target temperature large, mode and
/// fan speed, and power. Off, the controls fade until it's switched on.
class AcModal extends ConsumerStatefulWidget {
  const AcModal({super.key, required this.entityId});

  final String entityId;

  @override
  ConsumerState<AcModal> createState() => _AcModalState();
}

class _AcModalState extends ConsumerState<AcModal> with KDebouncedTarget {
  AcUnit? _unit;

  void _run(Future<void> Function() f) => f().catchError(KToast.error);

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(acUnitsProvider.select((units) => units.where((u) => u.entityId == widget.entityId).firstOrNull));
    if (u == null) return const KModal(child: SizedBox(height: 120));
    if (_unit != null) settleIfEchoed(u.target);
    _unit = u;
    final actions = ref.read(acActionsProvider);
    final on = u.on;
    final target = pending ?? u.target;
    final badgeBg = on ? u.mode.tint : KColors.chipAlt;
    final badgeFg = on ? u.mode.ink : KColors.faint;
    final fans = [
      for (final f in const ['auto', 'low', 'medium', 'high'])
        if (u.fanModes.contains(f)) f,
    ];
    // Units with other speeds show theirs, up to four.
    final speeds = fans.length >= 2 ? fans : u.fanModes.take(4).toList();

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: KText.label),
    );
    Widget segments(List<Widget> children) => Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(34)),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 4), Expanded(child: children[i])],
        ],
      ),
    );
    Widget step(bool plus) => KCircleButton(
      icon: plus ? KIcons.plus : KIcons.minus,
      size: 88,
      iconSize: 32,
      stroke: 2.4,
      onTap: on ? () => bump(u.target ?? 21, plus ? u.step : -u.step, u.min, u.max, (t) => actions.target(u, t)) : null,
    );

    return KModal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(22)),
                child: Center(child: KIcon(on ? acModeIcon(u.mode) : KIcons.power, size: 34, color: badgeFg, stroke: 1.9)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.name, style: KText.modalTitle),
                    const SizedBox(height: 4),
                    Text(on ? l10n.acNowMode(fmtDeg(u.current), u.mode.name) : l10n.acNowOff(fmtDeg(u.current)), style: KText.s(20, color: KColors.muted)),
                  ],
                ),
              ),
              KCircleButton(
                icon: KIcons.close,
                size: 64,
                iconSize: 26,
                stroke: 2.2,
                bg: KColors.chip,
                border: null,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // The target temperature.
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: on ? Color.lerp(KColors.card, u.mode.tint, 0.55) : KColors.sub, borderRadius: BorderRadius.circular(28)),
            child: Row(
              children: [
                Opacity(opacity: on ? 1 : 0.4, child: step(false)),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        fmtDeg(target),
                        style: KText.d(120, weight: FontWeight.w400, height: 1, spacing: -3, color: on ? u.mode.ink : KColors.faint),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        on ? l10n.acTargetTemperature : l10n.acOffTurnOnToAdjust,
                        style: KText.s(18, weight: FontWeight.w600, color: KColors.muted),
                      ),
                    ],
                  ),
                ),
                Opacity(opacity: on ? 1 : 0.4, child: step(true)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Mode and fan speed.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: on ? 1 : 0.4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (u.modes.length > 1) ...[
                  label(l10n.acModeLabel),
                  segments([
                    for (final m in u.modes)
                      KPress(
                        onTap: on && u.mode != m ? () => _run(() => actions.mode(u, m)) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 64,
                          decoration: BoxDecoration(color: u.mode == m ? m.color : Colors.transparent, borderRadius: BorderRadius.circular(30)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              KIcon(acModeIcon(m), size: 22, stroke: 2, color: u.mode == m ? KColors.onAccent : KColors.ink),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  m.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: KText.s(20, weight: FontWeight.w600, color: u.mode == m ? KColors.onAccent : KColors.ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ]),
                ],
                if (speeds.length > 1) ...[
                  if (u.modes.length > 1) const SizedBox(height: 18),
                  label(l10n.acFanLabel),
                  segments([
                    for (final f in speeds)
                      KPress(
                        onTap: on && u.fanMode != f ? () => _run(() => actions.fan(u, f)) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: u.fanMode == f ? KColors.tile : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: u.fanMode == f ? const [BoxShadow(color: Color(0x1A17191C), blurRadius: 8, offset: Offset(0, 2))] : null,
                          ),
                          child: Text(acFanLabel(f), style: KText.s(20, weight: FontWeight.w600)),
                        ),
                      ),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Transform.translate(
                offset: const Offset(-12, 0),
                child: KPress(
                  onTap: () {
                    Navigator.of(context).maybePop();
                    showClimateModal(context);
                  },
                  child: SizedBox(
                    height: 64,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Text(l10n.acAllUnits, style: KText.s(20, weight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const KIcon(KIcons.chevronRight, size: 22, stroke: 2.2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (on)
                KButton(
                  label: l10n.acTurnOff,
                  icon: KIcons.power,
                  iconSize: 26,
                  height: 72,
                  fontSize: 22,
                  gap: 12,
                  padding: const EdgeInsets.fromLTRB(28, 0, 36, 0),
                  onTap: () => _run(() => actions.power(u, false)),
                )
              else
                KButton.primary(
                  label: l10n.acTurnOn,
                  icon: KIcons.power,
                  iconSize: 26,
                  height: 72,
                  fontSize: 22,
                  gap: 12,
                  padding: const EdgeInsets.fromLTRB(30, 0, 40, 0),
                  onTap: () => _run(() => actions.power(u, true)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
