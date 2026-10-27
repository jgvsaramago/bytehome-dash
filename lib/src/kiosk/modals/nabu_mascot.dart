import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/kiosk_tokens.dart';

/// Where the conversation is, which is what Nabu's face shows.
enum NabuMood { listening, thinking, speaking, idle }

// The owl is artwork: its face, eyes and beak keep their colours in both
// themes; only the body follows the accent so it doesn't sink into the
// dark background.
const _face = Color(0xFFF6F1E6);
const _eye = Color(0xFFFFFFFF);
const _pupil = Color(0xFF17191C);
const _leaf = Color(0xFF7FB9A6);
const _cheek = Color(0x59F2A93B);
const _beakTop = Color(0xFFE8A33A);
const _beakBottom = Color(0xFFC77F1E);

Color get _body => KColors.accent;
Color get _belly => KColors.isDark ? const Color(0x996CB8A8) : const Color(0x992A6156);
Color get _ground => KColors.isDark ? const Color(0x59000000) : const Color(0x1417191C);

/// Nabu, the assistant's owl (the design's 300×300 SVG), drawn at whatever
/// size its parent gives it. Each mood has its own motion: listening tilts
/// the head with two rings rippling out, thinking breathes and looks
/// around, speaking bobs and moves the beak ([talking]), idle just
/// breathes. It blinks in all of them.
class NabuMascot extends StatefulWidget {
  const NabuMascot({super.key, required this.mood, this.talking = true});

  final NabuMood mood;

  /// Speaking moves the beak only when the reply is spoken out loud.
  final bool talking;

  @override
  State<NabuMascot> createState() => _NabuMascotState();
}

class _NabuMascotState extends State<NabuMascot> with SingleTickerProviderStateMixin {
  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) => _time.value = elapsed.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  // Its own layer, so the loop repaints only the owl, never the page.
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _NabuPainter(time: _time, mood: widget.mood, talking: widget.talking, body: _body, belly: _belly, ground: _ground, aura: KColors.accentFg),
      child: const SizedBox.expand(),
    ),
  );
}

double _ease(double x) => Curves.easeInOut.transform(x.clamp(0.0, 1.0));

/// 0 → 1 → 0 over [period], eased each way (`0%,100%{a} 50%{b}`).
double _bump(double t, double period) {
  final p = (t % period) / period;
  return p < 0.5 ? _ease(p * 2) : _ease((1 - p) * 2);
}

class _NabuPainter extends CustomPainter {
  _NabuPainter({
    required this.time,
    required this.mood,
    required this.talking,
    required this.body,
    required this.belly,
    required this.ground,
    required this.aura,
  }) : super(repaint: time);

  final ValueNotifier<double> time;
  final NabuMood mood;
  final bool talking;
  final Color body;
  final Color belly;
  final Color ground;
  final Color aura;

  static final _leafPath = Path()
    ..moveTo(150, 58)
    ..cubicTo(150, 40, 160, 26, 176, 22)
    ..cubicTo(176, 40, 166, 54, 150, 58)
    ..close();
  static final _stemPath = Path()
    ..moveTo(150, 58)
    ..cubicTo(150, 46, 156, 36, 164, 30);
  static final _earL = Path()
    ..moveTo(64, 108)
    ..lineTo(54, 46)
    ..lineTo(112, 82)
    ..close();
  static final _earR = Path()
    ..moveTo(236, 108)
    ..lineTo(246, 46)
    ..lineTo(188, 82)
    ..close();
  static final _beakLow = Path()
    ..moveTo(150, 214)
    ..lineTo(136, 194)
    ..lineTo(164, 194)
    ..close();
  static final _beakUp = Path()
    ..moveTo(150, 204)
    ..lineTo(132, 184)
    ..quadraticBezierTo(150, 172, 168, 184)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final w = size.shortestSide;
    final center = size.center(Offset.zero);

    // nabuAura: two rings, 2.2 s ease-out, the second 1.1 s behind.
    if (mood == NabuMood.listening) {
      for (final (delay, alpha) in const [(0.0, 0.28), (1.1, 0.22)]) {
        final p = Curves.easeOut.transform(((t - delay) % 2.2) / 2.2);
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = aura.withValues(alpha: alpha * 0.9 * (1 - p));
        canvas.drawCircle(center, w * 0.44 * (0.86 + 0.46 * p) - 1.5, ring);
      }
    }

    canvas.save();
    canvas.translate((size.width - w) / 2, (size.height - w) / 2);
    canvas.scale(w / 300);

    // Ground shadow; it squeezes as the head bobs while speaking.
    final squeeze = mood == NabuMood.speaking ? 1 - 0.12 * _bump(t, 1.1) : 1.0;
    canvas.save();
    canvas.translate(150, 282);
    canvas.scale(squeeze, 1);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 172, height: 20), Paint()..color = ground);
    canvas.restore();

    canvas.save();
    canvas.translate(150, 250);
    switch (mood) {
      case NabuMood.listening:
        canvas.rotate((-4 + 8 * _bump(t, 3.2)) * math.pi / 180);
      case NabuMood.thinking:
        canvas.translate(0, -4 * _bump(t, 2.4));
      case NabuMood.speaking:
        canvas.translate(0, -10 * _bump(t, 1.1));
      case NabuMood.idle:
        canvas.translate(0, -4 * _bump(t, 4));
    }
    canvas.translate(-150, -250);
    _head(canvas, t);
    canvas.restore();

    canvas.restore();
  }

  void _head(Canvas canvas, double t) {
    final fill = Paint()..color = body;
    canvas.drawPath(_leafPath, Paint()..color = _leaf);
    canvas.drawPath(
      _stemPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = body,
    );
    final earStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeJoin = StrokeJoin.round
      ..color = body;
    for (final ear in [_earL, _earR]) {
      canvas.drawPath(ear, fill);
      canvas.drawPath(ear, earStroke);
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(150, 158), width: 228, height: 208), fill);
    canvas.drawCircle(const Offset(150, 178), 70, Paint()..color = belly);

    final face = Paint()..color = _face;
    canvas.drawCircle(const Offset(106, 146), 56, face);
    canvas.drawCircle(const Offset(194, 146), 56, face);
    final white = Paint()..color = _eye;
    canvas.drawCircle(const Offset(106, 146), 35, white);
    canvas.drawCircle(const Offset(194, 146), 35, white);

    // nabuLook: up-left, up-right, back.
    var look = Offset.zero;
    if (mood == NabuMood.thinking) {
      final p = (t % 1.8) / 1.8;
      look = p < 0.3
          ? Offset.lerp(Offset.zero, const Offset(-9, -7), _ease(p / 0.3))!
          : p < 0.65
          ? Offset.lerp(const Offset(-9, -7), const Offset(9, -7), _ease((p - 0.3) / 0.35))!
          : Offset.lerp(const Offset(9, -7), Offset.zero, _ease((p - 0.65) / 0.35))!;
    }
    final pupil = Paint()..color = _pupil;
    canvas.drawCircle(const Offset(110, 150) + look, 19, pupil);
    canvas.drawCircle(const Offset(190, 150) + look, 19, pupil);
    canvas.drawCircle(const Offset(116, 142) + look, 6, white);
    canvas.drawCircle(const Offset(196, 142) + look, 6, white);

    // nabuBlink: the lids drop from the brow for a moment near the end of
    // each cycle.
    final period = switch (mood) {
      NabuMood.thinking => 6.0,
      NabuMood.speaking => 3.8,
      _ => 4.5,
    };
    final bp = (t % period) / period;
    final lid = bp < 0.92 ? 0.0 : (bp < 0.95 ? _ease((bp - 0.92) / 0.03) : _ease((1 - bp) / 0.05));
    if (lid > 0) {
      for (final x in const [106.0, 194.0]) {
        canvas.save();
        canvas.translate(0, 108);
        canvas.scale(1, lid);
        canvas.translate(0, -108);
        canvas.drawCircle(Offset(x, 146), 38, face);
        canvas.restore();
      }
    }

    final cheek = Paint()..color = _cheek;
    canvas.drawOval(Rect.fromCenter(center: const Offset(74, 202), width: 32, height: 18), cheek);
    canvas.drawOval(Rect.fromCenter(center: const Offset(226, 202), width: 32, height: 18), cheek);

    // nabuTalk: the lower beak opens and closes, .26 s each way.
    var jaw = 1.0;
    if (mood == NabuMood.speaking && talking) {
      final p = (t % 0.52) / 0.26;
      jaw = 0.15 + _ease(p <= 1 ? p : 2 - p);
    }
    canvas.save();
    canvas.translate(0, 194);
    canvas.scale(1, jaw);
    canvas.translate(0, -194);
    canvas.drawPath(_beakLow, Paint()..color = _beakBottom);
    canvas.restore();
    canvas.drawPath(_beakUp, Paint()..color = _beakTop);
  }

  @override
  bool shouldRepaint(_NabuPainter old) =>
      old.mood != mood || old.talking != talking || old.body != body || old.belly != belly || old.ground != ground || old.aura != aura;
}

/// The 56 px Nabu beside each answer: just the face on a body-coloured disc.
class NabuAvatar extends StatelessWidget {
  const NabuAvatar({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(color: _body, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: const SizedBox(width: 44, height: 44, child: CustomPaint(painter: _AvatarPainter())),
  );
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 300);
    final face = Paint()..color = _face;
    canvas.drawCircle(const Offset(106, 150), 58, face);
    canvas.drawCircle(const Offset(194, 150), 58, face);
    final pupil = Paint()..color = _pupil;
    canvas.drawCircle(const Offset(110, 152), 24, pupil);
    canvas.drawCircle(const Offset(190, 152), 24, pupil);
    canvas.drawPath(
      Path()
        ..moveTo(150, 216)
        ..lineTo(128, 186)
        ..quadraticBezierTo(150, 172, 172, 186)
        ..close(),
      Paint()..color = _beakTop,
    );
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => false;
}
