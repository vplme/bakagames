import 'dart:math' as math;
import 'package:flutter/material.dart';

const moonInk = Color(0xFF283457);
const moonGold = Color(0xFFF2D18C);
const moonLilac = Color(0xFFD7C5F0);
const moonGardenScene = 'assets/solitaire/moon-garden.webp';

class MoonGardenBackdrop extends StatelessWidget {
  final Widget child;
  final bool shaded, reducedMotion;
  const MoonGardenBackdrop({
    super.key,
    required this.child,
    this.shaded = false,
    this.reducedMotion = true,
  });
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        moonGardenScene,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
      if (shaded)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55202D50), Color(0xB315233D)],
            ),
          ),
        ),
      if (!reducedMotion && !MediaQuery.disableAnimationsOf(context))
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 2800),
              builder: (_, t, _) => CustomPaint(painter: _FirefliesPainter(t)),
            ),
          ),
        ),
      child,
    ],
  );
}

/// Original vector crescent and stars, crisp even on the smallest card backs.
class MoonEmblem extends StatelessWidget {
  final bool ornate;
  const MoonEmblem({super.key, this.ornate = false});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _MoonPainter(ornate),
    child: const SizedBox.expand(),
  );
}

class _MoonPainter extends CustomPainter {
  final bool ornate;
  const _MoonPainter(this.ornate);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final unit = math.min(size.width, size.height) / 80;
    canvas.scale(unit);
    final paint = Paint()..color = moonGold;
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 23)),
      Path()..addOval(Rect.fromCircle(center: Offset(11, -8), radius: 22)),
    );
    canvas.drawPath(crescent, paint);
    void star(double x, double y, double r) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y - r)
          ..lineTo(x + r * .32, y - r * .32)
          ..lineTo(x + r, y)
          ..lineTo(x + r * .32, y + r * .32)
          ..lineTo(x, y + r)
          ..lineTo(x - r * .32, y + r * .32)
          ..lineTo(x - r, y)
          ..lineTo(x - r * .32, y - r * .32)
          ..close(),
        paint,
      );
    }

    star(15, -5, 7);
    star(29, -25, 4);
    star(-24, 24, 3);
    if (ornate) {
      final line = Paint()
        ..color = moonLilac.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawOval(const Rect.fromLTWH(-31, -36, 62, 72), line);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        canvas.drawCircle(
          Offset(math.cos(a) * 34, math.sin(a) * 39),
          1.5,
          paint,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MoonPainter oldDelegate) => ornate != oldDelegate.ornate;
}

/// A brief constellation blooms when a foundation receives a card.
class FoundationStars extends StatelessWidget {
  const FoundationStars({super.key});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      builder: (context, t, _) => Opacity(
        opacity: 1 - t,
        child: Transform.translate(
          offset: Offset(0, -22 * t),
          child: Transform.scale(
            scale: .7 + t * .7,
            child: const Icon(Icons.auto_awesome, color: moonGold, size: 30),
          ),
        ),
      ),
    ),
  );
}

class _FirefliesPainter extends CustomPainter {
  final double t;
  const _FirefliesPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 12; i++) {
      final x = (i % 2 == 0 ? .04 : .92) + math.sin(i * 2.3) * .035;
      final y = .22 + (i / 12) * .7;
      final opacity =
          math.sin(math.pi * t) * (.55 + .45 * math.sin(t * math.pi * 4 + i));
      final paint = Paint()
        ..color = moonGold.withValues(alpha: opacity.clamp(0, 1));
      final center = Offset(size.width * x, size.height * y - 12 * t);
      canvas.drawCircle(
        center,
        5,
        Paint()..color = paint.color.withValues(alpha: opacity * .2),
      );
      canvas.drawCircle(center, 1.7, paint);
    }
  }

  @override
  bool shouldRepaint(_FirefliesPainter oldDelegate) => oldDelegate.t != t;
}
