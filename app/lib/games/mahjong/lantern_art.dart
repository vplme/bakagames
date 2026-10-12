import 'dart:math' as math;
import 'package:flutter/material.dart';

const lanternJade = Color(0xFF155E59);
const lanternGold = Color(0xFFFFCD69);
const lanternScene = 'assets/mahjong/lantern-festival.webp';
const festivalNames = [
  'lantern',
  'lotus',
  'bamboo',
  'moon',
  'plum blossom',
  'koi',
  'fan',
  'cloud',
  'pine',
  'golden knot',
  'star',
];
const _inks = [
  Color(0xFFD63F46),
  Color(0xFFD95691),
  Color(0xFF18856C),
  Color(0xFF7063BA),
  Color(0xFFE56677),
  Color(0xFFDF6634),
  Color(0xFF248EA3),
  Color(0xFF527CBC),
  Color(0xFF29775B),
  Color(0xFFC38723),
  Color(0xFFAB569A),
];

class LanternBackdrop extends StatelessWidget {
  final Widget child;
  final bool shaded;
  const LanternBackdrop({super.key, required this.child, this.shaded = false});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          lanternScene,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        if (shaded)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22103942), Color(0xBB103942)],
              ),
            ),
          ),
        child,
      ],
    ),
  );
}

/// Vector engravings stay crisp on small tiles and differ by shape, not color alone.
class FestivalMotif extends StatelessWidget {
  final int face;
  const FestivalMotif({super.key, required this.face});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _MotifPainter(face));
}

class _MotifPainter extends CustomPainter {
  final int face;
  _MotifPainter(this.face);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) / 64;
    canvas.scale(scale);
    final ink = _inks[face % _inks.length];
    final paint = Paint()..color = ink;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void stroke(Offset a, Offset b, [Color? color]) {
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = color ?? ink
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    switch (face) {
      case 0:
        stroke(const Offset(0, -29), const Offset(0, -21), lanternGold);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-21, -21, 42, 39),
            const Radius.circular(14),
          ),
          paint,
        );
        canvas.drawOval(
          const Rect.fromLTWH(-10, -21, 20, 39),
          line..color = lanternGold,
        );
        stroke(const Offset(-12, -22), const Offset(12, -22), lanternGold);
        stroke(const Offset(-12, 19), const Offset(12, 19), lanternGold);
        for (var x = -6; x <= 6; x += 6) {
          stroke(
            Offset(x.toDouble(), 20),
            Offset(x.toDouble(), 29),
            lanternGold,
          );
        }
      case 1:
      case 4:
        final petals = face == 1 ? 5 : 6;
        for (var i = 0; i < petals; i++) {
          canvas.save();
          canvas.rotate(i * math.pi * 2 / petals);
          canvas.drawOval(const Rect.fromLTWH(-9, -26, 18, 28), paint);
          canvas.restore();
        }
        canvas.drawCircle(Offset.zero, 7, Paint()..color = lanternGold);
        if (face == 1) {
          stroke(const Offset(-23, 25), const Offset(23, 25), lanternJade);
        }
      case 2:
        for (var x = -15; x <= 15; x += 15) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x - 3, -23, 6, 48),
              const Radius.circular(3),
            ),
            paint,
          );
          for (var y = -12; y <= 15; y += 13) {
            stroke(
              Offset(x - 4, y.toDouble()),
              Offset(x + 4, y.toDouble()),
              lanternGold,
            );
          }
        }
        canvas.drawOval(const Rect.fromLTWH(4, -26, 23, 9), paint);
      case 3:
        final moon = Path()..addOval(const Rect.fromLTWH(-23, -25, 46, 50));
        final cut = Path()..addOval(const Rect.fromLTWH(-6, -29, 40, 44));
        canvas.drawPath(
          Path.combine(PathOperation.difference, moon, cut),
          paint,
        );
        canvas.drawCircle(
          const Offset(17, 16),
          4,
          Paint()..color = lanternGold,
        );
      case 5:
        canvas.drawOval(const Rect.fromLTWH(-21, -12, 36, 25), paint);
        canvas.drawPath(
          Path()
            ..moveTo(10, 0)
            ..lineTo(27, -16)
            ..lineTo(27, 16)
            ..close(),
          paint,
        );
        canvas.drawCircle(
          const Offset(-13, -3),
          3,
          Paint()..color = Colors.white,
        );
        canvas.drawArc(
          const Rect.fromLTWH(-17, -12, 20, 25),
          -1.1,
          2.2,
          false,
          line..color = lanternGold,
        );
      case 6:
        canvas.drawArc(
          const Rect.fromLTWH(-27, -22, 54, 54),
          math.pi,
          math.pi,
          true,
          paint,
        );
        for (var i = 0; i < 5; i++) {
          final a = math.pi + (i + 1) * math.pi / 6;
          stroke(
            const Offset(0, 5),
            Offset(25 * math.cos(a), 5 + 25 * math.sin(a)),
            lanternGold,
          );
        }
        stroke(const Offset(0, 5), const Offset(0, 22));
      case 7:
        for (final p in [
          const Offset(-15, 3),
          const Offset(0, -8),
          const Offset(16, 1),
        ]) {
          canvas.drawCircle(p, 12, paint);
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-25, 0, 51, 17),
            const Radius.circular(8),
          ),
          paint,
        );
        stroke(const Offset(-14, 25), const Offset(16, 25), lanternGold);
      case 8:
        stroke(
          const Offset(0, -18),
          const Offset(0, 27),
          const Color(0xFF9E5C3C),
        );
        for (var y = -20; y <= 10; y += 15) {
          final w = (y + 20) / 3 + 13;
          canvas.drawPath(
            Path()
              ..moveTo(0, y - 9)
              ..lineTo(w, y + 12)
              ..lineTo(-w, y + 12)
              ..close(),
            paint,
          );
        }
      case 9:
        for (final x in [-9.0, 9.0]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, -5), width: 20, height: 28),
            line,
          );
        }
        canvas.drawPath(
          Path()
            ..moveTo(0, -23)
            ..lineTo(17, 0)
            ..lineTo(0, 22)
            ..lineTo(-17, 0)
            ..close(),
          line,
        );
        stroke(const Offset(-5, 19), const Offset(-8, 29));
        stroke(const Offset(5, 19), const Offset(8, 29));
      default:
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? 27.0 : 12.0;
          final a = i * math.pi / 5 - math.pi / 2;
          if (i == 0) {
            star.moveTo(r * math.cos(a), r * math.sin(a));
          } else {
            star.lineTo(r * math.cos(a), r * math.sin(a));
          }
        }
        canvas.drawPath(star..close(), paint);
        canvas.drawCircle(Offset.zero, 5, Paint()..color = lanternGold);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MotifPainter oldDelegate) => oldDelegate.face != face;
}
