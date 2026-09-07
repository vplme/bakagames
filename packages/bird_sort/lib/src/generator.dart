import 'engine.dart';
import 'models.dart';
import 'rng.dart';
import 'solver.dart';

/// Parameters for one generated level.
class GeneratorParams {
  final int colours;
  final int capacity;
  final int emptyBranches;
  final bool removeBranchOnComplete;
  final bool partialMovesAllowed;

  /// Deals whose optimal solution is shorter than this are rejected
  /// (keeps a tier from producing accidentally-easy levels).
  final int minOptimalMoves;

  /// Solver budget per validation attempt.
  final int maxNodes;

  const GeneratorParams({
    required this.colours,
    this.capacity = 4,
    required this.emptyBranches,
    required this.removeBranchOnComplete,
    this.partialMovesAllowed = true,
    this.minOptimalMoves = 0,
    this.maxNodes = 200000,
  });
}

/// A generated level plus generation diagnostics (for tuning the tier table).
class GenerationResult {
  final Level level;

  /// Number of rejected deals before this one was accepted.
  final int rejections;

  /// Nodes the solver expanded validating the accepted deal.
  final int nodesExpanded;

  /// Optimal move count of the accepted deal.
  final int optimalMoves;

  const GenerationResult({
    required this.level,
    required this.rejections,
    required this.nodesExpanded,
    required this.optimalMoves,
  });
}

/// Deterministically generates a solvable level for ([params], [seed]).
///
/// Deals are derived from `hash32(seed ^ hash32(attempt))`, so the whole
/// reject-and-re-roll sequence — and therefore the accepted level — is
/// identical on every platform for the same inputs.
///
/// Rejects a deal when: any branch is complete at deal time, the solver
/// proves it unsolvable, the budget is exceeded (unknown ≠ good), or the
/// optimal solution is shorter than [GeneratorParams.minOptimalMoves].
GenerationResult generateLevel(GeneratorParams params, int seed,
    {int maxAttempts = 1000}) {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final level = _deal(params, seed, attempt);
    if (level.branches
        .any((b) => isComplete(b, params.capacity))) {
      continue;
    }
    final result = solveLevel(level, maxNodes: params.maxNodes);
    if (!result.solvable) continue; // unsolvable or unknown: reject either way
    if (result.moves.length < params.minOptimalMoves) continue;
    return GenerationResult(
      level: level,
      rejections: attempt,
      nodesExpanded: result.nodesExpanded,
      optimalMoves: result.moves.length,
    );
  }
  throw StateError(
      'No solvable deal found for seed=$seed within $maxAttempts attempts — '
      'the tier parameters are likely too tight.');
}

Level _deal(GeneratorParams params, int seed, int attempt) {
  final rng = Rng(hash32(seed ^ hash32(attempt)));
  final birds = <int>[
    for (var colour = 0; colour < params.colours; colour++)
      for (var i = 0; i < params.capacity; i++) colour,
  ];
  rng.shuffle(birds);

  final branches = <Branch>[];
  for (var i = 0; i < params.colours; i++) {
    branches.add(Branch(
      side: branches.length.isEven ? Side.left : Side.right,
      birds: birds.sublist(i * params.capacity, (i + 1) * params.capacity),
    ));
  }
  for (var i = 0; i < params.emptyBranches; i++) {
    branches.add(Branch(
      side: branches.length.isEven ? Side.left : Side.right,
      birds: const [],
    ));
  }

  return Level(
    capacity: params.capacity,
    branches: branches,
    removeBranchOnComplete: params.removeBranchOnComplete,
    partialMovesAllowed: params.partialMovesAllowed,
    seed: seed,
  );
}
