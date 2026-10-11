import 'dart:math';

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

  /// A complete legal path retained as a generation witness.
  final List<List<int>> solution;
  MahjongBoard._(this.tiles, this.removed, this.history, this.solution);

  factory MahjongBoard.deal(int seed) {
    final slots = <GardenTile>[];
    for (var layer = 0; layer < 3; layer++) {
      for (var y = layer; y < 5 - layer; y++) {
        for (var x = layer; x < 6 - layer; x++) {
          slots.add(GardenTile(slots.length, x, y, layer, 0));
        }
      }
    }
    final board = MahjongBoard._(slots, {}, [], []);
    final random = Random(seed);
    final faces = List.filled(slots.length, 0);
    var pair = 0;
    while (board.remaining > 0) {
      final free = slots.where((t) => board.isFree(t.id)).toList()
        ..shuffle(random);
      // Remove mirrored endpoints to preserve an even, removable geometry.
      // Arbitrary pairs can strand a lone tile above its own partner.
      final a = free.first;
      final b = free.firstWhere(
        (t) => t.layer == a.layer && t.y == a.y && t.x == 5 - a.x,
      );
      board.solution.add([a.id, b.id]);
      faces[a.id] = faces[b.id] = pair++ % 11;
      board.removed.addAll([a.id, b.id]);
    }
    return MahjongBoard._(
      [for (final t in slots) GardenTile(t.id, t.x, t.y, t.layer, faces[t.id])],
      {},
      [],
      List.unmodifiable(board.solution.map((p) => List<int>.unmodifiable(p))),
    );
  }

  int get remaining => tiles.length - removed.length;
  bool get won => remaining == 0;
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
        if (free[i].face == free[j].face) return [free[i].id, free[j].id];
      }
    }
    return null;
  }

  bool match(int a, int b) {
    if (a == b || !isFree(a) || !isFree(b) || tiles[a].face != tiles[b].face) {
      return false;
    }
    removed.addAll([a, b]);
    history.add([a, b]);
    return true;
  }

  bool undo() {
    if (history.isEmpty) return false;
    removed.removeAll(history.removeLast());
    return true;
  }
}
