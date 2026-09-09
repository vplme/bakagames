import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'aviary.dart';

/// Reuses bundled gameplay artwork without running the game or its animations.
class AviaryPreview extends StatelessWidget {
  const AviaryPreview({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            habitatAsset(0),
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
        ),
        Positioned.fill(
          child: ColoredBox(color: aviaryCream.withValues(alpha: .25)),
        ),
        LayoutBuilder(
          builder: (context, box) {
            final size = math.min(110.0, box.maxWidth * .27);
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: 29,
                  height: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFA97545),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 33,
                  left: box.maxWidth * .14,
                  child: BirdArt(species: 0, size: size),
                ),
                Positioned(
                  bottom: 33,
                  right: box.maxWidth * .14,
                  child: BirdArt(species: 1, size: size),
                ),
                Positioned(
                  bottom: 33,
                  child: BirdArt(species: 2, size: size * 1.1),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
