import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../data/house_models.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/ac_widgets.dart';
import '../widgets/kiosk_widgets.dart';

Future<void> showClimateModal(BuildContext context) => showKModal(context, (_) => const ClimateModal());

/// Every AC unit with its own controls (the design's "Modal ar
/// condicionado"), opened from Início's "Ver todos".
class ClimateModal extends ConsumerWidget {
  const ClimateModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(acUnitsProvider);
    final outside = ref.watch(weatherNowProvider).temp;
    final on = units.where((u) => u.on).length;
    final summary = [on == 0 ? l10n.acAllOff : l10n.acOnOfTotal(on, units.length), if (outside != null) l10n.acOutside('${outside.round()}')].join(' · ');
    return KModal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: KModalHeader(
              title: l10n.acTitle,
              subtitle: summary,
              trailing: on == 0
                  ? null
                  : KButton(
                      label: l10n.acTurnOffAll,
                      icon: KIcons.power,
                      iconSize: 22,
                      height: 64,
                      fontSize: 20,
                      bg: KColors.chip,
                      border: null,
                      gap: 10,
                      padding: const EdgeInsets.fromLTRB(22, 0, 28, 0),
                      onTap: () => ref.read(acActionsProvider).allOff(units).catchError(KToast.error),
                    ),
            ),
          ),
          if (units.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.acNoneConfigured, style: KText.s(20, color: KColors.muted)),
            ),
          for (final u in units) ...[KAcRow(unit: u), const SizedBox(height: 16)],
        ],
      ),
    );
  }
}
