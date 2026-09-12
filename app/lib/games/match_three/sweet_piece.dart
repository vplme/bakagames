import 'package:flutter/material.dart';
import 'package:match_three/match_three.dart';

const sweetColors = [
  Color(0xFFD82367),
  Color(0xFF15884D),
  Color(0xFF923EE1),
  Color(0xFFE99B17),
  Color(0xFF159DCE),
  Color(0xFFCB692B),
  Color(0xFFE64797),
  Color(0xFFF08051),
];
const sweetNames = [
  'Berry heart',
  'Mint leaf',
  'Grape star',
  'Honey hexagon',
  'Blueberry drop',
  'Caramel diamond',
  'Raspberry ring',
  'Peach twist',
];
String sweetLabel(Sweet piece) =>
    '${sweetNames[piece.type]}${switch (piece.special) {
      Special.none => '',
      Special.row => ', row clearer',
      Special.column => ', column clearer',
      Special.color => ', rainbow color clearer',
    }}';

/// Original sprites share an atlas; later sweets use scalable candy artwork.
class SweetPiece extends StatelessWidget {
  final Sweet piece;
  final double size;
  const SweetPiece({super.key, required this.piece, this.size = 44});
  @override
  Widget build(BuildContext context) {
    final index = piece.special == Special.color ? 5 : piece.type;
    final tile = size / .9;
    // Visible alpha bounds, in atlas-cell pixels (ignoring faint edge noise).
    const centers = [
      Offset(142, 140),
      Offset(134, 133.5),
      Offset(127, 132.5),
      Offset(142, 119),
      Offset(127, 118.5),
      Offset(126, 118.5),
    ];
    final center = centers[index.clamp(0, 5)];
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (piece.type >= 5 && piece.special != Special.color)
              CustomPaint(
                size: Size.square(size),
                painter: _CandyPainter(piece.type),
              )
            else
              ClipRect(
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    children: [
                      Positioned(
                        left:
                            -(index % 3) * tile +
                            size / 2 -
                            center.dx / 256 * tile,
                        top:
                            -(index ~/ 3) * tile +
                            size / 2 -
                            center.dy / 256 * tile,
                        width: tile * 3,
                        height: tile * 2,
                        child: Image.asset(
                          'assets/sweets/candy-atlas.webp',
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (piece.special == Special.row || piece.special == Special.column)
              SizedBox(
                width: size * .58,
                height: size * .58,
                child: CustomPaint(
                  painter: _StripePainter(piece.special == Special.row),
                ),
              ),
            if (piece.special == Special.color)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: size * .32,
                  height: size * .32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF4FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF753D88)),
                  ),
                  child: SweetPiece(
                    piece: Sweet(piece.id, piece.type),
                    size: size * .28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  final bool horizontal;
  const _StripePainter(this.horizontal);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    if (!horizontal) canvas.rotate(1.57079632679);
    for (final y in [-size.height * .12, size.height * .12]) {
      final start = Offset(-size.width * .4, y),
          end = Offset(size.width * .4, y);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0x8063255A)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFFFFFADE)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.horizontal != horizontal;
}

/// Distinct silhouettes remain recognizable without relying on color.
class _CandyPainter extends CustomPainter {
  final int type;
  const _CandyPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final path = Path();
    if (type == 5) {
      path.moveTo(50, 8);
      path.lineTo(89, 50);
      path.lineTo(50, 92);
      path.lineTo(11, 50);
      path.close();
    } else if (type == 6) {
      path.fillType = PathFillType.evenOdd;
      path.addOval(const Rect.fromLTWH(10, 10, 80, 80));
      path.addOval(const Rect.fromLTWH(36, 36, 28, 28));
    } else {
      path.moveTo(9, 29);
      path.lineTo(30, 37);
      path.cubicTo(40, 15, 60, 15, 70, 37);
      path.lineTo(91, 29);
      path.lineTo(85, 50);
      path.lineTo(91, 71);
      path.lineTo(70, 63);
      path.cubicTo(60, 85, 40, 85, 30, 63);
      path.lineTo(9, 71);
      path.lineTo(15, 50);
      path.close();
    }
    canvas.drawShadow(path, const Color(0x80592449), 3, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(sweetColors[type], Colors.white, .55)!,
            sweetColors[type],
            Color.lerp(sweetColors[type], const Color(0xFF592449), .35)!,
          ],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = sweetColors[type]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(
      const Rect.fromLTWH(28, 23, 18, 7),
      Paint()..color = const Color(0xCCFFFFFF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CandyPainter old) => old.type != type;
}
