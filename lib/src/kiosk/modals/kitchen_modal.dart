import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ha_client/ha_websocket_client.dart';
import '../../l10n/l10n.dart';
import '../../services/ringtone_sound.dart';
import '../../services/screen_power_controller.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/bubble.dart';
import '../widgets/kiosk_widgets.dart';

/// A recipe to cook from, as the assistant's show_recipe tool sends it: the
/// page's own title, ingredients and steps (any of the rest may be missing).
class KitchenRecipe {
  KitchenRecipe(Map<String, dynamic> e)
    : url = e['url'] as String? ?? '',
      title = e['title'] as String? ?? l10n.kitchenRecipeDefaultTitle,
      image = e['image'] as String?,
      servings = e['servings'] as String?,
      minutes = (e['minutes'] as num?)?.toInt(),
      ingredients = [for (final i in e['ingredients'] as List? ?? const []) '$i'],
      steps = [for (final s in e['steps'] as List? ?? const []) '$s'],
      step = ((e['step'] as num?)?.toInt() ?? 1) - 1;

  final String url, title;
  final String? image, servings;
  final int? minutes;
  final List<String> ingredients, steps;

  /// From 0.
  final int step;

  String get host => Uri.tryParse(url)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? '';
}

/// Opens Modo cozinha with [recipe] — or, if it's already cooking (open or
/// in its bubble), brings it back.
Future<void> showKitchen(BuildContext context, KitchenRecipe recipe) async {
  final session = KitchenSession.instance;
  if (!session.active || session.recipe.url != recipe.url) session.start(recipe);
  await openKitchenView(context);
}

/// Shows the running session full screen (from its bubble, or after a
/// voice request).
Future<void> openKitchenView(BuildContext context) async {
  final session = KitchenSession.instance;
  session.minimized = false;
  if (KitchenModal.isOpen || !session.active) return;
  KitchenModal.isOpen = true;
  try {
    await showKModal(context, (_) => const KitchenModal());
  } finally {
    KitchenModal.isOpen = false;
  }
}

const _forkIcon = '<path d="M7 3v8a2 2 0 0 0 2 2v8M11 3v8a2 2 0 0 1-2 2M9 3v6M17 21V3c-2 1.5-3 4-3 7v4h3"/>';
const _chefIcon = '<path d="M6 13.9A4 4 0 0 1 7 6a5 5 0 0 1 10 0 4 4 0 0 1 1 7.9V20H6zM6 17h12"/>';
const _timerIcon = '<path d="M12 21a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM12 9v4l2.5 2M9 2h6"/>';
const _clockIcon = '<path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2"/>';
const _peopleIcon = '<path d="M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM2 21v-1a6 6 0 0 1 6-6h2a6 6 0 0 1 6 6v1"/>';
const _listIcon = '<path d="M9 6h12M9 12h12M9 18h12M4 6h.01M4 12h.01M4 18h.01"/>';
const _micIcon = '<path d="M9 3h6v11H9zM5 11a7 7 0 0 0 14 0M12 18v3"/>';
const _prevIcon = '<path d="M15 5l-7 7 7 7"/>';
const _nextIcon = '<path d="M9 5l7 7-7 7"/>';
const _minimizeIcon = '<path d="M6 12h12"/>';

/// "400 g de bacalhau" → ("400 g", "de bacalhau"): the quantity is bold.
(String, String) _splitIngredient(String s) {
  final m = RegExp(
    r'^((?:\d+(?:[.,/]\d+)?|[½¼¾⅓⅔])(?:\s*(?:a|-)\s*\d+)?\s*(?:kg|g|gr|mg|l|dl|cl|ml|colher(?:es)?(?: de (?:sopa|chá|sobremesa))?|c\.\s*(?:de\s*)?(?:sopa|chá)|chávenas?|copos?|dentes?|latas?|pacotes?|pitadas?|fatias?|ramos?|folhas?|unidades?|cups?|tablespoons?|teaspoons?|tbsps?|tsps?|ounces?|oz|pounds?|lbs?)?\.?)\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(s.trim());
  return m == null ? ('', s.trim()) : (m.group(1)!, m.group(2)!);
}

/// A quantity for [k] times the servings ("400 g" ×1,5 → "600 g"): grams
/// and millilitres to the nearest 10 past 100, everything else to halves.
/// Ranges and words are left as they are.
String _scaleQty(String qty, double k) {
  if (k == 1) return qty;
  final m = RegExp(r'^(\d+/\d+|\d+(?:[.,]\d+)?|[½¼¾⅓⅔])\s*(.*)$').firstMatch(qty);
  if (m == null) return qty;
  final raw = m.group(1)!, unit = m.group(2)!;
  const glyphs = {'½': 0.5, '¼': 0.25, '¾': 0.75, '⅓': 1 / 3, '⅔': 2 / 3};
  final double? n =
      glyphs[raw] ?? (raw.contains('/') ? double.parse(raw.split('/')[0]) / double.parse(raw.split('/')[1]) : double.tryParse(raw.replaceAll(',', '.')));
  if (n == null) return qty;
  var v = n * k;
  v = RegExp(r'^(g|ml)\b', caseSensitive: false).hasMatch(unit) ? (v >= 100 ? (v / 10).round() * 10.0 : v.roundToDouble()) : (v * 2).round() / 2;
  final text = v == v.roundToDouble() ? v.toInt().toString() : v.toString().replaceAll('.', ',');
  return unit.isEmpty ? text : '$text $unit';
}

enum _View { step, ingredients, done }

enum _Timer { running, paused, ended }

/// One step's timer: they keep counting when the step changes or the recipe
/// is minimised.
class _StepTimer {
  _StepTimer(this.total) : left = total;

  final int total;
  int left;
  _Timer state = _Timer.running;
}

/// The recipe being cooked, kept while it's minimised to a bubble: the step,
/// each step's timer, what's ticked off and for how many people.
class KitchenSession extends ChangeNotifier {
  KitchenSession._();

  static final instance = KitchenSession._();

  KitchenRecipe recipe = KitchenRecipe(const {});
  bool active = false;
  bool _minimized = false;
  int i = 0;
  int dir = 1;
  _View view = _View.step;
  bool list = false;
  bool askExit = false;
  final ticked = <int>{};
  final timers = <int, _StepTimer>{};

  /// For how many people the ingredients are shown (the recipe's own
  /// number until changed).
  int? serves;

  /// What the last voice step was ("próximo passo"…), shown for 3 s.
  String? voice;
  Timer? _voiceTimer, _tick, _alarm, _awake;
  StreamSubscription<Map<String, dynamic>>? _sub;
  HaWebSocketClient? _client;

  bool get minimized => _minimized;
  set minimized(bool v) {
    if (_minimized == v) return;
    _minimized = v;
    notifyListeners();
  }

  /// The servings the recipe states, when it's a plain number.
  int? get baseServings => int.tryParse(RegExp(r'^\s*(\d+)').firstMatch(recipe.servings ?? '')?.group(1) ?? '');

  void attach(HaWebSocketClient client) {
    if (identical(client, _client)) return;
    _client = client;
    _sub?.cancel();
    _sub = client.assistantEvents.listen(_onEvent);
  }

  void start(KitchenRecipe r) {
    _reset();
    recipe = r;
    i = r.step.clamp(0, r.steps.length - 1);
    active = true;
    // "O ecrã não se apaga enquanto cozinha."
    _awake = Timer.periodic(const Duration(seconds: 30), (_) => ScreenPowerController.instance.noteActivity());
    notifyListeners();
  }

  void end() {
    _reset();
    active = false;
    notifyListeners();
  }

  void _reset() {
    _voiceTimer?.cancel();
    _tick?.cancel();
    _tick = null;
    _alarm?.cancel();
    _alarm = null;
    _awake?.cancel();
    timers.clear();
    ticked.clear();
    serves = null;
    voice = null;
    view = _View.step;
    list = askExit = _minimized = false;
  }

  /// A step from the assistant ("próximo passo"): the same recipe moves on;
  /// another one starts afresh. Voice commands for the view itself
  /// (minimise, leave) come as `kitchen` events.
  void _onEvent(Map<String, dynamic> e) {
    if (!active) return;
    switch (e['action']) {
      case 'recipe':
        final next = KitchenRecipe(e);
        if (next.steps.isEmpty) return;
        if (next.url != recipe.url) {
          start(next);
          return;
        }
        recipe = next;
        final step = next.step.clamp(0, next.steps.length - 1);
        go(
          step,
          step < i ? -1 : 1,
          voice: step == i + 1
              ? l10n.kitchenVoiceNextStep
              : step == i
              ? l10n.kitchenVoiceRepeat
              : step == i - 1
              ? l10n.kitchenVoiceBack
              : l10n.kitchenVoiceStep(step + 1),
        );
      case 'kitchen':
        switch (e['command']) {
          case 'minimize':
            askExit = false;
            minimized = true;
          case 'exit':
            end();
          case 'continue':
            askExit = false;
            notifyListeners();
          case 'ingredients':
            view = _View.ingredients;
            notifyListeners();
        }
    }
  }

  void go(int to, int direction, {String? voice}) {
    if (to < 0) return;
    _voiceTimer?.cancel();
    if (to >= recipe.steps.length) {
      view = _View.done;
      this.voice = null;
      notifyListeners();
      return;
    }
    i = to;
    dir = direction;
    view = _View.step;
    list = false;
    this.voice = voice;
    if (voice != null) {
      _voiceTimer = Timer(const Duration(seconds: 3), () {
        this.voice = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  int minutesOf(int step) {
    // Recipes come from sites in any language.
    final m = RegExp(r'(\d+)\s*(?:minutos?|minutes?|mins?)\b', caseSensitive: false).firstMatch(recipe.steps[step]);
    return m == null ? 0 : int.parse(m.group(1)!);
  }

  void startTimer(int step) {
    final t = timers[step] ??= _StepTimer(minutesOf(step) * 60);
    t.state = _Timer.running;
    _tick ??= Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    notifyListeners();
  }

  void pauseTimer(int step) {
    timers[step]?.state = _Timer.paused;
    notifyListeners();
  }

  /// "Parar alarme": the step's timer goes; the chime stops when no other
  /// timer has ended.
  void clearTimer(int step) {
    timers.remove(step);
    if (!timers.values.any((t) => t.state == _Timer.ended)) {
      _alarm?.cancel();
      _alarm = null;
    }
    notifyListeners();
  }

  void _onTick() {
    var running = false;
    for (final t in timers.values) {
      if (t.state != _Timer.running) continue;
      if (--t.left <= 0) {
        t
          ..left = 0
          ..state = _Timer.ended;
        _ring();
      } else {
        running = true;
      }
    }
    if (!running) {
      _tick?.cancel();
      _tick = null;
    }
    notifyListeners();
  }

  /// The alarm: a chime every 2 s for up to a minute, until stopped.
  void _ring() {
    if (_alarm != null) return;
    var rings = 0;
    void chime() => playRingtone('triangulo', () => rootBundle.load('assets/ringtones/triangulo.wav'), 0.9).ignore();
    chime();
    ScreenPowerController.instance.setPowered(true);
    _alarm = Timer.periodic(const Duration(seconds: 2), (t) {
      if (++rings >= 30) {
        t.cancel();
        _alarm = null;
      }
      chime();
    });
  }

  /// The timer the bubble shows: an ended one first, else the one with the
  /// least time left.
  _StepTimer? get soonest {
    final all = timers.values.toList()..sort((a, b) => a.left.compareTo(b.left));
    return all.isEmpty ? null : all.first;
  }
}

String _clock(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

/// Modo cozinha (design: ModoCozinha): one step at a time in large type, to
/// read from across the kitchen, with big buttons for busy hands. Steps also
/// follow the assistant ("próximo passo", "repete", "volta atrás"); a step
/// that mentions minutes offers a timer, which keeps counting on other steps
/// and while minimised. The screen stays on meanwhile.
class KitchenModal extends ConsumerStatefulWidget {
  const KitchenModal({super.key});

  static bool isOpen = false;

  @override
  ConsumerState<KitchenModal> createState() => _KitchenModalState();
}

class _KitchenModalState extends ConsumerState<KitchenModal> {
  final _s = KitchenSession.instance;

  KitchenRecipe get _recipe => _s.recipe;
  int get _i => _s.i;
  _View get _view => _s.view;
  set _view(_View v) => _s.view = v;
  bool get _list => _s.list;
  set _list(bool v) => _s.list = v;
  int get _dir => _s.dir;
  Set<int> get _ticked => _s.ticked;
  String? get _voice => _s.voice;

  @override
  void initState() {
    super.initState();
    _s.addListener(_changed);
  }

  @override
  void dispose() {
    _s.removeListener(_changed);
    super.dispose();
  }

  /// Minimised or ended (by touch or voice): this view goes.
  void _changed() {
    if (!mounted) return;
    if (!_s.active || _s.minimized) {
      closeOwnRoute(context);
      return;
    }
    setState(() {});
  }

  void _go(int i, int dir) => _s.go(i, dir);

  int get _stepMinutes => _s.minutesOf(_i);

  /// "Sair" mid-recipe asks first (or offers to minimise); on the last step
  /// or once done it just closes.
  void _exit() {
    if (_view == _View.done || _i == _recipe.steps.length - 1) {
      _s.end();
    } else {
      setState(() => _s.askExit = true);
    }
  }

  void _minimize() {
    _s.askExit = false;
    _s.minimized = true;
  }

  @override
  Widget build(BuildContext context) {
    final r = _recipe;
    if (r.steps.isEmpty) return const SizedBox.shrink();
    final anim = ModalRoute.of(context)?.animation ?? const AlwaysStoppedAnimation(1.0);
    final done = _view == _View.done;
    final others = [
      for (final e in _s.timers.entries)
        if (e.key != _i) e,
    ]..sort((a, b) => a.key.compareTo(b.key));
    return FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.ease),
      child: Material(
        color: KColors.page,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 56, 56, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(r),
                  const SizedBox(height: 28),
                  if (!done) ...[_progress(r), const SizedBox(height: 28)],
                  if (!done && others.isNotEmpty) ...[_otherTimers(others), const SizedBox(height: 28)],
                  Expanded(
                    child: switch (_view) {
                      _View.step => _stepCard(r),
                      _View.ingredients => _ingredientsCard(r),
                      _View.done => _doneCard(r),
                    },
                  ),
                  if (!done) ...[const SizedBox(height: 28), _voiceHint(), const SizedBox(height: 28), _nav(r)],
                ],
              ),
            ),
            if (_list) _allSteps(r),
            if (_s.askExit) _exitDialog(r),
          ],
        ),
      ),
    );
  }

  /// Timers of other steps, still counting: tap to go back to that step.
  Widget _otherTimers(List<MapEntry<int, _StepTimer>> others) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final e in others)
        _Blinking(
          enabled: e.value.state == _Timer.ended,
          child: KPress(
            onTap: () => _go(e.key, e.key < _i ? -1 : 1),
            child: Container(
              height: 60,
              padding: const EdgeInsets.fromLTRB(14, 0, 22, 0),
              decoration: BoxDecoration(color: e.value.state == _Timer.ended ? KColors.orange : KColors.card, borderRadius: BorderRadius.circular(30)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KIcon(_timerIcon, size: 26, color: e.value.state == _Timer.ended ? Colors.white : KColors.ink),
                  const SizedBox(width: 10),
                  Text(
                    l10n.kitchenStepN(e.key + 1),
                    style: KText.s(20, weight: FontWeight.w700, color: e.value.state == _Timer.ended ? Colors.white : KColors.ink),
                  ),
                  const SizedBox(width: 10),
                  Text(switch (e.value.state) {
                    _Timer.ended => l10n.kitchenTimerEndedShort,
                    _Timer.paused => l10n.kitchenTimerPaused(_clock(e.value.left)),
                    _Timer.running => _clock(e.value.left),
                  }, style: KText.d(24, color: e.value.state == _Timer.ended ? Colors.white : KColors.ink)),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  Widget _exitDialog(KitchenRecipe r) => Positioned.fill(
    child: Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _s.askExit = false),
            child: ColoredBox(color: KColors.scrim),
          ),
        ),
        Positioned(
          left: 280,
          top: 820,
          width: 880,
          child: Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(36), boxShadow: KColors.shadowFloat),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.kitchenExitTitle, style: KText.d(40)),
                const SizedBox(height: 20),
                Text(
                  _s.timers.isNotEmpty ? l10n.kitchenExitBodyWithTimer(_i + 1, r.steps.length) : l10n.kitchenExitBody(_i + 1, r.steps.length),
                  style: KText.s(22, color: KColors.muted, height: 1.45),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    KIcon(_micIcon, size: 22, color: KColors.muted),
                    const SizedBox(width: 10),
                    Text(l10n.kitchenExitVoiceHint, style: KText.s(18, color: KColors.muted)),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    KButton(label: l10n.kitchenContinue, height: 72, border: null, bg: Colors.transparent, onTap: () => setState(() => _s.askExit = false)),
                    const SizedBox(width: 14),
                    KButton(label: l10n.kitchenMinimize, icon: _minimizeIcon, height: 72, onTap: _minimize),
                    const SizedBox(width: 14),
                    KButton(
                      label: l10n.kitchenExit,
                      height: 72,
                      weight: FontWeight.w700,
                      bg: KColors.redTint,
                      fg: KColors.red,
                      border: null,
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      onTap: _s.end,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _header(KitchenRecipe r) {
    final chips = [
      if (r.minutes case final m?) (_clockIcon, m >= 60 ? '${m ~/ 60} h${m % 60 > 0 ? ' ${m % 60} min' : ''}' : '$m min'),
      if (_s.baseServings case final b?) (_peopleIcon, _people(_s.serves ?? b)) else if (r.servings case final s?) (_peopleIcon, s),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.image case final img?) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              width: 132,
              height: 132,
              child: Image.network(
                img,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: KColors.chipAlt,
                  child: Center(child: KIcon(_forkIcon, size: 52, color: KColors.ink.withValues(alpha: 0.35))),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  KIcon(_forkIcon, size: 22, color: KColors.accentFg),
                  const SizedBox(width: 10),
                  Text(
                    l10n.kitchenModeLabel,
                    style: KText.s(17, weight: FontWeight.w700, spacing: 1, color: KColors.accentFg),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: KText.d(48, spacing: -0.5, height: 1.1)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final (icon, label) in chips)
                    Container(
                      height: 40,
                      padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                      decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          KIcon(icon, size: 20, color: KColors.ink2),
                          const SizedBox(width: 8),
                          Text(label, style: KText.s(18, weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  if (r.host.isNotEmpty) Text(r.host, style: KText.s(17, color: KColors.faint)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        KCircleButton(icon: _minimizeIcon, size: 72, iconSize: 30, stroke: 2.4, bg: KColors.card, border: null, onTap: _minimize),
        const SizedBox(width: 12),
        KButton(label: l10n.kitchenExit, icon: KIcons.close, height: 72, fontSize: 21, bg: KColors.card, border: null, onTap: _exit),
      ],
    );
  }

  Widget _progress(KitchenRecipe r) {
    final n = r.steps.length;
    final few = n <= 14;
    // The "of N" part is drawn fainter: split the sentence around it.
    final progress = l10n.kitchenProgress(_i + 1, '\u0000').split('\u0000');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: progress.first),
                  TextSpan(
                    text: l10n.kitchenOfTotal(n),
                    style: TextStyle(color: KColors.faint),
                  ),
                  if (progress.length > 1) TextSpan(text: progress[1]),
                ],
              ),
              style: KText.d(34),
            ),
            const Spacer(),
            if (!few) ...[
              KButton(label: l10n.kitchenAllSteps, icon: _listIcon, height: 60, fontSize: 19, bg: KColors.card, onTap: () => setState(() => _list = true)),
              const SizedBox(width: 14),
            ],
            if (r.ingredients.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: KColors.chipAlt, borderRadius: BorderRadius.circular(34)),
                child: Row(
                  children: [
                    for (final (view, label) in [(_View.step, l10n.kitchenTabStep), (_View.ingredients, l10n.kitchenTabIngredients(r.ingredients.length))])
                      KPress(
                        onTap: () => setState(() => _view = view),
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _view == view ? KColors.card : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: _view == view ? const [BoxShadow(color: Color(0x1A17191C), blurRadius: 8, offset: Offset(0, 2))] : null,
                          ),
                          child: Text(label, style: KText.s(20, weight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        // Up to 14 steps, a segment each; more, one continuous bar.
        if (few)
          Row(
            children: [
              for (var k = 0; k < n; k++) ...[
                if (k > 0) const SizedBox(width: 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 10,
                    decoration: BoxDecoration(
                      color: k < _i
                          ? KColors.accent
                          : k == _i
                          ? KColors.accentFg
                          : KColors.border,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ],
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(value: (_i + 1) / n, minHeight: 10, backgroundColor: KColors.border, color: KColors.accent),
          ),
      ],
    );
  }

  Widget _stepCard(KitchenRecipe r) {
    final text = r.steps[_i];
    final len = text.length;
    final size = len <= 120
        ? 64.0
        : len <= 260
        ? 54.0
        : len <= 420
        ? 44.0
        : 38.0;
    final mins = _stepMinutes;
    return _Slide(
      key: ValueKey('$_i|${r.url}|${_voice != null}'),
      dir: _dir,
      flash: _voice != null,
      child: Container(
        decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(40)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: KColors.accentSoft, shape: BoxShape.circle),
                    child: Text(
                      '${_i + 1}',
                      style: KText.d(40, weight: FontWeight.w600, color: KColors.accentFg),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(text, style: KText.d(size, weight: FontWeight.w400, height: 1.32, spacing: -0.3)),
                    ),
                  ),
                  if (mins > 0) ...[const SizedBox(height: 36), _timerBox(mins)],
                ],
              ),
            ),
            if (_voice case final v?)
              Positioned(
                top: 28,
                right: 28,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.fromLTRB(14, 0, 20, 0),
                  decoration: BoxDecoration(color: KColors.accent, borderRadius: BorderRadius.circular(26)),
                  child: Row(
                    children: [
                      KIcon(_micIcon, size: 22, color: KColors.onAccent),
                      const SizedBox(width: 10),
                      Text(
                        v,
                        style: KText.s(18, weight: FontWeight.w700, color: KColors.onAccent),
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

  Widget _timerBox(int mins) {
    final total = mins * 60;
    final t = _s.timers[_i];
    final left = t?.left ?? total;
    final ended = t?.state == _Timer.ended;
    final ring = ended ? KColors.orange : KColors.accent;
    String fmt(int s) => _clock(s);
    final (label, btnLabel, btnPrimary, onTap) = switch (t?.state) {
      _Timer.running => (l10n.kitchenTimerRunning, l10n.kitchenPause, false, () => _s.pauseTimer(_i)),
      _Timer.ended => (l10n.kitchenTimeUp, l10n.kitchenStopAlarm, true, () => _s.clearTimer(_i)),
      _Timer.paused => (l10n.kitchenTimerMinutes(mins), l10n.kitchenContinue, true, () => _s.startTimer(_i)),
      null => (l10n.kitchenTimerMinutes(mins), l10n.kitchenStart, true, () => _s.startTimer(_i)),
    };
    return _Blinking(
      enabled: ended,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        decoration: BoxDecoration(color: ended ? KColors.orangeTint : KColors.sub, borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(value: total == 0 ? 0 : 1 - left / total, strokeWidth: 8, backgroundColor: KColors.border, color: ring),
                  Center(child: KIcon(_timerIcon, size: 40, color: ring)),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: KText.s(19, weight: FontWeight.w600, color: KColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(fmt(left), style: KText.d(64, height: 1, spacing: -1)),
                ],
              ),
            ),
            if (btnPrimary)
              KButton.primary(label: btnLabel, height: 80, padding: const EdgeInsets.symmetric(horizontal: 32), bg: ended ? KColors.orange : null, onTap: onTap)
            else
              KButton(label: btnLabel, height: 80, padding: const EdgeInsets.symmetric(horizontal: 32), onTap: onTap),
          ],
        ),
      ),
    );
  }

  Widget _ingredientsCard(KitchenRecipe r) {
    final base = _s.baseServings;
    final serves = _s.serves ?? base;
    final k = base == null || serves == null ? 1.0 : serves / base;
    final note = base != null
        ? (_ticked.isNotEmpty ? l10n.kitchenIngredientsReady(_ticked.length, r.ingredients.length) : l10n.kitchenIngredientsTapHint)
        : (_ticked.isNotEmpty ? l10n.kitchenNoServingsReady(_ticked.length, r.ingredients.length) : l10n.kitchenNoServings);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(40)),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 20,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.kitchenIngredients, style: KText.d(40)),
                    const SizedBox(height: 4),
                    Text(note, style: KText.s(20, color: KColors.muted)),
                  ],
                ),
                // Doses: changing the people recalculates the quantities.
                if (base != null && serves != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),
                    decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(40)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.kitchenServesFor,
                          style: KText.s(20, weight: FontWeight.w600, color: KColors.muted),
                        ),
                        const SizedBox(width: 12),
                        Opacity(
                          opacity: serves > 1 ? 1 : 0.35,
                          child: KCircleButton(
                            icon: KIcons.minus,
                            size: 64,
                            iconSize: 28,
                            onTap: serves > 1 ? () => setState(() => _s.serves = serves - 1) : null,
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Text(_people(serves), textAlign: TextAlign.center, style: KText.d(34)),
                        ),
                        KCircleButton(icon: KIcons.plus, size: 64, iconSize: 28, onTap: serves < 24 ? () => setState(() => _s.serves = serves + 1) : null),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (k != 1)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(color: KColors.accentSoft, borderRadius: BorderRadius.circular(20)),
              child: Text(
                l10n.kitchenScaledNote(_people(base!), _people(serves!)),
                style: KText.s(18, weight: FontWeight.w600, color: KColors.accentFg),
              ),
            ),
          for (var j = 0; j < r.ingredients.length; j++)
            KPress(
              onTap: () => setState(() => _ticked.contains(j) ? _ticked.remove(j) : _ticked.add(j)),
              child: Container(
                constraints: const BoxConstraints(minHeight: 88),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                decoration: BoxDecoration(
                  border: j == 0 ? null : Border(top: BorderSide(color: KColors.divider, width: 1.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _ticked.contains(j) ? KColors.accent : Colors.transparent,
                        shape: BoxShape.circle,
                        border: _ticked.contains(j) ? null : Border.all(color: KColors.dashed, width: 3),
                      ),
                      child: _ticked.contains(j) ? KIcon(KIcons.check, size: 26, stroke: 2.8, color: KColors.onAccent) : null,
                    ),
                    const SizedBox(width: 22),
                    Expanded(child: _ingredientText(r.ingredients[j], _ticked.contains(j), k)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ingredientText(String raw, bool on, double scale) {
    final (q, name) = _splitIngredient(raw);
    final qty = q.isEmpty ? q : _scaleQty(q, scale);
    final style = KText.s(28, height: 1.35, color: on ? KColors.faint : KColors.ink).copyWith(decoration: on ? TextDecoration.lineThrough : null);
    return Text.rich(
      TextSpan(
        children: [
          if (qty.isNotEmpty)
            TextSpan(
              text: '$qty ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          TextSpan(text: name),
        ],
      ),
      style: style,
    );
  }

  Widget _doneCard(KitchenRecipe r) => Container(
    padding: const EdgeInsets.all(60),
    decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(40)),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 180,
          height: 180,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: KColors.greenTint, shape: BoxShape.circle),
          child: KIcon(KIcons.check, size: 90, stroke: 2.6, color: KColors.greenInk),
        ),
        const SizedBox(height: 28),
        Text(l10n.kitchenEnjoy, style: KText.d(72, spacing: -1)),
        const SizedBox(height: 28),
        Text(l10n.kitchenRecipeDone(r.steps.length), style: KText.s(26, color: KColors.muted)),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            KButton(label: l10n.kitchenReviewSteps, height: 88, fontSize: 24, padding: const EdgeInsets.symmetric(horizontal: 40), onTap: () => _go(0, -1)),
            const SizedBox(width: 16),
            KButton.primary(label: l10n.kitchenExitMode, height: 88, fontSize: 24, padding: const EdgeInsets.symmetric(horizontal: 44), onTap: _s.end),
          ],
        ),
      ],
    ),
  );

  Widget _voiceHint() {
    // The wake phrase is drawn bold: split the sentence around it.
    final hint = l10n.kitchenVoiceHint('\u0000').split('\u0000');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: KColors.card, shape: BoxShape.circle),
            child: KIcon(_micIcon, size: 26, color: KColors.accentFg),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: hint.first),
                  TextSpan(
                    text: l10n.kitchenVoiceHintCommand,
                    style: TextStyle(fontWeight: FontWeight.w700, color: KColors.ink),
                  ),
                  if (hint.length > 1) TextSpan(text: hint[1]),
                ],
              ),
              style: KText.s(20, color: KColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nav(KitchenRecipe r) {
    final last = _i == r.steps.length - 1;
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 10,
            child: Opacity(
              opacity: _i > 0 ? 1 : 0.4,
              child: KPress(
                onTap: _i > 0 ? () => _go(_i - 1, -1) : null,
                child: Container(
                  decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(48)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      KIcon(_prevIcon, size: 40, stroke: 2.4),
                      const SizedBox(width: 14),
                      Text(l10n.commonPrevious, style: KText.s(30, weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 16,
            child: KPress(
              onTap: () => _go(_i + 1, 1),
              child: Container(
                decoration: BoxDecoration(color: KColors.accent, borderRadius: BorderRadius.circular(48)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      last ? l10n.kitchenFinish : l10n.commonNext,
                      style: KText.s(32, weight: FontWeight.w600, color: KColors.onAccent),
                    ),
                    const SizedBox(width: 14),
                    KIcon(last ? KIcons.check : _nextIcon, size: 40, stroke: 2.4, color: KColors.onAccent),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _allSteps(KitchenRecipe r) => Positioned.fill(
    child: Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _list = false),
            child: ColoredBox(color: KColors.scrim),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 1900),
            padding: const EdgeInsets.fromLTRB(48, 36, 48, 56),
            decoration: BoxDecoration(
              color: KColors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l10n.kitchenAllSteps, style: KText.d(40))),
                    KCircleButton(icon: KIcons.close, size: 64, bg: KColors.page, border: null, onTap: () => setState(() => _list = false)),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: r.steps.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, k) {
                      final cur = k == _i, done = k < _i;
                      return KPress(
                        onTap: () => _go(k, k < _i ? -1 : 1),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 84),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(color: cur ? KColors.accentSoft : Colors.transparent, borderRadius: BorderRadius.circular(24)),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: done || cur ? KColors.accent : KColors.page, shape: BoxShape.circle),
                                child: Text(
                                  '${k + 1}',
                                  style: KText.d(22, weight: FontWeight.w600, color: done || cur ? KColors.onAccent : KColors.ink),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Text(
                                  r.steps[k],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: KText.s(21, height: 1.4, color: done ? KColors.faint : KColors.ink),
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
            ),
          ),
        ),
      ],
    ),
  );
}

String _people(int n) => l10n.kitchenPeople(n);

/// The minimised recipe (design: Bolhas): its picture, the nearest timer
/// (or the step) under it; tap to go back. Drawn in the kiosk shell, over
/// the pages.
class KitchenBubbleLayer extends StatelessWidget {
  const KitchenBubbleLayer({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: KitchenSession.instance,
    builder: (context, _) {
      final s = KitchenSession.instance;
      if (!s.active || !s.minimized) return const SizedBox.shrink();
      final t = s.soonest;
      final ended = t?.state == _Timer.ended;
      final face = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [KColors.accentFg, KColors.accent]),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (s.recipe.image case final img?) Image.network(img, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
            if (s.recipe.image == null) const Center(child: KIcon(_chefIcon, size: 44, color: Colors.white)),
          ],
        ),
      );
      final below = t == null
          ? KBubbleLabel(l10n.kitchenBubbleStep(s.i + 1, s.recipe.steps.length))
          : _Blinking(
              enabled: ended,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: ended ? KColors.orange : KColors.accent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    ended ? l10n.kitchenTimerEnded : _clock(t.left),
                    style: KText.d(21, weight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            );
      return KBubble(
        slot: 0,
        face: face,
        below: below,
        semantics: t == null
            ? l10n.kitchenBubbleSemantics(s.recipe.title)
            : ended
            ? l10n.kitchenBubbleSemanticsTimerEnded(s.recipe.title)
            : l10n.kitchenBubbleSemanticsTimer(s.recipe.title, _clock(t.left)),
        onTap: () => openKitchenView(context),
      );
    },
  );
}

/// A step coming in from the side it was moved towards; one changed by voice
/// also gets a ring that fades out, so it's noticed from across the room.
class _Slide extends StatefulWidget {
  const _Slide({super.key, required this.dir, required this.flash, required this.child});

  final int dir;
  final bool flash;
  final Widget child;

  @override
  State<_Slide> createState() => _SlideState();
}

class _SlideState extends State<_Slide> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.flash ? 1200 : 400),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) {
      final slide = Curves.easeOutCubic.transform((_c.value * (widget.flash ? 1200 / 450 : 1)).clamp(0.0, 1.0));
      final ring = widget.flash ? (1 - Curves.easeOut.transform((_c.value / 0.7).clamp(0.0, 1.0))) : 0.0;
      return Opacity(
        opacity: slide,
        child: Transform.translate(
          offset: Offset(60 * widget.dir * (1 - slide), 0),
          child: DecoratedBox(
            position: DecorationPosition.background,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: ring > 0
                  ? [
                      BoxShadow(
                        color: KColors.accent.withValues(alpha: 0.55 * ring),
                        spreadRadius: 28 * (1 - ring),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      );
    },
    child: widget.child,
  );
}

/// The ended timer's box, pulsing.
class _Blinking extends StatelessWidget {
  const _Blinking({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: KBlink(enabled: enabled, period: const Duration(seconds: 1), child: child),
  );
}
