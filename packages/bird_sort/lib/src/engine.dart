import 'models.dart';

/// Immutable game state. Equality compares the *position* (level, current
/// branches, won/stuck flags) and deliberately excludes [history]: two states
/// reached by different move sequences are the same position.
class GameState {
  final Level level;
  final List<Branch> branches;
  final List<GameState> history;
  final bool isWon;
  final bool isStuck;

  GameState._({
    required this.level,
    required List<Branch> branches,
    required List<GameState> history,
    required this.isWon,
    required this.isStuck,
  })  : branches = List.unmodifiable(branches),
        history = List.unmodifiable(history);

  /// The starting state for [level]. The engine does not auto-fly branches
  /// that are already complete at deal time; the generator rejects such
  /// deals (see docs/design.md).
  factory GameState.initial(Level level) {
    final won = _computeWon(level.branches);
    return GameState._(
      level: level,
      branches: level.branches,
      history: const [],
      isWon: won,
      isStuck: !won && _computeStuck(level, level.branches),
    );
  }

  int get moveCount => history.length;

  @override
  bool operator ==(Object other) {
    if (other is! GameState ||
        other.level != level ||
        other.isWon != isWon ||
        other.isStuck != isStuck ||
        other.branches.length != branches.length) {
      return false;
    }
    for (var i = 0; i < branches.length; i++) {
      if (other.branches[i] != branches[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(level, isWon, isStuck, Object.hashAll(branches));
}

/// True when [branch] is full and single-colour (and not already removed).
bool isComplete(Branch branch, int capacity) {
  if (branch.removed || branch.birds.length != capacity) return false;
  final first = branch.birds.first;
  return branch.birds.every((c) => c == first);
}

/// The canonical size for a move from [from] to [to], or null when the move
/// is invalid. This is the only place move legality is defined.
int? moveSize(Level level, List<Branch> branches, int from, int to) {
  if (from == to ||
      from < 0 ||
      to < 0 ||
      from >= branches.length ||
      to >= branches.length) {
    return null;
  }
  final a = branches[from];
  final b = branches[to];
  if (a.removed || b.removed || a.isEmpty) return null;
  final free = level.capacity - b.birds.length;
  if (free < 1) return null;
  if (!b.isEmpty && b.tipColour != a.tipColour) return null;
  final group = a.linkedGroupSize;
  if (level.partialMovesAllowed) return group < free ? group : free;
  return group <= free ? group : null;
}

/// A trivial move relocates a linked group that is the sole occupant of its
/// branch onto an empty branch — legal, but it can never make progress.
bool isTrivialMove(GameState state, Move move) {
  final a = state.branches[move.from];
  final b = state.branches[move.to];
  return b.isEmpty && a.linkedGroupSize == a.birds.length;
}

/// All valid moves in [state], trivial ones included (the player may make
/// them; solver and stuck detection filter them out).
List<Move> validMoves(GameState state) {
  final moves = <Move>[];
  for (var from = 0; from < state.branches.length; from++) {
    for (var to = 0; to < state.branches.length; to++) {
      final size = moveSize(state.level, state.branches, from, to);
      if (size != null) {
        moves.add(Move(from: from, to: to, count: size));
      }
    }
  }
  return moves;
}

/// Applies [move], returning the new state. Throws [ArgumentError] when the
/// move is invalid or its [Move.count] differs from the canonical size.
/// Single source of truth for the rules — solver and generator call this.
GameState applyMove(GameState state, Move move) {
  final size = moveSize(state.level, state.branches, move.from, move.to);
  if (size == null) {
    throw ArgumentError('Invalid move $move');
  }
  if (move.count != size) {
    throw ArgumentError(
        'Invalid move $move: canonical count is $size, got ${move.count}');
  }

  final level = state.level;
  final source = state.branches[move.from];
  final target = state.branches[move.to];
  final colour = source.tipColour!;

  final newSource = source.copyWith(
      birds: source.birds.sublist(0, source.birds.length - size));
  var newTarget = target.copyWith(
      birds: [...target.birds, for (var i = 0; i < size; i++) colour]);

  // Only the destination can complete: the flock flies away, and the branch
  // either stays (empty, reusable) or is removed, per the level's ruleset.
  if (isComplete(newTarget, level.capacity)) {
    newTarget = newTarget.copyWith(
        birds: const [], removed: level.removeBranchOnComplete);
  }

  final branches = [
    for (var i = 0; i < state.branches.length; i++)
      i == move.from
          ? newSource
          : i == move.to
              ? newTarget
              : state.branches[i],
  ];

  final won = _computeWon(branches);
  return GameState._(
    level: level,
    branches: branches,
    history: [...state.history, state],
    isWon: won,
    isStuck: !won && _computeStuck(level, branches),
  );
}

/// Previous state, or [state] itself when there is nothing to undo.
GameState undo(GameState state) =>
    state.history.isEmpty ? state : state.history.last;

/// Back to the initial state (history cleared).
GameState restart(GameState state) =>
    state.history.isEmpty ? state : state.history.first;

bool _computeWon(List<Branch> branches) =>
    branches.every((b) => b.removed || b.isEmpty);

/// Stuck: no valid non-trivial move exists. (Trivial: whole-branch content
/// moved to an empty branch — shuffling, never progress.)
bool _computeStuck(Level level, List<Branch> branches) {
  for (var from = 0; from < branches.length; from++) {
    for (var to = 0; to < branches.length; to++) {
      final size = moveSize(level, branches, from, to);
      if (size == null) continue;
      final trivial = branches[to].isEmpty &&
          branches[from].linkedGroupSize == branches[from].birds.length;
      if (!trivial) return false;
    }
  }
  return true;
}

/// Same position with an empty history. Used by the solver so search nodes
/// don't accumulate O(depth) history lists; the position itself (and thus
/// equality) is unchanged.
GameState stripHistory(GameState state) => state.history.isEmpty
    ? state
    : GameState._(
        level: state.level,
        branches: state.branches,
        history: const [],
        isWon: state.isWon,
        isStuck: state.isStuck,
      );
