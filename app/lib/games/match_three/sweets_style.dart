import 'dart:math' as math;
import 'package:flutter/material.dart';

const sweetsInk = Color(0xFF592449);
const sweetsPink = Color(0xFFB92E72);

class SweetsBackdrop extends StatelessWidget {
  final Widget child;
  final bool vivid;
  const SweetsBackdrop({super.key, required this.child, this.vivid = false});
  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFFBE4EF),
        image: DecorationImage(
          image: AssetImage('assets/sweets/garden.webp'),
          fit: BoxFit.cover,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFF5F9).withValues(alpha: vivid ? .2 : .86),
              const Color(0xFFFFEFF7).withValues(alpha: vivid ? .1 : .72),
              const Color(0xFFF5D1EE).withValues(alpha: vivid ? .05 : .45),
            ],
          ),
        ),
        child: child,
      ),
    ),
  );
}

class SugarCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const SugarCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBFD).withValues(alpha: .94),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x205A2153),
          offset: Offset(0, 6),
          blurRadius: 18,
        ),
      ],
    ),
    child: child,
  );
}

/// A bounded burst on a cleared cell; never runs as an idle animation.
class SugarBurst extends StatelessWidget {
  final Color color;
  const SugarBurst({super.key, required this.color});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (_, t, _) => CustomPaint(painter: _BurstPainter(t, color)),
    ),
  );
}

class _BurstPainter extends CustomPainter {
  final double t;
  final Color color;
  _BurstPainter(this.t, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final center = size.center(Offset.zero);
    final paint = Paint()..color = color.withValues(alpha: (1 - t) * .9);
    for (var i = 0; i < 7; i++) {
      final angle = i * math.pi * 2 / 7;
      final radius = size.width * (.08 + t * .38);
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        (1 - t) * 3.2 + .3,
        paint,
      );
    }
    canvas.drawCircle(
      center,
      size.width * t * .35,
      Paint()
        ..color = Colors.white.withValues(alpha: (1 - t) * .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t || old.color != color;
}
