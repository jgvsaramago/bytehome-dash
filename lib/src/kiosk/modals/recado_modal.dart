import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/ha_providers.dart';
import '../data/family_data.dart';
import '../data/messages_data.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/kiosk_widgets.dart';
import '../widgets/recado_widgets.dart';

/// Shows the unseen recados, if any and not already showing.
Future<void> showRecados(BuildContext context) async {
  if (RecadoModal.isOpen) return;
  RecadoModal.isOpen = true;
  try {
    await showKModal(context, (_) => const RecadoModal());
  } finally {
    RecadoModal.isOpen = false;
  }
}

/// Recados por ver (design: RecadoModal): opens each time the screen wakes
/// while a message is unseen. "Visto" marks it seen on every screen; "Mais
/// tarde" closes it until the next wake. Saying «visto» / «mais tarde» to
/// the assistant does the same (its mark_messages_seen tool).
class RecadoModal extends ConsumerStatefulWidget {
  const RecadoModal({super.key});

  static bool isOpen = false;

  @override
  ConsumerState<RecadoModal> createState() => _RecadoModalState();
}

class _RecadoModalState extends ConsumerState<RecadoModal> {
  /// The ones shown when it opened: marking one seen keeps it in place,
  /// faded, rather than reflowing the list.
  late final List<FamilyMessage> _shown = ref.read(familyMessagesProvider.notifier).unseen.reversed.toList();
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    // The assistant's mark_messages_seen: seen or "mais tarde", either way it closes.
    _sub = ref.read(haWebSocketClientProvider).assistantEvents.listen((e) {
      if (e['action'] == 'messages' && mounted) _close();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _close() => closeOwnRoute(context);

  Future<void> _seen(Set<String>? ids) async {
    try {
      await ref.read(familyMessagesProvider.notifier).markSeen(ids);
    } catch (e) {
      KToast.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(familyMembersProvider);
    final now = {for (final m in ref.watch(familyMessagesProvider)) m.id: m};
    final shown = [for (final m in _shown) now[m.id] ?? m];
    if (shown.isEmpty) return const SizedBox.shrink();
    final multi = shown.length > 1;
    final left = shown.where((m) => !m.seen).length;
    final one = shown.first;
    return KModal(
      top: 300,
      onDismiss: _close,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: KColors.orangeTint, borderRadius: BorderRadius.circular(22)),
                child: Center(child: KIcon(recadoIcon, size: 36, color: KColors.orangeInk)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      multi
                          ? l10n.recadoUnseenCount(left)
                          : one.to == null
                          ? l10n.recadoTitleEveryone
                          : l10n.recadoTitleFor(one.to!),
                      style: KText.d(40, spacing: -0.5, height: 1.15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      multi ? l10n.recadoStayUntilSeen : '${recadoFrom(one)} · ${recadoWhen(one.at, lower: true)}',
                      style: KText.s(20, color: KColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          if (!multi)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
              decoration: BoxDecoration(color: KColors.lightRoomBg, borderRadius: BorderRadius.circular(28)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecadoToChip(message: one, members: members),
                  const SizedBox(height: 18),
                  Text(l10n.recadoQuoted(one.text), style: KText.d(one.text.length > 160 ? 32 : 40, weight: FontWeight.w400, height: 1.35, spacing: -0.2)),
                ],
              ),
            )
          else
            for (final m in shown) ...[
              if (m != shown.first) const SizedBox(height: 14),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: m.seen ? 0.55 : 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                  decoration: BoxDecoration(color: m.seen ? KColors.sub : KColors.lightRoomBg, borderRadius: BorderRadius.circular(26)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          RecadoToChip(message: m, members: members, height: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${recadoFrom(m)} · ${recadoWhen(m.at, lower: true)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KText.s(18, color: KColors.muted).copyWith(fontStyle: m.from == null ? FontStyle.italic : null),
                            ),
                          ),
                          if (!m.seen)
                            KButton(
                              label: l10n.recadoSeen,
                              icon: KIcons.check,
                              iconSize: 22,
                              iconStroke: 2.6,
                              height: 56,
                              fontSize: 19,
                              onTap: () => _seen({m.id}),
                            )
                          else
                            Row(
                              children: [
                                KIcon(KIcons.check, size: 22, stroke: 2.6, color: KColors.greenInk),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.recadoSeen,
                                  style: KText.s(18, weight: FontWeight.w600, color: KColors.greenInk),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(m.text, style: KText.s(26, height: 1.45)),
                    ],
                  ),
                ),
              ),
            ],
          const SizedBox(height: 26),
          Row(
            children: [
              KIcon(KIcons.mic, size: 22, color: KColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.recadoVoiceHint, style: KText.s(17, color: KColors.muted)),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              KButton(label: l10n.recadoLater, height: 80, padding: const EdgeInsets.symmetric(horizontal: 36), onTap: _close),
              const SizedBox(width: 14),
              KButton.primary(
                label: multi ? l10n.recadoMarkAllSeen : l10n.recadoSeen,
                icon: KIcons.check,
                iconSize: 26,
                height: 80,
                padding: const EdgeInsets.fromLTRB(32, 0, 40, 0),
                onTap: () {
                  _seen({for (final m in shown) m.id});
                  _close();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
