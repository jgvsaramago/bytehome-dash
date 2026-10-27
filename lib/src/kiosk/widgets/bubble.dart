import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/kiosk_tokens.dart';

/// Where a minimised window's bubble rests at first: bottom right, above the
/// nav bar, one row per [slot] (0 the kitchen, 1 the browser) so two don't
/// overlap.
Offset bubbleHome(int slot) => Offset(1440 - 24 - 112, 2560 - 128 - 64 - 112 - slot * 150.0);

/// How far a bubble rests from the screen's edges; the bottom one also
/// clears the nav bar.
const _margin = 24.0;
const _navBar = 128.0;
const _w = 112.0, _h = 132.0;

/// A minimised window (design: Bolhas): a 112 px circle with a white ring
/// and a label or badge under it. Tap to bring the window back; drag it
/// anywhere, and on release it springs to the nearest of the four edges.
class KBubble extends StatefulWidget {
  const KBubble({super.key, required this.slot, required this.face, required this.below, required this.onTap, this.corner, this.semantics});

  final int slot;

  /// The circle's content (a picture, an icon).
  final Widget face;

  /// The label or badge across the bottom edge.
  final Widget below;

  /// A small badge on the top-right edge (the browser's site initial).
  final Widget? corner;
  final VoidCallback onTap;
  final String? semantics;

  @override
  State<KBubble> createState() => _KBubbleState();
}

class _KBubbleState extends State<KBubble> {
  late Offset _at = bubbleHome(widget.slot);
  Offset? _start;
  Offset _startAt = Offset.zero;
  bool _moved = false;
  bool _dragging = false;

  /// A finger has to travel this far before it's a drag, not a tap.
  static const _slop = 14.0;

  @override
  Widget build(BuildContext context) => AnimatedPositioned(
    duration: _dragging ? Duration.zero : const Duration(milliseconds: 650),
    curve: const ElasticOutCurve(0.7),
    left: _at.dx,
    top: _at.dy,
    width: _w,
    height: _h,
    child: Semantics(
      button: true,
      label: widget.semantics,
      // The pointer is followed directly and claimed at once: through the
      // gesture arena, a drag that another recognizer won came back as a
      // cancel and opened the window instead of moving the bubble.
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(EagerGestureRecognizer.new, (_) {})},
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            _start = e.position;
            _startAt = _at;
            _moved = false;
          },
          onPointerMove: (e) {
            final from = _start;
            if (from == null) return;
            final delta = e.position - from;
            if (!_moved && delta.distance < _slop) return;
            _moved = true;
            setState(() {
              _dragging = true;
              _at = Offset((_startAt.dx + delta.dx).clamp(0, 1440 - _w), (_startAt.dy + delta.dy).clamp(0, 2560 - _h));
            });
          },
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(tap: false),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (_, s, child) => Transform.scale(scale: s, child: child),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The white ring, then the face clipped round inside it.
                Container(
                  width: 112,
                  height: 112,
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Color(0x4717191C), blurRadius: 30, offset: Offset(0, 12))],
                  ),
                  child: ClipOval(
                    child: ColoredBox(
                      color: KColors.card,
                      child: SizedBox.expand(child: widget.face),
                    ),
                  ),
                ),
                Positioned(
                  left: -40,
                  right: -40,
                  top: 112 - 16,
                  child: Center(child: widget.below),
                ),
                if (widget.corner case final c?) Positioned(right: -6, top: -6, child: c),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  void _release({bool tap = true}) {
    if (_start == null) return;
    _start = null;
    if (!_moved) {
      if (tap) widget.onTap();
      return;
    }
    // To the nearest edge — left, right, top or bottom (above the nav bar) —
    // keeping the position along it.
    const left = _margin, right = 1440 - _margin - _w, top = _margin, bottom = 2560 - _navBar - _margin - _h;
    final x = _at.dx.clamp(left, right), y = _at.dy.clamp(top, bottom);
    final gaps = {'left': _at.dx - left, 'right': right - _at.dx, 'top': _at.dy - top, 'bottom': bottom - _at.dy};
    final nearest = gaps.entries.reduce((a, b) => a.value.abs() <= b.value.abs() ? a : b).key;
    setState(() {
      _dragging = false;
      _at = switch (nearest) {
        'left' => Offset(left, y),
        'right' => Offset(right, y),
        'top' => Offset(x, top),
        _ => Offset(x, bottom),
      };
    });
  }
}

/// The white pill under a bubble ("Passo 3/7", a site's name).
class KBubbleLabel extends StatelessWidget {
  const KBubbleLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    constraints: const BoxConstraints(maxWidth: 180),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      boxShadow: const [BoxShadow(color: Color(0x3317191C), blurRadius: 8, offset: Offset(0, 2))],
    ),
    child: Center(
      widthFactor: 1,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: KText.s(15, weight: FontWeight.w700, color: const Color(0xFF17191C)),
      ),
    ),
  );
}
