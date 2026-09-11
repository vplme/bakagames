import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:match_three/match_three.dart';
import 'sweet_piece.dart';

/// Game-owned library art fills the shell's entire preview area.
class SweetsPreview extends StatelessWidget {
  const SweetsPreview({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/sweets/garden.webp',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x30FFF2FA),
                  Color(0x00FFF2FA),
                  Color(0x60FBD6EA),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          left: 14,
          right: 14,
          bottom: 0,
          height: 165,
          child: SweetsHero(),
        ),
      ],
    ),
  );
}

/// A generous candy display, like the three-bird perch on Pocket Aviary's home.
class SweetsHero extends StatelessWidget {
  const SweetsHero({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final size = math.min(box.maxHeight * .73, width * .36);
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: width * .05,
              right: width * .05,
              bottom: 8,
              height: 34,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFAE7), Color(0xFFF9C58B)],
                  ),
                  border: Border.all(color: const Color(0xFFFFF4D8), width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x406C2854),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: width * .04,
              bottom: 30,
              child: Transform.rotate(
                angle: -.2,
                child: SweetPiece(piece: const Sweet(0, 0), size: size),
              ),
            ),
            Positioned(
              right: width * .04,
              bottom: 30,
              child: Transform.rotate(
                angle: .18,
                child: SweetPiece(
                  piece: const Sweet(1, 1, Special.row),
                  size: size,
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              child: SweetPiece(
                piece: const Sweet(2, 2, Special.color),
                size: size * 1.17,
              ),
            ),
            Positioned(
              left: width * .04,
              top: 6,
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFFF3B3),
                size: 23,
              ),
            ),
            Positioned(
              right: width * .08,
              top: 2,
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFFF3B3),
                size: 17,
              ),
            ),
          ],
        );
      },
    ),
  );
}
