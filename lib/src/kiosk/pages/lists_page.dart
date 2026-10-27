import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../widgets/on_screen_keyboard_controller.dart';
import '../data/family_data.dart';
import '../data/messages_data.dart';
import '../data/todo_data.dart';
import '../modals/item_modal.dart';
import '../modals/recado_new_modal.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/kiosk_widgets.dart';
import '../widgets/recado_widgets.dart';

/// Which list Listas shows; Início's "Compras" card points it at the
/// shopping list before navigating here.
final selectedListProvider = StateProvider<String?>((ref) => null);

/// [selectedListProvider]'s value for Recados, the special list.
const recadosListId = '_recados';

String listIcon(String key) => switch (key) {
  'cart' => KIcons.cart,
  'pill' => KIcons.pill,
  'home' => KIcons.house,
  'gift' => KIcons.gift,
  _ => KIcons.list,
};

/// Listas: every HA to-do list down the side, the selected one's items on
/// the right — pending first, the completed ones folded underneath.
class ListsPage extends ConsumerStatefulWidget {
  const ListsPage({super.key});

  @override
  ConsumerState<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends ConsumerState<ListsPage> {
  bool _showDone = true;

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(todoListsProvider);
    final selectedId = ref.watch(selectedListProvider);
    final recados = selectedId == recadosListId;
    final current = lists.where((l) => l.entityId == selectedId).firstOrNull ?? lists.firstOrNull;
    final itemsAsync = current == null ? null : ref.watch(todoItemsProvider(current.entityId));
    final items = itemsAsync?.valueOrNull ?? const <TodoItem>[];
    final pending = items.where((i) => !i.done).toList();
    final done = items.where((i) => i.done).toList();
    final actions = ref.read(todoActionsProvider);

    return KFadeUp(
      child: KSection(
        padding: const EdgeInsets.all(28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Text(l10n.listsTitle, style: KText.pageTitle),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        _RecadosButton(on: recados, onTap: () => ref.read(selectedListProvider.notifier).state = recadosListId),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 26, 6, 14),
                          child: Text(
                            l10n.listsTitle.toUpperCase(),
                            style: KText.s(15, weight: FontWeight.w700, spacing: 1, color: KColors.muted),
                          ),
                        ),
                        for (final l in lists) ...[
                          _ListButton(
                            list: l,
                            on: !recados && l.entityId == current?.entityId,
                            onTap: () => ref.read(selectedListProvider.notifier).state = l.entityId,
                          ),
                          const SizedBox(height: 14),
                        ],
                        KPress(
                          onTap: () => showKModal(context, (_) => const _NewListModal()),
                          child: KDashedBox(
                            radius: 26,
                            child: SizedBox(
                              height: 88,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  KIcon(KIcons.plus, size: 28, color: KColors.ink2, stroke: 2.2),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.listsNew,
                                    style: KText.s(22, weight: FontWeight.w600, color: KColors.ink2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(30)),
                child: recados
                    ? const _RecadosView()
                    : current == null
                    ? Center(
                        child: Text(l10n.listsNoneInHa, style: KText.s(24, color: KColors.muted)),
                      )
                    : Column(
                        key: ValueKey(current.entityId),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(current.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.d(44, spacing: -1)),
                                    const SizedBox(height: 4),
                                    Text(
                                      pending.isEmpty ? l10n.listsAllDone : l10n.listsItemsPending(pending.length),
                                      style: KText.s(21, color: KColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              if (done.isNotEmpty)
                                KButton(
                                  label: l10n.listsClearDone,
                                  height: 60,
                                  fontSize: 20,
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  onTap: () => actions.clearDone(current.entityId).catchError(KToast.error),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          KPress(
                            onTap: () => showItemModal(context, list: current, existing: items),
                            child: Container(
                              height: 80,
                              padding: const EdgeInsets.fromLTRB(18, 0, 24, 0),
                              decoration: BoxDecoration(color: KColors.tile, borderRadius: BorderRadius.circular(22)),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(color: KColors.accent, shape: BoxShape.circle),
                                    child: const Center(child: KIcon(KIcons.plus, size: 28, color: KColors.onAccent, stroke: 2.2)),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    l10n.listsAddItem,
                                    style: KText.s(24, weight: FontWeight.w500, color: KColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: itemsAsync != null && itemsAsync.isLoading && !itemsAsync.hasValue
                                ? Center(child: CircularProgressIndicator(color: KColors.accentFg))
                                : ListView(
                                    children: [
                                      for (final it in pending)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Container(
                                            constraints: const BoxConstraints(minHeight: 80),
                                            decoration: BoxDecoration(color: KColors.tile, borderRadius: BorderRadius.circular(22)),
                                            child: Row(
                                              children: [
                                                KPress(
                                                  onTap: () => actions.update(current.entityId, it, done: true).catchError(KToast.error),
                                                  child: const SizedBox(width: 92, height: 80, child: Center(child: KCheckCircle(done: false, size: 46))),
                                                ),
                                                Expanded(
                                                  child: KPress(
                                                    onTap: () => showItemModal(context, list: current, item: it, existing: items),
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(right: 24),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(it.name, style: KText.s(24, weight: FontWeight.w500)),
                                                          ),
                                                          if (it.detail.isNotEmpty) ...[
                                                            const SizedBox(width: 16),
                                                            Text(it.detail, style: KText.s(20, color: KColors.muted)),
                                                          ],
                                                          const SizedBox(width: 16),
                                                          KIcon(KIcons.chevronRight, size: 24, color: KColors.faint),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (pending.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 48),
                                          child: Text(
                                            l10n.listsNothingPending,
                                            textAlign: TextAlign.center,
                                            style: KText.s(24, color: KColors.muted),
                                          ),
                                        ),
                                      if (done.isNotEmpty) ...[
                                        KPress(
                                          onTap: () => setState(() => _showDone = !_showDone),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
                                            child: SizedBox(
                                              height: 64,
                                              child: Row(
                                                children: [
                                                  AnimatedRotation(
                                                    turns: _showDone ? .25 : 0,
                                                    duration: const Duration(milliseconds: 250),
                                                    child: KIcon(KIcons.chevronRight, size: 24, color: KColors.ink2, stroke: 2.2),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    l10n.listsDoneCount(done.length),
                                                    style: KText.s(21, weight: FontWeight.w700, color: KColors.ink2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_showDone)
                                          for (final it in done)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 10),
                                              child: KPress(
                                                onTap: () => actions.update(current.entityId, it, done: false).catchError(KToast.error),
                                                child: Container(
                                                  constraints: const BoxConstraints(minHeight: 80),
                                                  padding: const EdgeInsets.fromLTRB(22, 0, 28, 0),
                                                  decoration: BoxDecoration(
                                                    color: KColors.tile.withValues(alpha: 0.55),
                                                    borderRadius: BorderRadius.circular(22),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const KCheckCircle(done: true, size: 46),
                                                      const SizedBox(width: 20),
                                                      Expanded(
                                                        child: Text(
                                                          it.name,
                                                          style: KText.s(
                                                            22,
                                                            weight: FontWeight.w500,
                                                            color: KColors.faint,
                                                          ).copyWith(decoration: TextDecoration.lineThrough),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                      ],
                                    ],
                                  ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recados at the top of the lists: not a Home Assistant list — messages
/// left by voice — so it stands apart, with a badge for the unseen ones.
class _RecadosButton extends ConsumerWidget {
  const _RecadosButton({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(familyMessagesProvider);
    final unseen = messages.where((m) => !m.seen).length;
    return KPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 112,
        padding: const EdgeInsets.fromLTRB(16, 0, 22, 0),
        decoration: BoxDecoration(
          color: on ? KColors.accent : KColors.lightRoomBg,
          borderRadius: BorderRadius.circular(26),
          border: on ? null : Border.all(color: KColors.lightBtnBg, width: 2),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 4,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: on ? KColors.onAccent.withValues(alpha: 0.16) : KColors.lightBtnBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(child: KIcon(recadoIcon, size: 30, color: on ? KColors.onAccent : KColors.orangeInk)),
                    ),
                  ),
                  if (unseen > 0)
                    Positioned(
                      right: -2,
                      top: -4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 32),
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD92D20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: on ? KColors.accent : KColors.lightRoomBg, width: 4),
                        ),
                        child: Text(
                          '$unseen',
                          style: KText.s(15, weight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.listsMessagesTitle,
                    style: KText.s(24, weight: FontWeight.w600, color: on ? KColors.onAccent : KColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unseen > 0
                        ? l10n.listsMessagesUnseen(unseen)
                        : messages.isEmpty
                        ? l10n.listsMessagesNone
                        : l10n.listsMessagesAllSeen,
                    style: KText.s(18, color: on ? KColors.onAccentMuted : KColors.orangeInk),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The messages, unseen first: for whom, from whom, when, the text; "Marcar
/// como visto" and delete. Left by voice, or written in [RecadoNewModal].
class _RecadosView extends ConsumerWidget {
  const _RecadosView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = [...ref.watch(familyMessagesProvider)]..sort((a, b) => a.seen != b.seen ? (a.seen ? 1 : -1) : b.at.compareTo(a.at));
    final members = ref.watch(familyMembersProvider);
    final unseen = messages.where((m) => !m.seen).length;
    final notifier = ref.read(familyMessagesProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.listsMessagesTitle, style: KText.d(44, spacing: -1)),
        const SizedBox(height: 4),
        Text(
          unseen > 0 ? '${l10n.listsMessagesUnseen(unseen)} · ${l10n.listsMessagesExpiry}' : l10n.listsMessagesExpiry,
          style: KText.s(21, color: KColors.muted),
        ),
        const SizedBox(height: 20),
        // Written by hand (the modal) or left by voice.
        KPress(
          onTap: () => showRecadoNewModal(context),
          child: Container(
            height: 80,
            padding: const EdgeInsets.fromLTRB(18, 0, 24, 0),
            decoration: BoxDecoration(color: KColors.tile, borderRadius: BorderRadius.circular(22)),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: KColors.accent, shape: BoxShape.circle),
                  child: Center(child: KIcon(KIcons.plus, size: 28, stroke: 2.4, color: KColors.onAccent)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(l10n.listsMessagesWrite, style: KText.s(24, color: KColors.muted)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              KIcon(KIcons.mic, size: 22, color: KColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  members.isEmpty ? l10n.listsMessagesByVoiceEveryone : l10n.listsMessagesByVoice(members.first.name),
                  style: KText.s(18, color: KColors.muted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 80),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(color: KColors.tile, shape: BoxShape.circle),
                          child: Center(child: KIcon(recadoIcon, size: 54, stroke: 1.8, color: KColors.solar)),
                        ),
                        const SizedBox(height: 18),
                        Text(l10n.listsMessagesNone, style: KText.d(36)),
                        const SizedBox(height: 18),
                        Text(
                          l10n.listsMessagesEmptyBody,
                          textAlign: TextAlign.center,
                          style: KText.s(21, color: KColors.muted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    return Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(color: m.seen ? KColors.tile.withValues(alpha: 0.6) : KColors.tile, borderRadius: BorderRadius.circular(26)),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(width: 8, color: m.seen ? Colors.transparent : KColors.lightIconBg),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        RecadoToChip(message: m, members: members),
                                        Text(
                                          recadoFrom(m),
                                          style: KText.s(18, color: KColors.muted).copyWith(fontStyle: m.from == null ? FontStyle.italic : null),
                                        ),
                                        if (!m.seen)
                                          Container(
                                            height: 32,
                                            padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
                                            decoration: BoxDecoration(color: KColors.orangeTint, borderRadius: BorderRadius.circular(16)),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                RepaintBoundary(
                                                  child: KBlink(
                                                    child: Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(color: KColors.orange, shape: BoxShape.circle),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  l10n.listsMessagesUnseenBadge,
                                                  style: KText.s(15, weight: FontWeight.w700, color: KColors.orangeInk),
                                                ),
                                              ],
                                            ),
                                          ),
                                        Text(recadoWhen(m.at), style: KText.s(17, color: KColors.muted)),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      m.text,
                                      style: KText.s(
                                        26,
                                        height: 1.45,
                                        weight: m.seen ? FontWeight.w400 : FontWeight.w500,
                                        color: m.seen ? KColors.muted : KColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        if (!m.seen)
                                          KButton.primary(
                                            label: l10n.listsMessagesMarkSeen,
                                            icon: KIcons.check,
                                            iconSize: 24,
                                            height: 60,
                                            fontSize: 20,
                                            onTap: () => notifier.markSeen({m.id}).catchError((Object e) => KToast.error(e)),
                                          )
                                        else
                                          Row(
                                            children: [
                                              KIcon(KIcons.check, size: 22, stroke: 2.4, color: KColors.muted),
                                              const SizedBox(width: 8),
                                              Text(recadoSeen(m), style: KText.s(18, color: KColors.muted)),
                                            ],
                                          ),
                                        const Spacer(),
                                        Text(l10n.listsMessagesDeletesIn(m.daysLeft <= 1 ? 1 : m.daysLeft), style: KText.s(16, color: KColors.faint)),
                                        const SizedBox(width: 12),
                                        KCircleButton(
                                          icon: KIcons.trash,
                                          size: 60,
                                          iconSize: 24,
                                          fg: KColors.muted,
                                          onTap: () => notifier.delete(m.id).catchError((Object e) => KToast.error(e)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ListButton extends StatelessWidget {
  const _ListButton({required this.list, required this.on, required this.onTap});

  final TodoListInfo list;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 104,
        padding: const EdgeInsets.fromLTRB(16, 0, 22, 0),
        decoration: BoxDecoration(color: on ? KColors.accent : KColors.sub, borderRadius: BorderRadius.circular(26)),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: on ? KColors.onAccent.withValues(alpha: 0.16) : KColors.tile, borderRadius: BorderRadius.circular(20)),
              child: Center(child: KIcon(listIcon(list.icon), size: 30, color: on ? KColors.onAccent : KColors.ink)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(24, weight: FontWeight.w600, color: on ? KColors.onAccent : KColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    list.pending == 0 ? l10n.listsAllDone : l10n.listsPendingCount(list.pending),
                    style: KText.s(18, color: on ? KColors.onAccentMuted : KColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Nova lista": a name and an icon. Creates a Local To-do list in HA.
class _NewListModal extends ConsumerStatefulWidget {
  const _NewListModal();

  @override
  ConsumerState<_NewListModal> createState() => _NewListModalState();
}

class _NewListModalState extends ConsumerState<_NewListModal> {
  final _name = TextEditingController();
  String _icon = 'list';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await createTodoList(ref, name, _icon);
      OnScreenKeyboardController.instance.close();
      KToast.show(l10n.listsCreated(name));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      KToast.error(e);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KModal(
      keyboardTop: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KModalHeader(title: l10n.listsNew),
          const SizedBox(height: 24),
          KFieldLabel(l10n.listsFieldName),
          const SizedBox(height: 12),
          KTextField(
            controller: _name,
            hint: l10n.listsNameHint,
            autofocus: true,
            options: KeyboardOptions(doneLabel: l10n.listsCreateShort, onDone: _create),
          ),
          const SizedBox(height: 24),
          KFieldLabel(l10n.listsFieldIcon),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (i, k) in todoListIcons.indexed) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(
                  child: KPress(
                    onTap: () => setState(() => _icon = k),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 72,
                      decoration: BoxDecoration(color: _icon == k ? KColors.accent : KColors.sub, borderRadius: BorderRadius.circular(22)),
                      child: Center(child: KIcon(listIcon(k), size: 30, color: _icon == k ? KColors.onAccent : KColors.ink)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          KModalFooter(saveLabel: l10n.listsCreate, canSave: _name.text.trim().isNotEmpty, busy: _busy, onSave: _create),
        ],
      ),
    );
  }
}
