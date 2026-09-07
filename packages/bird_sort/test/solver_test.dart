import 'package:bird_sort/bird_sort.dart';
import 'package:test/test.dart';

Branch b(List<int> birds) => Branch(side: Side.left, birds: birds);

Level level(List<Branch> branches, {bool remove = false}) => Level(
    capacity: 4,
    branches: branches,
    removeBranchOnComplete: remove,
    partialMovesAllowed: true);

/// Replays [moves] through the engine — the solver's plan must be legal
/// move by move and actually win.
GameState replay(Level l, List<Move> moves) {
  var s = GameState.initial(l);
  for (final m in moves) {
    s = applyMove(s, m);
  }
  return s;
}

void main() {
  test('trivial level: one move to complete', () {
    final l = level([b([1, 1, 1]), b([1]), b([])]);
    final r = solveLevel(l);
    expect(r.solvable, isTrue);
    expect(r.budgetExceeded, isFalse);
    expect(r.moves, hasLength(1));
    expect(replay(l, r.moves).isWon, isTrue);
  });

  test('already-won state solves with zero moves', () {
    final r = solve(GameState.initial(level([b([]), b([])])));
    expect(r.solvable, isTrue);
    expect(r.moves, isEmpty);
  });

  test('medium hand-written level solves and the plan replays to a win', () {
    final l = level([
      b([1, 2, 3, 1]),
      b([2, 1, 3, 2]),
      b([3, 3, 1, 2]),
      b([]),
      b([]),
    ]);
    final r = solveLevel(l);
    expect(r.solvable, isTrue);
    expect(replay(l, r.moves).isWon, isTrue);
  });

  test('medium level with branch removal solves', () {
    final l = level([
      b([1, 2, 1, 2]),
      b([2, 1, 2, 1]),
      b([]),
      b([]),
    ], remove: true);
    final r = solveLevel(l);
    expect(r.solvable, isTrue);
    final end = replay(l, r.moves);
    expect(end.isWon, isTrue);
    expect(end.branches.where((br) => br.removed), hasLength(2));
  });

  test('unsolvable level reported as unsolvable, not budget-exceeded', () {
    // Two full alternating branches, no free space anywhere: stuck at move 0.
    final l = level([b([1, 2, 1, 2]), b([2, 1, 2, 1])]);
    final r = solveLevel(l);
    expect(r.solvable, isFalse);
    expect(r.budgetExceeded, isFalse);
    expect(r.unknown, isFalse);
  });

  test('deeper unsolvable level: search space exhausts', () {
    // 3 colours but only 3 birds of colour 1 dealt across full branches —
    // impossible to ever complete colour 1 (needs 4). Build it as full
    // branches with a colour-count mismatch (12 birds: 3×1, 5×2, 4×3).
    final l = level([
      b([1, 2, 3, 2]),
      b([2, 1, 3, 3]),
      b([2, 1, 3, 2]),
      b([]),
    ]);
    final r = solveLevel(l);
    expect(r.solvable, isFalse);
    expect(r.budgetExceeded, isFalse);
  });

  test('respects maxNodes and reports unknown', () {
    final l = level([
      b([1, 2, 3, 1]),
      b([2, 1, 3, 2]),
      b([3, 3, 1, 2]),
      b([]),
      b([]),
    ]);
    final r = solveLevel(l, maxNodes: 2);
    expect(r.budgetExceeded, isTrue);
    expect(r.solvable, isFalse);
    expect(r.unknown, isTrue);
    expect(r.nodesExpanded, lessThanOrEqualTo(2));
  });

  test('optimal length sanity: solver never beats the theoretical minimum',
      () {
    final l = level([b([1, 1, 1]), b([1]), b([])]);
    expect(solveLevel(l).moves.length, 1);
    // Two colours interleaved needs at least 4 moves.
    final l2 = level([b([1, 2, 1, 2]), b([2, 1, 2, 1]), b([]), b([])]);
    final r2 = solveLevel(l2);
    expect(r2.solvable, isTrue);
    expect(r2.moves.length, greaterThanOrEqualTo(4));
  });
}
