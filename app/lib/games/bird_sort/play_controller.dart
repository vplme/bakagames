import 'package:bird_sort/bird_sort.dart' as engine;
import 'package:flutter/foundation.dart';

/// Where a departed (flown-away) flock left from, for animation direction.
class DepartureInfo {
  final int branchIndex;
  final engine.Side side;

  /// Stable position within this departed flock, retained across later moves.
  final int slot;
  const DepartureInfo(this.branchIndex, this.side, {required this.slot});
}

class _Snapshot {
  final List<List<int>> mirror;
  final Map<int, DepartureInfo> departed;
  _Snapshot(List<List<int>> mirror, Map<int, DepartureInfo> departed)
    : mirror = [for (final b in mirror) List.of(b)],
      departed = Map.of(departed);
}

/// UI-side game controller.
///
/// Holds the engine [engine.GameState] (immutable, single source of rules)
/// plus a *mirror* of per-bird UI identities: `birdIds[branch]` lists stable
/// uids trunk→tip, kept in lockstep with every engine transition so birds
/// can be animated across branches. No gameplay decisions live here.
class PlayController extends ChangeNotifier {
  final engine.Level level;

  late engine.GameState state;

  /// Selected source branch (linked group lifted), or null.
  int? selected;

  /// Per branch: bird uids trunk→tip. Same shape as `state.branches`.
  late List<List<int>> birdIds;

  /// uid → colour id (uids never change colour).
  final Map<int, int> colourOf = {};

  /// Birds that flew away, with where they left from.
  Map<int, DepartureInfo> departed = {};

  /// Bumped on every transition; uid → stagger slot for the birds that just
  /// moved (drives the flight stagger and nothing else).
  int transitionTick = 0;
  Map<int, int> staggerOf = {};

  /// Bumped to trigger a shake on [shakeBranch].
  int shakeTick = 0;
  int? shakeBranch;

  /// The extra-branch booster is once per level; restart does not refund it.
  bool extraBranchUsed = false;

  final List<_Snapshot> _undoStack = [];

  PlayController(this.level) {
    state = engine.GameState.initial(level);
    var uid = 0;
    birdIds = [];
    for (final b in level.branches) {
      final ids = <int>[];
      for (final colour in b.birds) {
        colourOf[uid] = colour;
        ids.add(uid++);
      }
      birdIds.add(ids);
    }
  }

  bool get canUndo => state.history.isNotEmpty;

  int get moveCount => state.moveCount;

  /// Linked-group size of [branch] in the current state (0 when empty).
  int linkedGroup(int branch) => state.branches[branch].linkedGroupSize;

  void tapBranch(int index) {
    if (state.isWon) return;
    final branch = state.branches[index];
    if (selected == null) {
      if (branch.removed || branch.isEmpty) {
        _shake(index);
      } else {
        selected = index;
      }
      notifyListeners();
      return;
    }
    if (selected == index) {
      selected = null;
      notifyListeners();
      return;
    }
    final size = engine.moveSize(state.level, state.branches, selected!, index);
    if (size == null) {
      _shake(index);
      notifyListeners();
      return;
    }
    _apply(engine.Move(from: selected!, to: index, count: size));
  }

  /// Applies a move coming from outside the tap flow (e.g. a solver hint).
  void applyExternalMove(engine.Move move) {
    if (state.isWon) return;
    selected = null;
    _apply(move);
  }

  void _apply(engine.Move move) {
    final next = engine.applyMove(state, move);
    _undoStack.add(_Snapshot(birdIds, departed));

    final from = birdIds[move.from];
    final moving = from.sublist(from.length - move.count);
    birdIds[move.from] = from.sublist(0, from.length - move.count);
    birdIds[move.to] = [...birdIds[move.to], ...moving];

    transitionTick++;
    staggerOf = {for (var i = 0; i < moving.length; i++) moving[i]: i};

    // The engine emptied the destination → that flock flew away.
    if (next.branches[move.to].isEmpty) {
      departed = Map.of(departed);
      var i = 0;
      for (final uid in birdIds[move.to]) {
        departed[uid] = DepartureInfo(
          move.to,
          state.branches[move.to].side,
          slot: i,
        );
        staggerOf[uid] = i++;
      }
      birdIds[move.to] = [];
    }

    state = next;
    selected = null;
    notifyListeners();
  }

  /// The "extra branch" booster. No-op when already used or won.
  void useExtraBranch() {
    if (extraBranchUsed || state.isWon) return;
    _undoStack.add(_Snapshot(birdIds, departed));
    state = engine.addEmptyBranch(state);
    birdIds = [...birdIds, <int>[]];
    extraBranchUsed = true;
    transitionTick++;
    staggerOf = {};
    selected = null;
    notifyListeners();
  }

  void undoMove() {
    if (!canUndo) return;
    state = engine.undo(state);
    final snap = _undoStack.removeLast();
    birdIds = snap.mirror;
    departed = snap.departed;
    transitionTick++;
    staggerOf = {};
    selected = null;
    notifyListeners();
  }

  void restartLevel() {
    if (_undoStack.isEmpty) return;
    state = engine.restart(state);
    final first = _undoStack.first;
    birdIds = first.mirror;
    departed = first.departed;
    _undoStack.clear();
    transitionTick++;
    staggerOf = {};
    selected = null;
    notifyListeners();
  }

  void _shake(int index) {
    shakeBranch = index;
    shakeTick++;
    selected = null;
  }
}
