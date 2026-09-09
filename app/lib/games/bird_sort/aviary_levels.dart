import 'package:bird_sort/bird_sort.dart' as engine;

/// Preserve the original seeded positions; every fifth level is a breather.
/// A bijective species mapping changes character variety, never solvability.
engine.Level aviaryLevelFor(int index) {
  final base = index % 5 == 4
      ? engine
            .generateLevel(
              const engine.GeneratorParams(
                colours: 3,
                emptyBranches: 2,
                removeBranchOnComplete: false,
                minOptimalMoves: 4,
              ),
              engine.hash32(index),
            )
            .level
      : engine.levelFor(index);
  final available = index < 3
      ? 3
      : index < 8
      ? 4
      : index < 15
      ? 5
      : index < 24
      ? 6
      : index < 35
      ? 7
      : 8;
  final count = available < base.colourCount ? base.colourCount : available;
  final shift = index < 3 ? 0 : index % count;
  return engine.Level(
    capacity: base.capacity,
    seed: base.seed,
    removeBranchOnComplete: base.removeBranchOnComplete,
    partialMovesAllowed: base.partialMovesAllowed,
    branches: [
      for (final b in base.branches)
        engine.Branch(
          side: b.side,
          removed: b.removed,
          birds: [for (final colour in b.birds) (colour + shift) % count],
        ),
    ],
  );
}
