/// Which side of the trunk a branch attaches to. Cosmetic — gameplay treats
/// all branches identically.
enum Side { left, right }

bool _listEquals(List<int> a, List<int> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// One branch on the tree. [birds] is ordered trunk→tip (colour ids).
class Branch {
  final Side side;
  final List<int> birds;
  final bool removed;

  Branch({required this.side, required List<int> birds, this.removed = false})
      : birds = List.unmodifiable(birds);

  bool get isEmpty => birds.isEmpty;

  /// Colour at the tip, or null when empty.
  int? get tipColour => birds.isEmpty ? null : birds.last;

  /// Size of the linked group: the maximal same-colour run ending at the tip.
  int get linkedGroupSize {
    if (birds.isEmpty) return 0;
    final colour = birds.last;
    var n = 0;
    for (var i = birds.length - 1; i >= 0 && birds[i] == colour; i--) {
      n++;
    }
    return n;
  }

  Branch copyWith({List<int>? birds, bool? removed}) => Branch(
        side: side,
        birds: birds ?? this.birds,
        removed: removed ?? this.removed,
      );

  @override
  bool operator ==(Object other) =>
      other is Branch &&
      other.side == side &&
      other.removed == removed &&
      _listEquals(other.birds, birds);

  @override
  int get hashCode => Object.hash(side, removed, Object.hashAll(birds));

  @override
  String toString() =>
      'Branch(${side.name}, $birds${removed ? ', removed' : ''})';
}

/// Immutable level definition: the initial layout plus ruleset flags.
class Level {
  final int capacity;
  final List<Branch> branches;
  final bool removeBranchOnComplete;
  final bool partialMovesAllowed;
  final int seed;

  Level({
    required this.capacity,
    required List<Branch> branches,
    required this.removeBranchOnComplete,
    this.partialMovesAllowed = true,
    this.seed = 0,
  }) : branches = List.unmodifiable(branches);

  int get colourCount =>
      branches.expand((b) => b.birds).toSet().length;

  @override
  bool operator ==(Object other) {
    if (other is! Level ||
        other.capacity != capacity ||
        other.removeBranchOnComplete != removeBranchOnComplete ||
        other.partialMovesAllowed != partialMovesAllowed ||
        other.seed != seed ||
        other.branches.length != branches.length) {
      return false;
    }
    for (var i = 0; i < branches.length; i++) {
      if (other.branches[i] != branches[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(capacity, removeBranchOnComplete,
      partialMovesAllowed, seed, Object.hashAll(branches));
}

/// A move of [count] birds from branch [from] to branch [to].
class Move {
  final int from;
  final int to;
  final int count;

  const Move({required this.from, required this.to, required this.count});

  @override
  bool operator ==(Object other) =>
      other is Move &&
      other.from == from &&
      other.to == to &&
      other.count == count;

  @override
  int get hashCode => Object.hash(from, to, count);

  @override
  String toString() => 'Move($from→$to ×$count)';
}
