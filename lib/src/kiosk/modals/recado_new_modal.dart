import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../widgets/on_screen_keyboard_controller.dart';
import '../data/family_data.dart';
import '../data/messages_data.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/kiosk_widgets.dart';
import '../widgets/recado_widgets.dart';

const _maxLength = 300;
const _mobileIcon = '<path d="M8 2h8a2 2 0 0 1 2 2v16a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2zM11 18h2"/>';

List<String> get _suggestions => [l10n.recadoNewSuggestDinner, l10n.recadoNewSuggestBack, l10n.recadoNewSuggestDontForget];

Future<void> showRecadoNewModal(BuildContext context) => showKModal(context, (_) => const RecadoNewModal());

/// Writing a recado by hand (design "RecadoNovoModal", from Listas ›
/// Recados): for whom, the text, from whom, and whether it also goes to
/// the phone. Stored like one left by voice, so it shows on every screen
/// until someone sees it.
class RecadoNewModal extends ConsumerStatefulWidget {
  const RecadoNewModal({super.key});

  @override
  ConsumerState<RecadoNewModal> createState() => _RecadoNewModalState();
}

/// [_RecadoNewModalState._to]'s value for everyone.
const _everyone = '';

class _RecadoNewModalState extends ConsumerState<RecadoNewModal> {
  final _text = TextEditingController();

  /// A person's name, [_everyone], or null while nobody is chosen.
  String? _to;

  /// Who's leaving it; null is "Não dizer".
  String? _from;
  bool _phone = true;

  @override
  void initState() {
    super.initState();
    // A listener on the controller, not the field's onChanged: text typed on
    // the on-screen keyboard only reaches the controller.
    _text.addListener(() {
      if (_text.text.length > _maxLength) {
        final cut = _text.text.substring(0, _maxLength);
        _text.value = TextEditingValue(
          text: cut,
          selection: TextSelection.collapsed(offset: cut.length),
        );
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSave => _to != null && _text.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;
    final to = _to == _everyone ? null : _to;
    OnScreenKeyboardController.instance.close();
    Navigator.of(context).pop();
    try {
      await ref.read(familyMessagesProvider.notifier).add(text: _text.text, to: to, from: _from, phone: _phone);
    } catch (e) {
      KToast.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(familyMembersProvider);
    final length = _text.text.length;
    final phoneLabel = switch (_to) {
      null => l10n.recadoNewPhone,
      _everyone => l10n.recadoNewPhoneEveryone,
      final String name => l10n.recadoNewPhoneOf(name),
    };
    return KModal(
      keyboardTop: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: KColors.orangeTint, borderRadius: BorderRadius.circular(20)),
                child: Center(child: KIcon(recadoIcon, size: 32, color: KColors.orangeInk)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.recadoNewTitle, style: KText.modalTitle),
                    const SizedBox(height: 4),
                    Text(l10n.recadoNewSubtitle, style: KText.s(20, color: KColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              KCircleButton(
                icon: KIcons.close,
                size: 64,
                iconSize: 26,
                stroke: 2.2,
                bg: KColors.chip,
                fg: KColors.ink,
                border: null,
                onTap: () {
                  OnScreenKeyboardController.instance.close();
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
          const SizedBox(height: 26),
          KFieldLabel(l10n.tasksFieldWho),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PersonChip(
                label: l10n.recadoNewEveryone,
                color: KColors.accent,
                icon: recadoEveryoneIcon,
                on: _to == _everyone,
                onTap: () => setState(() => _to = _everyone),
              ),
              for (final m in members)
                _PersonChip(label: m.name, color: m.color.color, initial: m.initial, on: _to == m.name, onTap: () => setState(() => _to = m.name)),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: KFieldLabel(l10n.recadoNewText)),
              Text(
                '$length / $_maxLength',
                style: KText.s(16, weight: FontWeight.w600, color: length > _maxLength - 30 ? KColors.orange : KColors.faint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          KTextField(
            controller: _text,
            hint: l10n.recadoNewHint,
            height: 190,
            maxLines: 4,
            autofocus: true,
            options: KeyboardOptions(
              suggestions: (t) => t.isEmpty ? _suggestions : const [],
              onSuggest: (s) {
                final text = '$s ';
                _text.value = TextEditingValue(
                  text: text,
                  selection: TextSelection.collapsed(offset: text.length),
                );
              },
            ),
          ),
          const SizedBox(height: 26),
          KFieldLabel(l10n.recadoNewFrom),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final m in members)
                _PersonChip(label: m.name, color: m.color.color, initial: m.initial, on: _from == m.name, onTap: () => setState(() => _from = m.name)),
              _PersonChip(label: l10n.recadoNewAnonymous, color: KColors.faint, initial: '?', on: _from == null, onTap: () => setState(() => _from = null)),
            ],
          ),
          const SizedBox(height: 26),
          KPress(
            onTap: () => setState(() => _phone = !_phone),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  KIcon(_mobileIcon, size: 28, color: KColors.muted),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(phoneLabel, style: KText.s(21, weight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(l10n.recadoNewPhoneSub, style: KText.s(16, color: KColors.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  KSwitch(on: _phone),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          KModalFooter(saveLabel: l10n.recadoNewSave, canSave: _canSave, onSave: _save),
        ],
      ),
    );
  }
}

/// A "Para quem" / "De quem" choice: the person's round avatar and name,
/// ringed in the accent when chosen.
class _PersonChip extends StatelessWidget {
  const _PersonChip({required this.label, required this.color, required this.on, required this.onTap, this.initial, this.icon});

  final String label;
  final Color color;
  final String? initial;
  final String? icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        padding: const EdgeInsets.fromLTRB(8, 0, 22, 0),
        decoration: BoxDecoration(
          color: on ? KColors.accentSoft : KColors.sub,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: on ? KColors.accent : Colors.transparent, width: 2.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: icon != null
                  ? KIcon(icon!, size: 22, stroke: 2.6, color: Colors.white)
                  : Text(
                      initial ?? '',
                      style: KText.s(18, weight: FontWeight.w700, color: Colors.white),
                    ),
            ),
            const SizedBox(width: 10),
            Text(label, maxLines: 1, style: KText.s(20, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
