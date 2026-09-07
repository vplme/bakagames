import 'package:flutter/material.dart';

import 'palette.dart';

/// A simple original vector bird: plump oval body, round head, triangle
/// beak, dot eye, one wing arc and a two-feather tail. Faces left or right.
class BirdPainter extends CustomPainter {
  final int colourId;
  final bool facingLeft;

  const BirdPainter({required this.colourId, required this.facingLeft});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (facingLeft) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final w = size.width, h = size.height;
    final body = Paint()..color = birdColour(colourId);
    final shade = Paint()..color = birdShade(colourId);

    // Tail: two feathers poking out the back.
    final tail = Path()
      ..moveTo(w * 0.18, h * 0.55)
      ..lineTo(-w * 0.02, h * 0.38)
      ..lineTo(w * 0.14, h * 0.68)
      ..lineTo(-w * 0.04, h * 0.62)
      ..lineTo(w * 0.22, h * 0.78)
      ..close();
    canvas.drawPath(tail, shade);

    // Body.
    canvas.drawOval(
        Rect.fromLTWH(w * 0.08, h * 0.32, w * 0.62, h * 0.60), body);
    // Head.
    canvas.drawCircle(Offset(w * 0.62, h * 0.34), w * 0.22, body);
    // Belly highlight.
    canvas.drawOval(
        Rect.fromLTWH(w * 0.18, h * 0.55, w * 0.34, h * 0.32),
        Paint()..color = Colors.white.withValues(alpha: 0.35));
    // Wing.
    final wing = Path()
      ..moveTo(w * 0.22, h * 0.48)
      ..quadraticBezierTo(w * 0.10, h * 0.72, w * 0.36, h * 0.80)
      ..quadraticBezierTo(w * 0.50, h * 0.76, w * 0.48, h * 0.55)
      ..close();
    canvas.drawPath(wing, shade);
    // Beak.
    final beak = Path()
      ..moveTo(w * 0.80, h * 0.28)
      ..lineTo(w * 0.99, h * 0.36)
      ..lineTo(w * 0.80, h * 0.44)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFF9A825));
    // Eye.
    canvas.drawCircle(Offset(w * 0.66, h * 0.30), w * 0.05,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.675, h * 0.30), w * 0.028,
        Paint()..color = const Color(0xFF212121));
    // Feet.
    final feet = Paint()
      ..color = const Color(0xFFF9A825)
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(w * 0.34, h * 0.90), Offset(w * 0.34, h * 1.0), feet);
    canvas.drawLine(
        Offset(w * 0.46, h * 0.90), Offset(w * 0.46, h * 1.0), feet);
    canvas.restore();
  }

  @override
  bool shouldRepaint(BirdPainter old) =>
      old.colourId != colourId || old.facingLeft != facingLeft;
}
