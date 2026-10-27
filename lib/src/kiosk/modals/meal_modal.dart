import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/ha_providers.dart';
import '../../widgets/on_screen_keyboard_controller.dart';
import '../browser/browser.dart';
import '../data/meals_data.dart';
import '../data/dates.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/kiosk_widgets.dart';
import 'kitchen_modal.dart';

Future<void> showMealModal(BuildContext context, {required DateTime day, required MealType type}) =>
    showKModal(context, (_) => MealModal(day: day, type: type));

/// Plan or edit one meal (the design's "Modal de refeição"): the dish
/// (typed or picked from favourites), where, when, and a note. Opened from
/// the Refeições grid and from Início's "Refeições" card.
class MealModal extends ConsumerStatefulWidget {
  const MealModal({super.key, required this.day, required this.type});

  final DateTime day;
  final MealType type;

  @override
  ConsumerState<MealModal> createState() => _MealModalState();
}

class _MealModalState extends ConsumerState<MealModal> {
  late final Meal? _existing = ref.read(mealPlanProvider)[mealKey(widget.day, widget.type)];
  late final _dish = TextEditingController(text: _existing?.dish ?? '');
  late final _note = TextEditingController(text: _existing?.note ?? '');
  final _dishFocus = FocusNode();
  final _noteFocus = FocusNode();
  late MealPlace _place = _existing?.place ?? MealPlace.casa;
  late int _time = _existing == null ? widget.type.defaultMinutes : KDates.toMinutes(_existing.time);

  @override
  void initState() {
    super.initState();
    _dish.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _dish.dispose();
    _note.dispose();
    _dishFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  /// The planned recipe's page, while the dish is still the one it was for.
  bool _cooking = false;

  /// Modo cozinha from the recipe's own page (read by the integration, the
  /// same way the assistant's show_recipe does).
  Future<void> _cook(String url) async {
    OnScreenKeyboardController.instance.close();
    setState(() => _cooking = true);
    try {
      final r = await ref.read(haWebSocketClientProvider).command('bytehomedash/get_recipe', {'url': url});
      if (!mounted) return;
      final recipe = KitchenRecipe((r as Map).cast<String, dynamic>());
      if (recipe.steps.isEmpty) throw Exception(l10n.mealsRecipeNoSteps);
      final nav = Navigator.of(context);
      nav.pop();
      unawaited(showKitchen(nav.context, recipe));
    } catch (e) {
      if (mounted) setState(() => _cooking = false);
      KToast.error(e);
    }
  }

  String? get _recipeUrl => _existing?.url != null && _dish.text.trim() == _existing!.dish ? _existing.url : null;

  Future<void> _put(Meal? meal) async {
    try {
      OnScreenKeyboardController.instance.close();
      Navigator.of(context).pop();
      await ref.read(mealPlanProvider.notifier).put(widget.day, widget.type, meal);
    } catch (e) {
      KToast.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = mealFavorites(ref.watch(mealPlanProvider), widget.type);
    final hasDish = _dish.text.trim().isNotEmpty;
    return KModal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KModalHeader(title: widget.type.label, subtitle: KDates.cap(KDates.longLower(widget.day))),
          const SizedBox(height: 24),
          KFieldLabel(l10n.mealsFieldDish),
          const SizedBox(height: 12),
          KTextField(
            controller: _dish,
            focusNode: _dishFocus,
            hint: l10n.mealsDishHint,
            autofocus: _existing == null,
            options: KeyboardOptions(
              suggestions: (t) {
                final q = t.trim().toLowerCase();
                return q.isEmpty ? const [] : favorites.where((f) => f.toLowerCase().startsWith(q) && f != t).toList();
              },
              doneLabel: l10n.commonNext,
              onDone: () => _noteFocus.requestFocus(),
              onSuggest: (s) {
                _dish.text = s;
                _noteFocus.requestFocus();
              },
            ),
          ),
          // A dish planned from a recipe page: open the page, or cook from it
          // (Modo cozinha). Otherwise, a search for one. The browser sits
          // below every modal, so this one closes first.
          if (_recipeUrl case final url?) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: _existing?.image == null
                          ? ColoredBox(
                              color: KColors.chipAlt,
                              child: Center(child: KIcon(_chef, size: 32, color: KColors.muted)),
                            )
                          : Image.network(
                              _existing!.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => ColoredBox(color: KColors.chipAlt),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mealsRecipe.toUpperCase(),
                          style: KText.s(15, weight: FontWeight.w700, spacing: 1, color: KColors.muted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Uri.tryParse(url)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KText.s(20, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  KButton(
                    label: l10n.mealsOpenSite,
                    icon: _globe,
                    height: 64,
                    fontSize: 20,
                    onTap: () {
                      OnScreenKeyboardController.instance.close();
                      Navigator.of(context).pop();
                      Browser.open(context, url: url);
                    },
                  ),
                  const SizedBox(width: 12),
                  KButton.primary(
                    label: _cooking ? l10n.mealsOpening : l10n.mealsKitchenMode,
                    icon: _chef,
                    iconSize: 24,
                    height: 64,
                    fontSize: 20,
                    onTap: _cooking ? null : () => _cook(url),
                  ),
                ],
              ),
            ),
          ] else if (hasDish)
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: const Offset(-10, 8),
                child: KPress(
                  onTap: () {
                    OnScreenKeyboardController.instance.close();
                    Navigator.of(context).pop();
                    Browser.open(context, url: browserSearch(l10n.mealsRecipeSearch(_dish.text.trim())));
                  },
                  child: SizedBox(
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          KIcon(_globe, size: 22, color: KColors.muted, stroke: 2),
                          const SizedBox(width: 8),
                          Text(
                            l10n.mealsSearchRecipe,
                            style: KText.s(18, weight: FontWeight.w600, color: KColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          KFieldLabel(l10n.mealsFieldFavorites),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final f in favorites)
                KChip(
                  label: f,
                  on: _dish.text == f,
                  padX: 26,
                  onTap: () {
                    _dish.text = f;
                    OnScreenKeyboardController.instance.close();
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KFieldLabel(l10n.mealsFieldWhere),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [for (final p in MealPlace.values) KChip(label: p.label, on: _place == p, padX: 26, onTap: () => setState(() => _place = p))],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KFieldLabel(l10n.mealsFieldTime),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(28, 8, 10, 8),
                      decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(26)),
                      child: Row(
                        children: [
                          Expanded(child: Text(KDates.minutes(_time), style: KText.d(40))),
                          KStepButton(plus: false, onTap: () => setState(() => _time = (_time - 15).clamp(0, 23 * 60 + 45))),
                          const SizedBox(width: 10),
                          KStepButton(plus: true, onTap: () => setState(() => _time = (_time + 15).clamp(0, 23 * 60 + 45))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          KFieldLabel(l10n.mealsFieldNotes, optional: true),
          const SizedBox(height: 12),
          KTextField(controller: _note, focusNode: _noteFocus, hint: l10n.mealsNoteHint, height: 80, fontSize: 24),
          const SizedBox(height: 24),
          KModalFooter(
            saveLabel: l10n.commonSave,
            canSave: hasDish,
            deleteLabel: l10n.commonRemove,
            onDelete: _existing == null ? null : () => _put(null),
            onSave: () => _put(
              Meal(
                dish: _dish.text.trim(),
                place: _place,
                time: KDates.minutes(_time),
                note: _note.text.trim(),
                url: _recipeUrl,
                image: _recipeUrl != null ? _existing?.image : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _globe = '<path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3 12h18M12 3c2.5 2.5 3.5 5.5 3.5 9s-1 6.5-3.5 9c-2.5-2.5-3.5-5.5-3.5-9s1-6.5 3.5-9z"/>';

const _chef = '<path d="M6 13.9A4 4 0 0 1 7 6a5 5 0 0 1 10 0 4 4 0 0 1 1 7.9V20H6zM6 17h12"/>';
