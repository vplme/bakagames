import 'deals.dart';

class GardenTile {
  final int id, x, y, layer, face;
  const GardenTile(this.id, this.x, this.y, this.layer, this.face);
}

/// Layered Mahjong solitaire. Deals are assigned in a legal removal order,
/// so every initial board has a complete solution.
class MahjongBoard {
  final List<GardenTile> tiles;
  final Set<int> removed;
  final List<List<int>> history;
  final List<int> lanternTargets;
  final List<int> _lanternHistory = [];
  int lanternProgress = 0;

  /// A complete legal path retained as a generation witness.
  final List<List<int>> solution;
  MahjongBoard._(
    this.tiles,
    this.removed,
    this.history,
    this.solution,
    this.lanternTargets,
  );

  /// A validated, pre-generated deal: loading never runs search on the UI isolate.
  factory MahjongBoard.deal(int seed) {
    final data = mahjongDeals[seed % mahjongDeals.length];
    return MahjongBoard.fromTiles(
      [
        for (var i = 0; i < data.tiles.length; i++)
          GardenTile(
            i,
            data.tiles[i][0],
            data.tiles[i][1],
            data.tiles[i][2],
            data.tiles[i][3],
          ),
      ],
      solution: data.solution,
      lanternTargets: data.lanternTargets,
    );
  }

  /// Also used by the offline generator and rule fixtures.
  factory MahjongBoard.fromTiles(
    List<GardenTile> tiles, {
    List<List<int>> solution = const [],
    List<int> lanternTargets = const [],
  }) {
    if (tiles.isEmpty ||
        tiles.length.isOdd ||
        List.generate(tiles.length, (i) => i).any((i) => tiles[i].id != i)) {
      throw ArgumentError(
        'Tiles need contiguous IDs and an even, nonzero count.',
      );
    }
    if (lanternTargets.toSet().length != lanternTargets.length ||
        lanternTargets.any((id) => id < 0 || id >= tiles.length)) {
      throw ArgumentError('Lantern targets must be distinct tile IDs.');
    }
    return MahjongBoard._(
      List.unmodifiable(tiles),
      {},
      [],
      List.unmodifiable(solution.map((pair) => List<int>.unmodifiable(pair))),
      List.unmodifiable(lanternTargets),
    );
  }

  int get columns => tiles.map((t) => t.x).reduce((a, b) => a > b ? a : b) + 1;
  int get rows => tiles.map((t) => t.y).reduce((a, b) => a > b ? a : b) + 1;
  int get layers =>
      tiles.map((t) => t.layer).reduce((a, b) => a > b ? a : b) + 1;
  int get pairCount => tiles.length ~/ 2;

  List<List<int>> get legalPairs {
    final free = tiles.where((t) => isFree(t.id)).toList();
    return [
      for (var i = 0; i < free.length; i++)
        for (var j = i + 1; j < free.length; j++)
          if (canMatch(free[i].id, free[j].id)) [free[i].id, free[j].id],
    ];
  }

  int get remaining => tiles.length - removed.length;
  bool get won => remaining == 0 && lanternProgress == lanternTargets.length;
  bool isFree(int id) {
    if (id < 0 || id >= tiles.length || removed.contains(id)) return false;
    final tile = tiles[id];
    final live = tiles.where((t) => !removed.contains(t.id));
    if (live.any(
      (t) => t.layer > tile.layer && t.x == tile.x && t.y == tile.y,
    )) {
      return false;
    }
    bool side(int dx) => live.any(
      (t) => t.layer == tile.layer && t.y == tile.y && t.x == tile.x + dx,
    );
    return !side(-1) || !side(1);
  }

  List<int>? get hint {
    final free = tiles.where((t) => isFree(t.id)).toList();
    for (var i = 0; i < free.length; i++) {
      for (var j = i + 1; j < free.length; j++) {
        if (canMatch(free[i].id, free[j].id)) return [free[i].id, free[j].id];
      }
    }
    return null;
  }

  bool _matchingFreeTiles(int a, int b) =>
      a != b && isFree(a) && isFree(b) && tiles[a].face == tiles[b].face;

  // Preview ordered reveals without changing history or lantern credit.
  int? _lanternsAfter(int a, int b) {
    if (lanternTargets.isEmpty) return 0;
    removed.addAll([a, b]);
    try {
      var next = lanternProgress;
      while (next < lanternTargets.length && isFree(lanternTargets[next])) {
        next++;
      }
      if (lanternTargets.skip(next).any(isFree)) return null;
      return next;
    } finally {
      removed.removeAll([a, b]);
    }
  }

  bool canMatch(int a, int b) =>
      _matchingFreeTiles(a, b) && _lanternsAfter(a, b) != null;

  bool match(int a, int b) {
    if (!_matchingFreeTiles(a, b)) return false;
    final next = _lanternsAfter(a, b);
    if (next == null) return false;
    _lanternHistory.add(lanternProgress);
    lanternProgress = next;
    removed.addAll([a, b]);
    history.add([a, b]);
    return true;
  }

  bool undo() {
    if (history.isEmpty) return false;
    removed.removeAll(history.removeLast());
    lanternProgress = _lanternHistory.removeLast();
    return true;
  }
}
