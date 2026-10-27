import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../widgets/on_screen_keyboard_controller.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';

/// Tap target with the design's press feedback (`button:active` scales to
/// .96). Everything tappable in the redesign goes through this.
///
/// A whole tappable card passes its corner [cardRadius] instead: it then
/// gets the style rules' card press — the `pressed` overlay and a .98
/// scale, 120 ms.
class KPress extends StatefulWidget {
  const KPress({super.key, required this.child, this.onTap, this.enabled = true, this.cardRadius});

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double? cardRadius;

  @override
  State<KPress> createState() => _KPressState();
}

class _KPressState extends State<KPress> {
  static const _press = Duration(milliseconds: 120);
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onTap != null;
    final card = widget.cardRadius;
    var child = widget.child;
    if (card != null) {
      child = AnimatedContainer(
        duration: _press,
        foregroundDecoration: BoxDecoration(color: _down ? KColors.pressed : KColors.pressed.withValues(alpha: 0), borderRadius: BorderRadius.circular(card)),
        child: child,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: active ? (_) => _set(true) : null,
      onTapUp: active ? (_) => _set(false) : null,
      onTapCancel: active ? () => _set(false) : null,
      onTap: active ? widget.onTap : null,
      child: AnimatedScale(scale: _down ? (card == null ? 0.96 : 0.98) : 1, duration: _press, child: child),
    );
  }
}

/// Pill button — "Hoje", "Guardar", "Novo evento" ... Height follows the
/// design's control scale: 72 primary, 64 standard, 56 choice, 52 compact.
class KButton extends StatelessWidget {
  const KButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.height = 64,
    Color? bg,
    Color? fg,
    Color? border = _token,
    this.fontSize = 22,
    this.weight = FontWeight.w600,
    this.iconSize = 24,
    this.iconStroke = 2.2,
    this.padding,
    this.iconAfter = false,
    this.gap = 10,
  }) : _bg = bg,
       _fg = fg,
       _border = border,
       _primary = false;

  /// Accent-filled primary action.
  const KButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.height = 64,
    this.fontSize = 22,
    this.iconSize = 28,
    this.padding,
    this.gap = 10,
    Color? bg,
    Color? fg,
  }) : _bg = bg,
       _fg = fg,
       _border = null,
       _primary = true,
       weight = FontWeight.w600,
       iconStroke = 2.2,
       iconAfter = false;

  final String label;
  final String? icon;
  final VoidCallback? onTap;
  final double height;
  final Color? _bg;
  final Color? _fg;
  final Color? _border;
  final bool _primary;
  final double fontSize;
  final FontWeight weight;

  /// Secondary buttons sit on a `tile` with a `track` outline; primary
  /// ones are an accent fill.
  Color get bg => _bg ?? (_primary ? KColors.accent : KColors.tile);
  Color get fg => _fg ?? (_primary ? KColors.onAccent : KColors.ink);
  Color? get border => _border == _token ? KColors.border : _border;
  final double iconSize;
  final double iconStroke;
  final EdgeInsets? padding;
  final bool iconAfter;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final iconW = icon == null ? null : KIcon(icon!, size: iconSize, color: fg, stroke: iconStroke);
    return KPress(
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding ?? EdgeInsets.fromLTRB(icon != null && !iconAfter ? 20 : 28, 0, icon != null && iconAfter ? 20 : 28, 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(height / 2),
          border: border == null ? null : Border.all(color: border!, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconW != null && !iconAfter) ...[iconW, SizedBox(width: gap)],
            Text(
              label,
              maxLines: 1,
              style: KText.s(fontSize, weight: weight, color: fg),
            ),
            if (iconW != null && iconAfter) ...[SizedBox(width: gap), iconW],
          ],
        ),
      ),
    );
  }
}

class KCircleButton extends StatelessWidget {
  const KCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 64,
    this.iconSize = 28,
    Color? bg,
    Color? fg,
    Color? border = _token,
    this.stroke = 2,
    this.shadow,
  }) : _bg = bg,
       _fg = fg,
       _border = border;

  final String icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? _bg;
  final Color? _fg;
  final Color? _border;
  Color get bg => _bg ?? KColors.tile;
  Color get fg => _fg ?? KColors.ink;
  Color? get border => _border == _token ? KColors.border : _border;
  final double stroke;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return KPress(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: border == null ? null : Border.all(color: border!, width: 1.5),
          boxShadow: shadow,
        ),
        child: KIcon(icon, size: iconSize, color: fg, stroke: stroke),
      ),
    );
  }
}

/// −/+ stepper button (60 px in modals, 52 in AC rows, 44 on Início).
class KStepButton extends StatelessWidget {
  const KStepButton({super.key, required this.plus, required this.onTap, this.size = 60, this.enabled = true});

  final bool plus;
  final VoidCallback? onTap;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) => KCircleButton(
    icon: plus ? KIcons.plus : KIcons.minus,
    size: size,
    iconSize: size * 0.43,
    stroke: 2.2,
    fg: enabled ? KColors.ink : KColors.disabledFg,
    onTap: enabled ? onTap : null,
  );
}

/// Toggle switch: 68×40 in modals, 52×30 in compact rows.
class KSwitch extends StatelessWidget {
  const KSwitch({super.key, required this.on, this.small = false, Color? onColor}) : _onColor = onColor;

  final bool on;
  final bool small;
  final Color? _onColor;
  Color get onColor => _onColor ?? KColors.accent;

  @override
  Widget build(BuildContext context) {
    final w = small ? 52.0 : 68.0, h = small ? 30.0 : 40.0, pad = small ? 3.0 : 4.0;
    final knob = h - pad * 2;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: w,
      height: h,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(color: on ? onColor : KColors.ring, borderRadius: BorderRadius.circular(h / 2)),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 260),
        curve: kEase,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: knob,
          height: knob,
          decoration: BoxDecoration(
            color: KColors.onAccent,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: KColors.dark.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 1))],
          ),
        ),
      ),
    );
  }
}

class KAvatar extends StatelessWidget {
  const KAvatar({super.key, required this.initial, required this.color, this.size = 48, this.fontSize = 20, this.flag = false});

  final String initial;
  final Color color;
  final double size;
  final double fontSize;
  final bool flag;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: flag
          ? KIcon(KIcons.flag, size: size * 0.5, color: KColors.onAccent, stroke: 2.2)
          : Text(
              initial,
              style: KText.s(fontSize, weight: FontWeight.w700, color: KColors.onAccent),
            ),
    );
  }
}

/// Option chip (56 px, pill) — accent when selected.
class KChip extends StatelessWidget {
  const KChip({super.key, required this.label, required this.on, this.onTap, this.height = 56, this.fontSize = 22, this.padX = 28, Color? offBg, Color? onBg})
    : _offBg = offBg,
      _onBg = onBg;

  final String label;
  final bool on;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final double padX;
  final Color? _offBg;
  final Color? _onBg;
  Color get offBg => _offBg ?? KColors.chip;
  Color get onBg => _onBg ?? KColors.accent;

  @override
  Widget build(BuildContext context) {
    return KPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        padding: EdgeInsets.symmetric(horizontal: padX),
        decoration: BoxDecoration(color: on ? onBg : offBg, borderRadius: BorderRadius.circular(height / 2)),
        // A min-size Row (not `alignment`) so the chip hugs its label
        // instead of stretching to the width a Wrap offers it.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              style: KText.s(fontSize, weight: FontWeight.w600, color: on ? KColors.onAccent : KColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// "TÍTULO", "NOTAS (opcional)" — the small caps label above a field.
class KFieldLabel extends StatelessWidget {
  const KFieldLabel(this.text, {super.key, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        children: [
          if (optional)
            TextSpan(
              text: ' ${l10n.uiOptionalSuffix}',
              style: KText.s(15, weight: FontWeight.w500, color: KColors.muted),
            ),
        ],
      ),
      style: KText.label,
    );
  }
}

class KProgress extends StatelessWidget {
  const KProgress({super.key, required this.value, this.height = 10, Color? track, Color? fill, this.gradient}) : _track = track, _fill = fill;

  final double value;
  final double height;
  final Color? _track;
  final Color? _fill;
  Color get track => _track ?? KColors.border;
  Color get fill => _fill ?? KColors.accent;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: track,
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 400),
          curve: kEase,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(color: gradient == null ? fill : null, gradient: gradient, borderRadius: BorderRadius.circular(height / 2)),
          ),
        ),
      ),
    );
  }
}

/// A rounded rectangle with a dashed outline ("+ Planear", "Nova lista").
class KDashedBox extends StatelessWidget {
  const KDashedBox({super.key, required this.child, this.radius = 22, Color? color, this.width = 2}) : _color = color;

  final Widget child;
  final double radius;
  final Color? _color;
  Color get color => _color ?? KColors.dashed;
  final double width;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DashedPainter(radius, color, width), child: child);
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.radius, this.color, this.width);

  final double radius;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(width / 2);
    // Each dash as a straight segment, all in one call: stroking dashed
    // paths made a page of empty slots (Refeições) slow to draw on the
    // Pi's GPU. On the corners a 6 px chord is indistinguishable from the arc.
    final points = <Offset>[];
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (double d = 0; d < metric.length; d += 12) {
        final a = metric.getTangentForOffset(d), b = metric.getTangentForOffset(math.min(d + 6, metric.length));
        if (a != null && b != null) points.addAll([a.position, b.position]);
      }
    }
    canvas.drawPoints(PointMode.lines, points, paint);
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.color != color || old.radius != radius || old.width != width;
}

/// The redesign's text field: a soft rounded box, accent ring while
/// focused, wired to the on-screen keyboard. [options] carries the
/// keyboard's suggestion row and its done key's label/action for this
/// field.
class KTextField extends StatefulWidget {
  const KTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hint,
    this.height = 84,
    this.fontSize = 28,
    this.options = const KeyboardOptions(),
    this.leading,
    this.trailing,
    this.maxLines = 1,
    Color? background,
    this.autofocus = false,
  }) : _background = background;

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hint;
  final double height;
  final double fontSize;
  final KeyboardOptions options;
  final Widget? leading;
  final Widget? trailing;
  final int maxLines;
  final Color? _background;
  Color get background => _background ?? KColors.sub;
  final bool autofocus;

  @override
  State<KTextField> createState() => _KTextFieldState();
}

class _KTextFieldState extends State<KTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  late final bool _ownsFocus = widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  void _onFocus() {
    if (_focus.hasFocus) {
      OnScreenKeyboardController.instance.attach(widget.controller, options: widget.options);
    } else {
      OnScreenKeyboardController.instance.detach(widget.controller);
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(KTextField old) {
    super.didUpdateWidget(old);
    // Options close over the form's latest state (e.g. which field comes
    // next), so refresh them while this field still has the keyboard.
    if (_focus.hasFocus) OnScreenKeyboardController.instance.options = widget.options;
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    OnScreenKeyboardController.instance.detach(widget.controller);
    if (_ownsFocus) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multi = widget.maxLines > 1;
    // Its own layer: the focus border's fade (as a modal opens with the
    // field focused) would otherwise redraw the whole modal every frame.
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: multi ? null : widget.height,
        constraints: multi ? BoxConstraints(minHeight: widget.height) : null,
        padding: EdgeInsets.fromLTRB(widget.leading != null ? 28 : (multi ? 24 : 28), multi ? 18 : 0, widget.trailing != null ? 12 : 28, multi ? 18 : 0),
        decoration: BoxDecoration(
          color: widget.background,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _focus.hasFocus ? KColors.accent : Colors.transparent, width: 3),
        ),
        child: Row(
          crossAxisAlignment: multi ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 16)],
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                maxLines: widget.maxLines,
                minLines: multi ? widget.maxLines : 1,
                // flutter-pi has no IME; the on-screen keyboard is ours.
                keyboardType: TextInputType.none,
                cursorColor: KColors.accentFg,
                cursorWidth: 3,
                style: KText.s(widget.fontSize, weight: multi ? FontWeight.w400 : FontWeight.w500, height: multi ? 1.4 : null),
                decoration: InputDecoration.collapsed(
                  hintText: widget.hint,
                  hintStyle: KText.s(widget.fontSize, weight: multi ? FontWeight.w400 : FontWeight.w500, color: KColors.faint),
                ),
              ),
            ),
            if (widget.trailing != null) ...[const SizedBox(width: 12), widget.trailing!],
          ],
        ),
      ),
    );
  }
}

/// Whether the on-screen keyboard is docked at the bottom — modals rise to
/// make room. A floating keyboard leaves them where they are.
class KeyboardVisibility extends StatelessWidget {
  const KeyboardVisibility({super.key, required this.builder});

  final Widget Function(BuildContext context, bool open) builder;

  @override
  Widget build(BuildContext context) {
    final kb = OnScreenKeyboardController.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([kb.active, kb.floating]),
      builder: (context, _) => builder(context, kb.active.value != null && !kb.floating.value),
    );
  }
}

/// The design's `dcBlink` — a soft pulse for "live" indicators (the
/// charging bolt, "A aquecer", "AO VIVO").
class KBlink extends StatefulWidget {
  const KBlink({super.key, required this.child, this.enabled = true, this.period = const Duration(milliseconds: 1600)});

  final Widget child;
  final bool enabled;
  final Duration period;

  @override
  State<KBlink> createState() => _KBlinkState();
}

class _KBlinkState extends State<KBlink> with SingleTickerProviderStateMixin {
  // Created up front: a lazy one would first be created in dispose() by a
  // blink that was never enabled, after its context is already gone.
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.period ~/ 2);
    if (widget.enabled) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(KBlink old) {
    super.didUpdateWidget(old);
    if (widget.enabled == old.enabled) return;
    if (widget.enabled) {
      _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Its own layer, so the pulse doesn't repaint the page around it.
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: widget.enabled
        ? FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.3).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
            child: widget.child,
          )
        : widget.child,
  );
}

/// White section card (radius 36, padding 32).
class KSection extends StatelessWidget {
  const KSection({super.key, required this.child, this.padding = const EdgeInsets.all(32)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(36)),
    child: child,
  );
}

/// Round tick box (tasks, list items).
class KCheckCircle extends StatelessWidget {
  const KCheckCircle({super.key, required this.done, this.size = 40, Color? color}) : _color = color;

  final bool done;
  final double size;
  final Color? _color;
  Color get color => _color ?? KColors.accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? color : KColors.tile,
        border: Border.all(color: done ? color : KColors.ring, width: size > 44 ? 3 : 2.5),
      ),
      child: done
          ? Center(
              child: KIcon(KIcons.check, size: size * 0.6, color: KColors.onAccent, stroke: 2.8),
            )
          : null,
    );
  }
}

/// The design's `dcPageIn`: a section rises 28 px while fading in. On a
/// page with several sections each gets the next [index], so they arrive
/// one after another, top first.
class KFadeUp extends StatefulWidget {
  const KFadeUp({super.key, this.index = 0, required this.child});

  /// Position from the top; each step waits [step] longer.
  final int index;
  final Widget child;

  static const _base = Duration(milliseconds: 50);
  static const step = Duration(milliseconds: 100);
  static const _duration = Duration(milliseconds: 450);

  @override
  State<KFadeUp> createState() => _KFadeUpState();
}

class _KFadeUpState extends State<KFadeUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: KFadeUp._duration);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: kEase);
  Timer? _start;

  @override
  void initState() {
    super.initState();
    _start = Timer(KFadeUp._base + KFadeUp.step * widget.index, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _start?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 28 * (1 - _t.value)), child: child),
      ),
      // Its own layer: the rise only moves the section, rather than
      // redrawing the whole page every frame.
      child: RepaintBoundary(child: widget.child),
    );
  }
}

// ─── Modals ────────────────────────────────────────────────────────────

/// Opens a redesign modal: a dimmed backdrop and a card that rises in
/// (`dcModalIn`) and drops out (`dcModalOut`). [builder] returns a
/// [KModal].
/// Closes the modal [context] is in — and only that one. A modal that
/// reacts to an event (the assistant opening something) may no longer be on
/// top by then, and a plain pop would close whatever replaced it.
void closeOwnRoute(BuildContext context) {
  final route = ModalRoute.of(context);
  if (route == null || !route.isActive) return;
  final nav = Navigator.of(context);
  if (route.isCurrent) {
    nav.pop();
  } else {
    nav.removeRoute(route);
  }
}

Future<T?> showKModal<T>(BuildContext context, WidgetBuilder builder) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, _) => builder(context),
      transitionsBuilder: (_, _, _, child) => child,
    ),
  );
}

/// The modal frame: backdrop, an 880-wide card whose top sits at 340 px
/// (level with Início's Casa section) and rises to [keyboardTop] while the
/// keyboard is up. Content taller than the space left scrolls.
class KModal extends StatelessWidget {
  const KModal({
    super.key,
    required this.child,
    this.width = 880,
    this.top = 340,
    this.keyboardTop = 120,
    Color? background,
    Color? scrim,
    this.dismissible = true,
    this.padding = const EdgeInsets.all(36),
    BoxShadow? shadow,
    this.onDismiss,
  }) : _background = background,
       _scrim = scrim,
       _shadow = shadow;

  final Widget child;
  final double width;
  final double top;
  final double keyboardTop;
  final Color? _background;
  final Color? _scrim;
  final bool dismissible;
  final EdgeInsets padding;
  final BoxShadow? _shadow;

  /// A modal is a `surface`; in the dark it floats on light, not shadow,
  /// so it also gets the 1 px outline.
  Color get background => _background ?? KColors.card;
  Color get scrim => _scrim ?? KColors.scrim;
  List<BoxShadow> get shadow => [
    if (KColors.isDark) const BoxShadow(color: Color(0x0FFFFFFF), spreadRadius: 1),
    _shadow ?? BoxShadow(color: KColors.isDark ? const Color(0x80000000) : const Color(0x4D17191C), blurRadius: 80, offset: const Offset(0, 30)),
  ];
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final anim = route?.animation ?? const AlwaysStoppedAnimation(1.0);
    void dismiss() {
      if (!dismissible) return;
      OnScreenKeyboardController.instance.close();
      if (onDismiss != null) {
        onDismiss!();
      } else {
        Navigator.of(context).maybePop();
      }
    }

    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final reversing = anim.status == AnimationStatus.reverse;
        final t = reversing ? Curves.easeIn.transform(anim.value) : kEase.transform(anim.value);
        final fade = Curves.ease.transform(anim.value);
        final dy = reversing ? 40 * (1 - t) : 56 * (1 - t);
        return Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: fade,
                child: ColoredBox(color: scrim),
              ),
            ),
            // Fade and rise only, no scale: a moving layer is reused from
            // the Pi's raster cache, a scaling one is redrawn every frame.
            Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(offset: Offset(0, dy), child: child),
            ),
          ],
        );
      },
      child: KeyboardVisibility(
        builder: (context, kb) => LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: GestureDetector(
              // The scroll view covers the whole screen, so the "tap the
              // backdrop to close" target has to live inside it.
              behavior: HitTestBehavior.opaque,
              onTap: dismiss,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 450),
                  curve: kEase,
                  padding: EdgeInsets.only(top: kb ? keyboardTop : top, bottom: kb ? 680 : 64),
                  child: Align(
                    alignment: Alignment.topCenter,
                    // Its own layer: the open/close and the rise over the
                    // keyboard only move the card, rather than repainting
                    // it (and its blurred shadow) every frame.
                    child: RepaintBoundary(
                      child: GestureDetector(
                        // Swallow taps on the card so they don't reach the backdrop.
                        onTap: () {},
                        child: Container(
                          width: width,
                          padding: padding,
                          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(36), boxShadow: shadow),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Title row shared by every modal: title (+ optional subtitle) and the
/// round close button.
class KModalHeader extends StatelessWidget {
  const KModalHeader({super.key, required this.title, this.subtitle, this.subtitleChild, this.trailing, Color? closeBg, this.dark = false})
    : _closeBg = closeBg;

  final String title;
  final String? subtitle;

  /// In place of [subtitle], when parts of it do something (a reading that
  /// opens its history). Styled like [subtitle].
  final Widget? subtitleChild;
  final Widget? trailing;
  final Color? _closeBg;
  Color get closeBg => _closeBg ?? KColors.chip;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    // [dark]: over the camera's fixed dark surface, the same in both themes.
    final fg = dark ? KColors.onAccent : KColors.ink;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: KText.modalTitle.copyWith(color: fg)),
              if (subtitleChild != null) ...[
                const SizedBox(height: 4),
                DefaultTextStyle(
                  style: KText.s(22, color: dark ? KColors.cameraText : KColors.muted),
                  child: subtitleChild!,
                ),
              ] else if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: KText.s(22, color: dark ? KColors.cameraText : KColors.muted)),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[trailing!, const SizedBox(width: 12)],
        KCircleButton(
          icon: KIcons.close,
          size: 64,
          iconSize: 30,
          stroke: 2.2,
          bg: closeBg,
          fg: fg,
          border: null,
          onTap: () {
            OnScreenKeyboardController.instance.close();
            Navigator.of(context).maybePop();
          },
        ),
      ],
    );
  }
}

/// The modal footer: an optional destructive action on the left, Cancel +
/// the primary action on the right, above a hairline.
class KModalFooter extends StatelessWidget {
  const KModalFooter({
    super.key,
    required this.saveLabel,
    required this.canSave,
    required this.onSave,
    this.deleteLabel,
    this.onDelete,
    this.hint,
    this.busy = false,
  });

  final String saveLabel;
  final bool canSave;
  final VoidCallback onSave;
  final String? deleteLabel;
  final VoidCallback? onDelete;
  final String? hint;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 28),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: KColors.divider, width: 1.5)),
      ),
      child: Row(
        children: [
          if (onDelete != null)
            KButton(
              label: deleteLabel ?? l10n.commonDelete,
              icon: KIcons.trash,
              iconSize: 26,
              iconStroke: 2,
              height: 72,
              bg: KColors.redTint,
              fg: KColors.redInk,
              border: null,
              onTap: onDelete,
            )
          else if (hint != null)
            Expanded(
              child: Text(hint!, style: KText.s(20, color: KColors.muted)),
            ),
          if (onDelete != null || hint == null) const Spacer(),
          const SizedBox(width: 14),
          KButton(
            label: l10n.commonCancel,
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            onTap: () {
              OnScreenKeyboardController.instance.close();
              Navigator.of(context).maybePop();
            },
          ),
          const SizedBox(width: 14),
          KButton(
            label: busy ? l10n.uiSaving : saveLabel,
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 44),
            bg: canSave ? KColors.accent : KColors.border,
            fg: canSave ? KColors.onAccent : KColors.muted,
            border: null,
            onTap: canSave && !busy ? onSave : null,
          ),
        ],
      ),
    );
  }
}

// ─── Toast ─────────────────────────────────────────────────────────────

class KToastData {
  const KToastData(this.text, {this.actionLabel = 'OK', this.onAction, this.error = false});

  final String text;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool error;
}

/// The dark confirmation pill above the nav bar ("Evento criado: …").
/// Shown by the shell; anything can raise one.
/// Marks "the theme's default" for a nullable colour parameter where an
/// explicit `null` already means "none".
const _token = Color(0x00000001);

abstract final class KToast {
  static final current = ValueNotifier<KToastData?>(null);
  static Timer? _timer;

  static void show(String text, {String actionLabel = 'OK', VoidCallback? onAction, bool error = false}) {
    _timer?.cancel();
    current.value = KToastData(text, actionLabel: actionLabel, onAction: onAction, error: error);
    _timer = Timer(const Duration(seconds: 6), hide);
  }

  static void error(Object e) => show(l10n.uiActionFailed(_friendly(e)), error: true);

  static String _friendly(Object e) {
    final s = e.toString();
    final i = s.indexOf(': ');
    return i >= 0 ? s.substring(i + 2) : s;
  }

  static void hide() {
    _timer?.cancel();
    current.value = null;
  }
}
