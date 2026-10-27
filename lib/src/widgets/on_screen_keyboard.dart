import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../kiosk/theme/kiosk_icons.dart';
import '../kiosk/theme/kiosk_tokens.dart';
import '../l10n/l10n.dart';
import 'on_screen_keyboard_controller.dart';

/// Height of the keyboard panel in design pixels (the design's "Teclado"
/// board: 96 px keys, a 68 px suggestion row, 600 px in all).
const kKeyboardHeight = 600.0;

/// The floating panel (the design's "Teclado a flutuar"): about 46 % of the
/// width with 64 px keys, its height for the margin it keeps from the edges.
const _floatWidth = 660.0;
const _floatHeight = 426.0;

/// Mounted once at the app root (see `app.dart`): shows the on-screen
/// keyboard docked to the bottom of the screen whenever
/// [OnScreenKeyboardController] has an attached field, on top of [child].
///
/// Also reports the keyboard's own height to [child] as
/// `MediaQuery.viewInsets.bottom` while it's showing — the same signal a
/// real system keyboard sends. This app's keyboard is just an ordinary
/// overlay widget, not an IME, so Flutter has no idea it's covering
/// anything unless told: without this, every `Scaffold` behind it (every
/// settings page) had no reason to shrink/scroll out of its way, and
/// `TextField`'s own built-in "scroll the focused field above the keyboard"
/// behavior — which keys off this exact value — never had anything to
/// react to either.
class OnScreenKeyboardHost extends StatefulWidget {
  const OnScreenKeyboardHost({super.key, required this.child});

  final Widget child;

  @override
  State<OnScreenKeyboardHost> createState() => _OnScreenKeyboardHostState();
}

class _OnScreenKeyboardHostState extends State<OnScreenKeyboardHost> with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    reverseDuration: const Duration(milliseconds: 220),
  );

  /// The field the panel is (or was, while sliding out) typing into — kept
  /// past detach so the exit animation still has keys to draw.
  TextEditingController? _shown;

  OnScreenKeyboardController get _kb => OnScreenKeyboardController.instance;

  bool _dragging = false;

  /// Where the drag began (finger, in canvas pixels) and where the panel
  /// was then: the panel follows the finger's whole travel, not summed
  /// per-event deltas, which fell behind when several arrived per frame.
  Offset? _dragFrom;
  Offset _dragAt = Offset.zero;

  /// Set when the panel switches between docked and floating, so only that
  /// plays the settle animation — not every keyboard opening.
  bool _modeSwitch = false;

  @override
  void initState() {
    super.initState();
    _kb.active.addListener(_onActiveChanged);
    _kb.floating.addListener(_onFloatingChanged);
    _kb.loadPrefs();
    _onActiveChanged();
  }

  @override
  void dispose() {
    _kb.active.removeListener(_onActiveChanged);
    _kb.floating.removeListener(_onFloatingChanged);
    _slide.dispose();
    super.dispose();
  }

  void _onFloatingChanged() {
    if (mounted) setState(() => _modeSwitch = true);
  }

  Offset _local(Offset global) => (context.findRenderObject() as RenderBox).globalToLocal(global);

  /// Kept inside the screen with a 16 px margin.
  static Offset _clamp(Offset at) => Offset(at.dx.clamp(16, 1440 - _floatWidth - 16), at.dy.clamp(16, 2560 - _floatHeight - 16));

  void _onActiveChanged() {
    final next = OnScreenKeyboardController.instance.active.value;
    if (next != null) {
      setState(() {
        if (_shown == null) _modeSwitch = false;
        _shown = next;
      });
      _slide.forward();
    } else {
      setState(() {});
      _slide.reverse().whenComplete(() {
        if (mounted && OnScreenKeyboardController.instance.active.value == null) setState(() => _shown = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final floating = _kb.floating.value;
    // A floating keyboard covers nothing in particular, so nothing moves.
    final showing = _kb.active.value != null && !floating;
    final inset = showing ? kKeyboardHeight : 0.0;
    return Stack(
      children: [
        MediaQuery(
          data: mediaQuery.copyWith(
            viewInsets: mediaQuery.viewInsets.copyWith(bottom: inset > mediaQuery.viewInsets.bottom ? inset : mediaQuery.viewInsets.bottom),
          ),
          child: widget.child,
        ),
        if (_shown != null && !floating)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _slide, curve: kEase, reverseCurve: Curves.easeIn)),
              // Its own layer: the slide only moves the keyboard, rather
              // than redrawing every key each frame (measured on the Pi:
              // half the dropped frames opening a modal with a text field).
              child: _ModeIn(
                key: const ValueKey('docked'),
                floating: false,
                animate: _modeSwitch,
                child: RepaintBoundary(
                  child: KioskKeyboard(key: ValueKey(_shown), controller: _shown!, onFloat: () => _kb.setFloating(true)),
                ),
              ),
            ),
          ),
        if (_shown != null && floating) _floatingPanel(),
      ],
    );
  }

  Widget _floatingPanel() {
    final at = _clamp(_kb.floatAt);
    return Positioned(
      left: at.dx,
      bottom: at.dy,
      width: _floatWidth,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, child) {
          final t = _slide.status == AnimationStatus.reverse ? Curves.easeIn.transform(_slide.value) : kEase.transform(_slide.value);
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
          );
        },
        child: _ModeIn(
          key: const ValueKey('floating'),
          floating: true,
          animate: _modeSwitch,
          child: RepaintBoundary(
            child: KioskKeyboard(
              key: ValueKey(_shown),
              controller: _shown!,
              floating: true,
              dragging: _dragging,
              onDock: () => _kb.setFloating(false),
              onDragStart: (global) => setState(() {
                _dragging = true;
                _dragFrom = _local(global);
                _dragAt = at;
              }),
              onDrag: (global) {
                final from = _dragFrom;
                if (from == null) return;
                final d = _local(global) - from;
                // Up the screen is a bigger `bottom`.
                setState(() => _kb.floatAt = _clamp(Offset(_dragAt.dx + d.dx, _dragAt.dy - d.dy)));
              },
              onDragEnd: () {
                setState(() {
                  _dragging = false;
                  _dragFrom = null;
                });
                _kb.savePrefs();
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The panel settling in when it opens or switches between docked and
/// floating (the design's kbFixIn / kbFloatIn).
class _ModeIn extends StatelessWidget {
  const _ModeIn({super.key, required this.floating, required this.animate, required this.child});

  final bool floating;

  /// Only on a switch between docked and floating; an ordinary opening
  /// already slides/fades in, and fading the whole docked panel on top of
  /// that made opening a modal with a text field stutter on the Pi.
  final bool animate;
  final Widget child;

  @override
  Widget build(BuildContext context) => !animate
      ? child
      : TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          curve: kEase,
          child: child,
          builder: (context, t, child) {
            final rise = floating ? 24 * (1 - t) : 40 * (1 - t);
            final opacity = floating ? t : 0.4 + 0.6 * t;
            final scale = floating ? 0.96 + 0.04 * t : 1.0;
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, rise),
                child: Transform.scale(scale: scale, child: child),
              ),
            );
          },
        );
}

enum _Layer { abc, num, sym }

/// The keyboard panel itself — the design's "Teclado" component, after the
/// iPhone's: a row of three suggestions (with "Flutuar" and "Fechar" when
/// docked), a Portuguese QWERTY whose accents live behind a held key (hold
/// "a" for á à â ã…, slide to one, let go), a touched key that darkens
/// (floating, a balloon shows it too), a shift that locks on a double tap, a backspace that repeats
/// while held, a double space that types ". ", and an accent "done" key
/// whose label/action the focused field chooses.
class KioskKeyboard extends StatefulWidget {
  const KioskKeyboard({
    super.key,
    required this.controller,
    this.floating = false,
    this.dragging = false,
    this.onFloat,
    this.onDock,
    this.onDragStart,
    this.onDrag,
    this.onDragEnd,
  });

  final TextEditingController controller;

  /// The smaller, draggable panel: a grip with "fix to the bottom" and
  /// "close" round buttons above the suggestions, 64 px keys.
  final bool floating;
  final bool dragging;
  final VoidCallback? onFloat;
  final VoidCallback? onDock;

  /// The finger's global position as the panel is dragged by its grip.
  final ValueChanged<Offset>? onDragStart;
  final ValueChanged<Offset>? onDrag;
  final VoidCallback? onDragEnd;

  @override
  State<KioskKeyboard> createState() => _KioskKeyboardState();
}

/// The panel's measures, docked (the wall screen) or floating (a phone).
class _Metrics {
  const _Metrics(this.floating);

  final bool floating;
  double get width => floating ? 660 : 1440;
  double get padX => floating ? 14 : 24;
  double get keyH => floating ? 64 : 96;
  double get keyGap => floating ? 7 : 12;
  double get rowGap => floating ? 8 : 12;
  double get keyR => floating ? 14 : 18;
  double get letter => floating ? 26 : 34;
  double get func => floating ? 18 : 24;
  double get icon => floating ? 30 : 40;
  double get sugH => floating ? 48 : 68;
  double get sugSize => floating ? 19 : 24;
  double get keyW => (width - 2 * padX - 9 * keyGap) / 10;
}

/// A key being touched: where it is in the panel, for the balloon.
typedef _Touch = ({String label, Rect rect});

/// Held long enough: the variants, and the one under the finger.
typedef _Variants = ({String base, List<String> options, int selected, Rect rect});

class _KioskKeyboardState extends State<KioskKeyboard> {
  final _panel = GlobalKey();
  _Layer _layer = _Layer.abc;

  /// 0 = off, 1 = next letter only, 2 = caps lock.
  int _shift = 0;

  /// A function key held down (it lights up), by id.
  String? _down;

  /// The balloon and the variants live on their own layer: touching a
  /// letter redraws them, not every key (a whole-panel repaint per touch
  /// costs a frame on the Pi).
  final _touch = ValueNotifier<_Touch?>(null);
  final _variants = ValueNotifier<_Variants?>(null);

  /// The character key under the finger: it alone takes the function-key
  /// tone while held (the balloon shows only when floating).
  final _held = ValueNotifier<String?>(null);
  String? _pressing;
  Timer? _hold;
  Timer? _repeatDelay;
  Timer? _repeat;
  DateTime _lastShift = DateTime(0);
  DateTime _lastSpace = DateTime(0);

  /// Accents and kin behind a held key, as on an iPhone set to Portuguese.
  static const _variantsOf = {
    'a': ['á', 'à', 'â', 'ã', 'ä', 'å', 'æ'],
    'e': ['é', 'è', 'ê', 'ë', 'ę', 'ē'],
    'i': ['í', 'ì', 'î', 'ï'],
    'o': ['ó', 'ò', 'ô', 'õ', 'ö', 'ø', 'œ'],
    'u': ['ú', 'ù', 'û', 'ü'],
    'c': ['ç', 'ć', 'č'],
    'n': ['ñ', 'ń'],
    's': ['ß', 'ś', 'š'],
    'y': ['ÿ'],
    'z': ['ž', 'ź', 'ż'],
    '-': ['–', '—', '·'],
    '.': ['…'],
    '?': ['¿'],
    '!': ['¡'],
    "'": ['’', '‘', '`'],
    '"': ['«', '»', '“', '”', '„'],
    '0': ['°'],
    '&': ['§'],
    r'$': ['€', '£', '¥', '¢'],
    '€': [r'$', '£', '¥'],
  };

  KeyboardOptions get _options => OnScreenKeyboardController.instance.options;
  _Metrics get _m => _Metrics(widget.floating);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _hold?.cancel();
    _stopRepeat();
    _touch.dispose();
    _variants.dispose();
    _held.dispose();
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  /// Auto-capitalise at the start of the field or a new sentence.
  bool get _capNext {
    if (!_options.capitalize || _layer != _Layer.abc) return false;
    final text = widget.controller.text;
    return text.isEmpty || RegExp(r'[.!?]\s$').hasMatch(text);
  }

  bool get _upper => _layer == _Layer.abc && (_shift > 0 || (_shift == 0 && _capNext));

  void _insert(String text) {
    final value = widget.controller.value;
    var selection = value.selection;
    if (!selection.isValid) selection = TextSelection.collapsed(offset: value.text.length);
    final newText = value.text.replaceRange(selection.start, selection.end, text);
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  void _backspace() {
    final value = widget.controller.value;
    var selection = value.selection;
    if (!selection.isValid) selection = TextSelection.collapsed(offset: value.text.length);
    if (selection.start != selection.end) {
      _insert('');
      return;
    }
    final start = selection.start;
    if (start <= 0) return;
    widget.controller.value = TextEditingValue(
      text: value.text.replaceRange(start - 1, start, ''),
      selection: TextSelection.collapsed(offset: start - 1),
    );
  }

  void _typed(String ch) {
    _insert(_upper && RegExp(r'[a-zà-ÿ]').hasMatch(ch) ? ch.toUpperCase() : ch);
    _lastSpace = DateTime(0);
    if (_shift == 1) setState(() => _shift = 0);
  }

  void _done() {
    final onDone = _options.onDone;
    if (onDone != null) {
      onDone();
    } else {
      OnScreenKeyboardController.instance.close();
    }
  }

  void _suggest(String s) {
    final onSuggest = _options.onSuggest;
    if (onSuggest != null) {
      onSuggest(s);
    } else {
      widget.controller.value = TextEditingValue(
        text: s,
        selection: TextSelection.collapsed(offset: s.length),
      );
    }
  }

  void _stopRepeat() {
    _repeatDelay?.cancel();
    _repeat?.cancel();
  }

  /// A key's rectangle in the panel.
  Rect? _rectOf(BuildContext key) {
    final panel = _panel.currentContext?.findRenderObject() as RenderBox?;
    final box = key.findRenderObject() as RenderBox?;
    if (panel == null || box == null) return null;
    final topLeft = panel.globalToLocal(box.localToGlobal(Offset.zero));
    return topLeft & box.size;
  }

  /// Where the variants pop up: from the key leftwards, kept inside.
  double _variantsLeft(Rect key, int n) {
    final w = n * key.width + 12;
    var left = key.left - 6;
    if (left + w > _m.width - 4) left = key.right + 6 - w;
    return math.max(4, left);
  }

  // ─── Character keys: balloon on touch, variants when held ───────────

  void _charDown(String ch, String label, BuildContext key) {
    final rect = _rectOf(key);
    if (rect == null) return;
    _pressing = ch;
    _held.value = ch;
    if (widget.floating) _touch.value = (label: label, rect: rect);
    _variants.value = null;
    _hold?.cancel();
    final options = _variantsOf[ch];
    if (options == null) return;
    _hold = Timer(const Duration(milliseconds: 380), () {
      if (!mounted || _pressing != ch) return;
      final up = _upper && RegExp('[a-z]').hasMatch(ch);
      _touch.value = null;
      _variants.value = (base: label, options: [for (final o in options) up ? o.toUpperCase() : o], selected: 0, rect: rect);
    });
  }

  void _charMove(PointerMoveEvent e) {
    final v = _variants.value;
    final panel = _panel.currentContext?.findRenderObject() as RenderBox?;
    if (v == null || panel == null) return;
    final x = panel.globalToLocal(e.position).dx;
    final selected = ((x - _variantsLeft(v.rect, v.options.length) - 6) / v.rect.width).floor().clamp(0, v.options.length - 1);
    if (selected != v.selected) _variants.value = (base: v.base, options: v.options, selected: selected, rect: v.rect);
  }

  void _charUp() {
    _hold?.cancel();
    final v = _variants.value;
    if (v != null) {
      _insert(v.options[v.selected]);
      _lastSpace = DateTime(0);
      if (_shift == 1) setState(() => _shift = 0);
    } else if (_pressing != null) {
      _typed(_pressing!);
    }
    _pressing = null;
    _held.value = null;
    _touch.value = null;
    _variants.value = null;
  }

  void _charCancel() {
    _hold?.cancel();
    _pressing = null;
    _held.value = null;
    _touch.value = null;
    _variants.value = null;
  }

  Widget _char(String ch, {double flex = 1, double marginRight = 0}) {
    final label = _upper && RegExp('[a-z]').hasMatch(ch) ? ch.toUpperCase() : ch;
    return _KeySlot(
      flex: flex,
      marginRight: marginRight,
      builder: (key) => Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _charDown(ch, label, key),
        onPointerMove: _charMove,
        onPointerUp: (_) => _charUp(),
        onPointerCancel: (_) => _charCancel(),
        child: ValueListenableBuilder<String?>(
          valueListenable: _held,
          builder: (context, held, child) => _keyFace(bg: held == ch ? KColors.keyboardFunc : KColors.keyboardKey, child: child!),
          child: Text(label, maxLines: 1, style: KText.s(_m.letter, weight: FontWeight.w500)),
        ),
      ),
    );
  }

  // ─── Function keys: light up while held, act when let go ────────────

  Widget _func(
    String id, {
    double flex = 1.45,
    double marginRight = 0,
    String? label,
    Widget? child,
    Color? bg,
    Color? fg,
    double? size,
    FontWeight weight = FontWeight.w600,
    VoidCallback? onDown,
    VoidCallback? onUp,
    VoidCallback? onCancel,
  }) {
    final held = _down == id;
    return _KeySlot(
      flex: flex,
      marginRight: marginRight,
      builder: (_) => Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          setState(() => _down = id);
          onDown?.call();
        },
        onPointerUp: (_) {
          setState(() => _down = null);
          onUp?.call();
        },
        onPointerCancel: (_) {
          setState(() => _down = null);
          onCancel?.call();
        },
        child: _keyFace(
          bg: bg ?? (held ? KColors.keyboardKey : KColors.keyboardFunc),
          child:
              child ??
              Text(
                label!,
                maxLines: 1,
                style: KText.s(size ?? _m.func, weight: weight, color: fg ?? KColors.ink),
              ),
        ),
      ),
    );
  }

  Widget _keyFace({required Color bg, required Widget child}) => AnimatedContainer(
    duration: const Duration(milliseconds: 80),
    height: _m.keyH,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(_m.keyR),
      boxShadow: [
        BoxShadow(
          color: KColors.dark.withValues(alpha: KColors.isDark ? 0.6 : 0.14),
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Widget get _shiftKey {
    final locked = _shift == 2;
    final on = _upper;
    final fg = locked ? KColors.keyboardKey : KColors.ink;
    return _func(
      'shift',
      marginRight: _m.keyGap * 0.8,
      bg: locked ? KColors.ink : (on ? KColors.keyboardKey : KColors.keyboardFunc),
      child: KIcon(
        '<path d="M12 4l8 8h-4.5v7h-7v-7H4z"/>${locked ? '<path d="M8 21.5h8" stroke-width="2.2"/>' : ''}',
        size: _m.icon,
        color: fg,
        stroke: 1.8,
        solid: on,
      ),
      onUp: () {
        final now = DateTime.now();
        // A double tap locks capitals.
        setState(() => _shift = now.difference(_lastShift) < const Duration(milliseconds: 350) ? 2 : (_shift == 0 ? 1 : 0));
        _lastShift = now;
      },
    );
  }

  Widget get _backKey {
    final held = _down == 'back';
    return _func(
      'back',
      child: KIcon(
        '<path d="M9 5h11a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H9l-6-7z" ${held ? 'fill="${_hex(KColors.ink)}"' : ''}/>'
        '<path d="M12 9.5l5 5M17 9.5l-5 5" ${held ? 'stroke="${_hex(KColors.keyboardKey)}"' : ''}/>',
        size: _m.icon,
        stroke: 1.8,
      ),
      onDown: () {
        _backspace();
        _lastSpace = DateTime(0);
        _stopRepeat();
        // Held, it keeps deleting.
        _repeatDelay = Timer(const Duration(milliseconds: 450), () => _repeat = Timer.periodic(const Duration(milliseconds: 80), (_) => _backspace()));
      },
      onUp: _stopRepeat,
      onCancel: _stopRepeat,
    );
  }

  static String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  Widget _layerKey(String label, _Layer to, {double marginRight = 0}) => _func(
    'layer-$label',
    flex: 1.3,
    marginRight: marginRight,
    label: label,
    onUp: () {
      _variants.value = null;
      setState(() => _layer = to);
    },
  );

  Widget get _spaceKey => _func(
    'space',
    flex: 5,
    label: l10n.keyboardSpace,
    bg: _down == 'space' ? KColors.keyboardFunc : KColors.keyboardKey,
    fg: KColors.muted,
    weight: FontWeight.w500,
    onUp: () {
      final now = DateTime.now();
      // Two spaces in a row: a full stop and a space.
      if (now.difference(_lastSpace) < const Duration(milliseconds: 450)) {
        _backspace();
        _insert('. ');
        _lastSpace = DateTime(0);
      } else {
        _insert(' ');
        _lastSpace = now;
      }
      if (_shift == 1) setState(() => _shift = 0);
    },
  );

  Widget get _doneKey => _func('done', flex: 2.4, label: _options.doneLabel, bg: KColors.accent, fg: KColors.onAccent, onUp: _done);

  List<Widget> _rows() {
    Widget row(List<Widget> keys, {double pad = 0}) => Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[if (i > 0) SizedBox(width: _m.keyGap), keys[i]],
        ],
      ),
    );
    List<Widget> chars(String s) => [for (final c in s.split('')) _char(c)];
    final bottom = row([_layerKey(_layer == _Layer.abc ? '123' : 'ABC', _layer == _Layer.abc ? _Layer.num : _Layer.abc), _spaceKey, _doneKey]);
    if (_layer == _Layer.abc) {
      return [
        row(chars('qwertyuiop')),
        row(chars('asdfghjkl'), pad: (_m.keyW + _m.keyGap) / 2),
        row([_shiftKey, ...chars('zxcvbn'), _char('m', marginRight: _m.keyGap * 0.8), _backKey]),
        bottom,
      ];
    }
    final punctuation = ['.', ',', '?', '!', "'"];
    return [
      if (_layer == _Layer.num) ...[
        row(chars('1234567890')),
        row([
          for (final c in ['-', '/', ':', ';', '(', ')', '€', '&', '@', '"']) _char(c),
        ]),
      ] else ...[
        row([
          for (final c in ['[', ']', '{', '}', '#', '%', '^', '*', '+', '=']) _char(c),
        ]),
        row([
          for (final c in ['_', r'\', '|', '~', '<', '>', r'$', '£', '¥', '•']) _char(c),
        ]),
      ],
      row([
        _layerKey(_layer == _Layer.num ? '#+=' : '123', _layer == _Layer.num ? _Layer.sym : _Layer.num, marginRight: _m.keyGap * 0.8),
        for (final (i, c) in punctuation.indexed) _char(c, flex: 1.4, marginRight: i == punctuation.length - 1 ? _m.keyGap * 0.8 : 0),
        _backKey,
      ]),
      bottom,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    final floating = widget.floating;
    final suggestions = (_options.suggestions?.call(widget.controller.text) ?? const <String>[]).take(3).toList();
    // Floating: a phone-sized panel with a grip to drag it by.
    final shadow = KColors.isDark || !floating
        ? [
            for (final s in KColors.shadowFloat)
              BoxShadow(color: s.color, blurRadius: s.blurRadius, spreadRadius: s.spreadRadius, offset: floating ? s.offset : -s.offset),
          ]
        : [
            BoxShadow(
              color: KColors.dark.withValues(alpha: widget.dragging ? 0.32 : 0.24),
              blurRadius: widget.dragging ? 70 : 50,
              offset: Offset(0, widget.dragging ? 30 : 18),
            ),
          ];
    final rows = _rows();
    // TextFieldTapRegion marks this panel as part of the focused field's own
    // tap region even though it's mounted at the app root, entirely outside
    // that field's widget subtree — the same mechanism a real IME's
    // predictive-text bar uses. Without it, a key tap here would register as
    // "tapped outside the field" and blur it, dropping the keystroke.
    return TextFieldTapRegion(
      child: Stack(
        key: _panel,
        clipBehavior: Clip.none,
        children: [
          RepaintBoundary(
            child: Container(
              height: floating ? null : kKeyboardHeight,
              padding: floating ? const EdgeInsets.fromLTRB(14, 14, 14, 18) : const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: KColors.keyboardBg,
                borderRadius: floating ? BorderRadius.circular(32) : const BorderRadius.vertical(top: Radius.circular(36)),
                // The theme's shadow-float (with the dark outline), cast upwards
                // when docked.
                boxShadow: shadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (floating) ...[_floatingBar(), SizedBox(height: m.rowGap)],
                  // Three fixed places, like the iPhone's predictive bar.
                  Padding(
                    padding: EdgeInsets.only(bottom: floating ? 0 : 2),
                    child: SizedBox(
                      height: m.sugH,
                      child: Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) SizedBox(width: m.keyGap),
                            Expanded(
                              child: i < suggestions.length
                                  ? _Pressable(
                                      onTap: () => _suggest(suggestions[i]),
                                      child: Container(
                                        height: m.sugH,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(color: KColors.keyboardSugg, borderRadius: BorderRadius.circular(m.sugH / 2)),
                                        child: Text(
                                          suggestions[i],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: KText.s(m.sugSize, weight: FontWeight.w500),
                                        ),
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                          if (!floating) ...[
                            const SizedBox(width: 12),
                            _pill(l10n.keyboardFloat, KIcons.keyboardFloat, iconFirst: true, size: 26, onTap: widget.onFloat),
                            const SizedBox(width: 12),
                            _pill(l10n.commonClose, KIcons.keyboard, size: 28, onTap: () => OnScreenKeyboardController.instance.close()),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: m.rowGap),
                  for (var i = 0; i < rows.length; i++) ...[if (i > 0) SizedBox(height: m.rowGap), rows[i]],
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ListenableBuilder(
                  listenable: Listenable.merge([_touch, _variants]),
                  builder: (context, _) =>
                      Stack(clipBehavior: Clip.none, children: [if (_touch.value case final t?) _balloon(t), if (_variants.value case final v?) _popup(v)]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The touched key, larger, above it (a key head and a stem down to it).
  Widget _balloon(_Touch t) {
    final m = _m;
    final w = t.rect.width * (widget.floating ? 1.45 : 1.35);
    final headH = t.rect.height * 1.05;
    final top = t.rect.top - headH - 4;
    final left = (t.rect.center.dx - w / 2).clamp(0.0, m.width - w);
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: t.rect.bottom - top,
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              left: t.rect.left - left,
              width: t.rect.width,
              top: headH - 2,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: KColors.keyboardKey,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(m.keyR)),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: headH,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: KColors.keyboardKey,
                  borderRadius: BorderRadius.circular(m.keyR * 1.3),
                  boxShadow: [BoxShadow(color: KColors.dark.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Text(t.label, style: KText.s((m.letter * 1.6).roundToDouble(), weight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The held key's variants; the one under the finger in accent.
  Widget _popup(_Variants v) {
    final m = _m;
    final optH = v.rect.height * 1.05;
    return Positioned(
      left: _variantsLeft(v.rect, v.options.length),
      top: v.rect.top - optH - 22,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: KColors.keyboardKey,
            borderRadius: BorderRadius.circular(m.keyR * 1.3),
            boxShadow: [BoxShadow(color: KColors.dark.withValues(alpha: 0.22), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, o) in v.options.indexed)
                Container(
                  width: v.rect.width,
                  height: optH,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: i == v.selected ? KColors.accent : Colors.transparent, borderRadius: BorderRadius.circular(m.keyR)),
                  child: Text(
                    o,
                    style: KText.s((m.letter * 1.25).roundToDouble(), weight: FontWeight.w500, color: i == v.selected ? KColors.onAccent : KColors.ink),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// A rounded control in the docked suggestion row.
  Widget _pill(String label, String icon, {required double size, bool iconFirst = false, VoidCallback? onTap}) {
    final ico = KIcon(icon, size: size, stroke: 2);
    final text = Text(label, style: KText.s(21, weight: FontWeight.w600));
    return _Pressable(
      onTap: onTap ?? () {},
      child: Container(
        height: 64,
        padding: iconFirst ? const EdgeInsets.fromLTRB(18, 0, 22, 0) : const EdgeInsets.fromLTRB(22, 0, 20, 0),
        decoration: BoxDecoration(color: KColors.keyboardCtl, borderRadius: BorderRadius.circular(32)),
        child: Row(children: iconFirst ? [ico, const SizedBox(width: 10), text] : [text, const SizedBox(width: 10), ico]),
      ),
    );
  }

  /// Floating: "fix to the bottom", the grip, "close".
  Widget _floatingBar() {
    Widget round(String icon, double size, double stroke, VoidCallback onTap) => _Pressable(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: KColors.keyboardCtl, shape: BoxShape.circle),
        child: Center(
          child: KIcon(icon, size: size, stroke: stroke),
        ),
      ),
    );
    return Row(
      children: [
        round(KIcons.keyboardDock, 26, 2, widget.onDock ?? () {}),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => widget.onDragStart?.call(d.globalPosition),
            onPanUpdate: (d) => widget.onDrag?.call(d.globalPosition),
            onPanEnd: (_) => widget.onDragEnd?.call(),
            onPanCancel: () => widget.onDragEnd?.call(),
            child: SizedBox(
              height: 52,
              child: Center(
                child: Container(
                  width: 88,
                  height: 8,
                  decoration: BoxDecoration(color: Color.lerp(KColors.keyboardFunc, KColors.ink, 0.25), borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ),
        ),
        round(KIcons.close, 24, 2.2, () => OnScreenKeyboardController.instance.close()),
      ],
    );
  }
}

/// One key's share of its row (flex, plus the extra gap some keys keep on
/// their right), handing its own context to [builder] so a touch can find
/// where the key is.
class _KeySlot extends StatelessWidget {
  const _KeySlot({required this.flex, required this.builder, this.marginRight = 0});

  final double flex;
  final double marginRight;
  final Widget Function(BuildContext key) builder;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: (flex * 10).round(),
    child: Padding(
      padding: EdgeInsets.only(right: marginRight),
      child: Builder(builder: builder),
    ),
  );
}

/// Key press feedback: the design's `button:active { transform: scale(.96) }`.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(scale: _down ? 0.96 : 1, duration: const Duration(milliseconds: 120), child: widget.child),
    );
  }
}
