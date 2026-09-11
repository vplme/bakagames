import 'package:flutter/material.dart';
import 'package:match_three/match_three.dart';

const sweetColors = [
  Color(0xFFD82367),
  Color(0xFF15884D),
  Color(0xFF923EE1),
  Color(0xFFE99B17),
  Color(0xFF159DCE),
];
const sweetNames = [
  'Berry heart',
  'Mint leaf',
  'Grape star',
  'Honey hexagon',
  'Blueberry drop',
];
String sweetLabel(Sweet piece) =>
    '${sweetNames[piece.type]}${switch (piece.special) {
      Special.none => '',
      Special.row => ', row clearer',
      Special.column => ', column clearer',
      Special.color => ', rainbow color clearer',
    }}';

/// Six sprites share a single decoded atlas, including the rainbow bonbon.
class SweetPiece extends StatelessWidget {
  final Sweet piece;
  final double size;
  const SweetPiece({super.key, required this.piece, this.size = 44});
  @override
  Widget build(BuildContext context) {
    final index = piece.special == Special.color ? 5 : piece.type;
    final tile = size / .9;
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRect(
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  children: [
                    Positioned(
                      left: -(index % 3) * tile - (tile - size) / 2,
                      top: -(index ~/ 3) * tile - (tile - size) / 2,
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
