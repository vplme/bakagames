import 'engine.dart';
import 'models.dart';

/// Result of a solve attempt.
///
/// When [budgetExceeded] is true, solvability is *unknown* — [solvable] is
/// false only in the sense of "not proven solvable within budget", never
/// "proven unsolvable". [solvable] == false with [budgetExceeded] == false
/// is a proof of unsolvability (the pruned search space was exhausted; the
/// prunes only drop moves that lead to already-visited positions).
class SolveResult {
  final bool solvable;
  final List<Move> moves;
  final int nodesExpanded;
  final bool budgetExceeded;

  const SolveResult({
    required this.solvable,
    required this.moves,
    required this.nodesExpanded,
    required this.budgetExceeded,
  });

  /// True when the search proved neither solvable nor unsolvable.
  bool get unknown => budgetExceeded && !solvable;
}

class _Node {
  final GameState state;
  final _Node? parent;
  final Move? move;
  final int g;
  final int f;
  _Node(this.state, this.parent, this.move, this.g, this.f);
}

/// A* over positions. Canonical key = sorted multiset of non-removed branch
/// contents (branch identity and side are irrelevant to solvability).
///
/// Heuristic: Σ over branches (colour segments − 1) + number of colours not
/// yet flown. Each extra segment needs ≥1 move to merge away and each
/// remaining colour needs ≥1 completing move — near-admissible and cheap
/// (see docs/design.md).
///
/// Synchronous by design; the app wraps it in `Isolate.run`.
SolveResult solve(GameState start, {int maxNodes = 200000}) {
  if (start.isWon) {
    return const SolveResult(
        solvable: true, moves: [], nodesExpanded: 0, budgetExceeded: false);
  }

  final open = _Heap();
  final bestG = <String, int>{};
  final s0 = stripHistory(start);
  open.push(_Node(s0, null, null, 0, _heuristic(s0)));
  bestG[_key(s0)] = 0;

  var expanded = 0;
  while (open.isNotEmpty) {
    final node = open.pop();
    if (node.state.isWon) {
      return SolveResult(
        solvable: true,
        moves: _path(node),
        nodesExpanded: expanded,
        budgetExceeded: false,
      );
    }
    if (expanded >= maxNodes) {
      return SolveResult(
          solvable: false,
          moves: const [],
          nodesExpanded: expanded,
          budgetExceeded: true);
    }
    expanded++;

    for (final move in validMoves(node.state)) {
      // Prune trivial moves (position-equivalent under the canonical key)
      // and immediate reversals of the previous move.
      if (isTrivialMove(node.state, move)) continue;
      final prev = node.move;
      if (prev != null && move.from == prev.to && move.to == prev.from) {
        continue;
      }
      final next = stripHistory(applyMove(node.state, move));
      final key = _key(next);
      final g = node.g + 1;
      final known = bestG[key];
      if (known != null && known <= g) continue;
      bestG[key] = g;
      open.push(_Node(next, node, move, g, g + _heuristic(next)));
    }
  }

  return SolveResult(
      solvable: false,
      moves: const [],
      nodesExpanded: expanded,
      budgetExceeded: false);
}

/// Convenience: solve a level from its initial state.
SolveResult solveLevel(Level level, {int maxNodes = 200000}) =>
    solve(GameState.initial(level), maxNodes: maxNodes);

List<Move> _path(_Node node) {
  final moves = <Move>[];
  for (_Node? n = node; n != null && n.move != null; n = n.parent) {
    moves.add(n.move!);
  }
  return moves.reversed.toList();
}

String _key(GameState state) {
  final parts = <String>[
    for (final b in state.branches)
      if (!b.removed) b.birds.join(','),
  ]..sort();
  return parts.join('|');
}

int _heuristic(GameState state) {
  var h = 0;
  final colours = <int>{};
  for (final b in state.branches) {
    if (b.removed || b.isEmpty) continue;
    var segments = 1;
    for (var i = 1; i < b.birds.length; i++) {
      if (b.birds[i] != b.birds[i - 1]) segments++;
    }
    h += segments - 1;
    colours.addAll(b.birds);
  }
  return h + colours.length;
}

/// Minimal binary min-heap on `f` (ties broken by larger `g`, which prefers
/// deeper nodes and speeds up the endgame).
class _Heap {
  final _items = <_Node>[];

  bool get isNotEmpty => _items.isNotEmpty;

  static bool _less(_Node a, _Node b) =>
      a.f != b.f ? a.f < b.f : a.g > b.g;

  void push(_Node n) {
    _items.add(n);
    var i = _items.length - 1;
    while (i > 0) {
      final p = (i - 1) >> 1;
      if (_less(_items[i], _items[p])) {
        final t = _items[p];
        _items[p] = _items[i];
        _items[i] = t;
        i = p;
      } else {
        break;
      }
    }
  }

  _Node pop() {
    final top = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = 2 * i + 2;
        var m = i;
        if (l < _items.length && _less(_items[l], _items[m])) m = l;
        if (r < _items.length && _less(_items[r], _items[m])) m = r;
        if (m == i) break;
        final t = _items[m];
        _items[m] = _items[i];
        _items[i] = t;
        i = m;
      }
    }
    return top;
  }
}
