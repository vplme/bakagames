import 'generator.dart';
import 'models.dart';
import 'rng.dart';

/// One row of the difficulty table: [firstLevel] (0-based, inclusive) up to
/// the next tier's [firstLevel]. Edit freely — levels are generated on
/// demand, so reordering tiers only changes levels players haven't reached.
class DifficultyTier {
  final int firstLevel;
  final GeneratorParams params;

  const DifficultyTier({required this.firstLevel, required this.params});
}

/// The difficulty curve. Levels are 0-based internally (shown 1-based in UI):
///   0–9   (levels 1–10):  3 colours, 2 empty, keep branches — the tutorial.
///   10–19 (11–20):        4 colours, 2 empty.
///   20–29 (21–30):        5 colours, 2 empty.
///   30–59 (31–60):        5 colours, 1 empty, branches fly away for good.
///   60+   (61+):          6 colours, 1 empty, removal — the long tail.
const List<DifficultyTier> difficultyTiers = [
  DifficultyTier(
    firstLevel: 0,
    params: GeneratorParams(
        colours: 3,
        emptyBranches: 2,
        removeBranchOnComplete: false,
        minOptimalMoves: 6),
  ),
  DifficultyTier(
    firstLevel: 10,
    params: GeneratorParams(
        colours: 4,
        emptyBranches: 2,
        removeBranchOnComplete: false,
        minOptimalMoves: 10),
  ),
  DifficultyTier(
    firstLevel: 20,
    params: GeneratorParams(
        colours: 5,
        emptyBranches: 2,
        removeBranchOnComplete: false,
        minOptimalMoves: 14),
  ),
  DifficultyTier(
    firstLevel: 30,
    params: GeneratorParams(
        colours: 5,
        emptyBranches: 1,
        removeBranchOnComplete: true,
        minOptimalMoves: 14),
  ),
  DifficultyTier(
    firstLevel: 60,
    params: GeneratorParams(
        colours: 6,
        emptyBranches: 1,
        removeBranchOnComplete: true,
        minOptimalMoves: 18),
  ),
];

/// The tier governing [levelIndex].
DifficultyTier tierFor(int levelIndex) {
  var tier = difficultyTiers.first;
  for (final t in difficultyTiers) {
    if (t.firstLevel <= levelIndex) tier = t;
  }
  return tier;
}

/// Level index → level, deterministic across devices and Dart versions.
Level levelFor(int levelIndex) => generationFor(levelIndex).level;

/// Same as [levelFor] but keeps the generation diagnostics.
GenerationResult generationFor(int levelIndex) =>
    generateLevel(tierFor(levelIndex).params, hash32(levelIndex));
