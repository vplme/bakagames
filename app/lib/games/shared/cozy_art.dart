import 'dart:math' as math;
import 'package:flutter/material.dart';

const cozyInk = Color(0xFF514861);

/// Small vector companions: no animation, assets, or extra hit targets.
class CozyFriend extends StatelessWidget {
  final bool garden, bunny;
  final double size;
  const CozyFriend({
    super.key,
    this.garden = false,
    this.bunny = false,
    this.size = 56,
  });
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _FriendPainter(garden, bunny)),
    ),
  );
}

class _FriendPainter extends CustomPainter {
  final bool garden, bunny;
  const _FriendPainter(this.garden, this.bunny);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final paint = Paint();
    void oval(Rect rect, Color color) =>
        canvas.drawOval(rect, paint..color = color);
    const cream = Color(0xFFFFF4DC), pink = Color(0xFFF1A8B9);
    if (garden) {
      for (var i = 0; i < 7; i++) {
        final angle = i * math.pi * 2 / 7;
        oval(
          Rect.fromCircle(
            center: Offset(
              50 + math.cos(angle) * 25,
              48 + math.sin(angle) * 25,
            ),
            radius: 18,
          ),
          pink,
        );
      }
      oval(const Rect.fromLTWH(27, 26, 46, 46), const Color(0xFFFFDF91));
    } else if (bunny) {
      oval(const Rect.fromLTWH(23, 5, 21, 54), cream);
      oval(const Rect.fromLTWH(56, 5, 21, 54), cream);
      oval(const Rect.fromLTWH(29, 12, 9, 33), pink);
      oval(const Rect.fromLTWH(62, 12, 9, 33), pink);
      oval(const Rect.fromLTWH(14, 35, 72, 58), cream);
    } else {
      // A plump crescent, with a small sleeping face on its lit side.
      final moon = Path()
        ..moveTo(72, 12)
        ..cubicTo(14, -2, -1, 66, 40, 88)
        ..cubicTo(63, 103, 91, 83, 94, 65)
        ..cubicTo(54, 83, 37, 37, 72, 12)
        ..close();
      canvas.drawPath(moon, paint..color = const Color(0xFFFFDF91));
    }
    final cy = garden
        ? 49.0
        : bunny
        ? 62.0
        : 59.0;
    final cx = garden || bunny ? 50.0 : 35.0;
    oval(
      Rect.fromCenter(center: Offset(cx - 16, cy + 8), width: 12, height: 7),
      pink,
    );
    oval(
      Rect.fromCenter(center: Offset(cx + 16, cy + 8), width: 12, height: 7),
      pink,
    );
    paint
      ..color = cozyInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final dx in [-9.0, 9.0]) {
      if (!garden && !bunny) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx + dx, cy - 2), width: 9, height: 7),
          0,
          math.pi,
          false,
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(cx + dx, cy - 3),
          Offset(cx + dx, cy + 1),
          paint,
        );
      }
    }
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + 6), width: 9, height: 7),
      0,
      math.pi,
      false,
      paint,
    );
    paint.style = PaintingStyle.fill;
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FriendPainter oldDelegate) =>
      oldDelegate.garden != garden || oldDelegate.bunny != bunny;
}

class CozyBackdrop extends StatelessWidget {
  final bool garden;
  final Widget child;
  const CozyBackdrop({super.key, required this.garden, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: garden
            ? const [Color(0xFFE2F1DF), Color(0xFFC1DDD0)]
            : const [Color(0xFFF0E8FA), Color(0xFFD7D8F0)],
      ),
    ),
    child: CustomPaint(painter: _Doodles(garden), child: child),
  );
}

class _Doodles extends CustomPainter {
  final bool garden;
  const _Doodles(this.garden);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .46)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var y = 28.0; y < size.height; y += 100) {
      for (var x = 22.0; x < size.width; x += 94) {
        final center = Offset(x + ((y ~/ 100).isEven ? 0 : 30), y);
        if (garden) {
          for (var i = 0; i < 5; i++) {
            final angle = i * math.pi * 2 / 5;
            canvas.drawCircle(
              center + Offset(math.cos(angle) * 4, math.sin(angle) * 4),
              3,
              paint,
            );
          }
        } else {
          canvas.drawLine(
            center - const Offset(0, 5),
            center + const Offset(0, 5),
            paint,
          );
          canvas.drawLine(
            center - const Offset(4, 0),
            center + const Offset(4, 0),
            paint,
          );
        }
        canvas.drawCircle(center + const Offset(39, 36), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Doodles oldDelegate) => oldDelegate.garden != garden;
}

/// Blushing cheeks and a smile, drawn over a tile's distinctive silhouette.
class TinySmile extends StatelessWidget {
  const TinySmile({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _SmilePainter());
}

class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFF3A3B2);
    final y = size.height * .57;
    for (final x in [.29, .71]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * x, y + 3),
          width: size.width * .15,
          height: size.height * .085,
        ),
        p,
      );
    }
    p.color = cozyInk;
    for (final x in [.4, .6]) {
      canvas.drawCircle(Offset(size.width * x, y - 2), size.width * .027, p);
    }
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * .5, y + 2),
        width: size.width * .13,
        height: size.height * .09,
      ),
      0,
      math.pi,
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(_SmilePainter oldDelegate) => false;
}

/// Vector suits stay legible even on devices without playing-card font glyphs.
class CozySuit extends StatelessWidget {
  final int suit;
  final Color color;
  final double size;
  const CozySuit({
    super.key,
    required this.suit,
    required this.color,
    this.size = 24,
  });
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _SuitPainter(suit, color)),
  );
}

class _SuitPainter extends CustomPainter {
  final int suit;
  final Color color;
  const _SuitPainter(this.suit, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()..color = color;
    if (suit == 2) {
      canvas.drawPath(
        Path()
          ..moveTo(12, 1)
          ..lineTo(22, 12)
          ..lineTo(12, 23)
          ..lineTo(2, 12)
          ..close(),
        paint,
      );
    } else if (suit == 3) {
      for (final c in [
        const Offset(12, 7),
        const Offset(6.5, 14),
        const Offset(17.5, 14),
      ]) {
        canvas.drawCircle(c, 5.5, paint);
      }
    } else {
      canvas.save();
      if (suit == 0) {
        canvas.translate(24, 22);
        canvas.rotate(math.pi);
      }
      canvas.drawPath(
        Path()
          ..moveTo(12, 21)
          ..cubicTo(9, 17, 1, 12, 1, 7)
          ..cubicTo(1, 0, 10, 0, 12, 6)
          ..cubicTo(14, 0, 23, 0, 23, 7)
          ..cubicTo(23, 12, 15, 17, 12, 21)
          ..close(),
        paint,
      );
      canvas.restore();
    }
    if (suit == 0 || suit == 3) {
      canvas.drawPath(
        Path()
          ..moveTo(12, 12)
          ..quadraticBezierTo(12, 20, 7, 23)
          ..lineTo(17, 23)
          ..quadraticBezierTo(12, 20, 12, 12)
          ..close(),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SuitPainter oldDelegate) =>
      oldDelegate.suit != suit || oldDelegate.color != color;
}
