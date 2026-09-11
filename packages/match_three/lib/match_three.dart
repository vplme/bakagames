/// Flutter-independent, deterministic match-three rules.
library;

enum Special { none, row, column, color }

enum SpecialRules { none, lines, all }

class Sweet {
  final int id;
  final int type;
  final Special special;
  const Sweet(this.id, this.type, [this.special = Special.none]);
}

class Snapshot {
  final List<Sweet?> board;
  final List<int> collected;
  final int moves;
  final int randomState;
  final int nextId;
  Snapshot(
    List<Sweet?> board,
    List<int> collected,
    this.moves,
    this.randomState,
    this.nextId,
  ) : board = List.unmodifiable(board),
      collected = List.unmodifiable(collected);
}

class ResolutionStep {
  final String kind;
  final Snapshot state;
  const ResolutionStep(this.kind, this.state);
}

class MatchThree {
  static const size = 7;
  static const types = 5;
  final int seed;
  final SpecialRules specials;
  final List<Sweet>? opening;
  final List<int> targets;
  late List<Sweet?> _board;
  List<int> _collected = List.filled(types, 0);
  int _moves = 0;
  late int _random;
  int _nextId = 0;
  final List<Snapshot> _history = [];

  MatchThree({
    this.seed = 731,
    List<int>? targets,
    this.specials = SpecialRules.none,
    List<Sweet>? opening,
  }) : opening = opening == null ? null : List.unmodifiable(opening),
       targets = List.unmodifiable(targets ?? [12, 12, 12, 0, 0]) {
    if (this.targets.length != types || this.targets.any((n) => n < 0)) {
      throw ArgumentError('Expected five nonnegative targets');
    }
    if (opening != null &&
        (opening.length != size * size ||
            opening.map((p) => p.id).toSet().length != size * size ||
            opening.any((p) => p.id < 0 || p.type < 0 || p.type >= types) ||
            matches(opening).isNotEmpty)) {
      throw ArgumentError('An opening needs 49 unique pieces and no matches');
    }
    restart();
  }

  Snapshot get state => Snapshot(_board, _collected, _moves, _random, _nextId);
  bool get won =>
      List.generate(types, (i) => i).every((i) => _collected[i] >= targets[i]);
  bool get canUndo => _history.isNotEmpty;

  int _roll(int limit) {
    _random = (1664525 * _random + 1013904223) & 0xffffffff;
    return (_random >> 8) % limit;
  }

  void restart() {
    _random = seed & 0xffffffff;
    _nextId = 0;
    _moves = 0;
    _collected = List.filled(types, 0);
    _history.clear();
    if (opening case final pieces?) {
      _board = List<Sweet?>.of(pieces);
      _nextId = pieces.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
      if (hint() == null) _freshBoard();
    } else {
      _freshBoard();
    }
  }

  // Bounded generation with a guaranteed legal swap in the fallback pattern.
  void _freshBoard() {
    for (var attempt = 0; attempt < 100; attempt++) {
      _board = List.filled(size * size, null);
      for (var i = 0; i < _board.length; i++) {
        final options = List.generate(types, (t) => t)
          ..removeWhere(
            (t) =>
                (i % size >= 2 &&
                    _board[i - 1]?.type == t &&
                    _board[i - 2]?.type == t) ||
                (i >= size * 2 &&
                    _board[i - size]?.type == t &&
                    _board[i - size * 2]?.type == t),
          );
        _board[i] = Sweet(_nextId++, options[_roll(options.length)]);
      }
      if (hint() != null) return;
    }
    _board = List.generate(
      size * size,
      (i) => Sweet(_nextId++, (i ~/ size + i % size) % types),
    );
    for (final e in {0: 0, 1: 1, 2: 0, 8: 0}.entries) {
      _board[e.key] = Sweet(_nextId++, e.value);
    }
  }

  static bool adjacent(int a, int b) =>
      a >= 0 &&
      b >= 0 &&
      a < size * size &&
      b < size * size &&
      ((a ~/ size == b ~/ size && (a - b).abs() == 1) || (a - b).abs() == size);

  static List<List<int>> _runs(List<Sweet?> board) {
    final result = <List<int>>[];
    for (var i = 0; i < size * size; i++) {
      final type = board[i]?.type;
      if (type == null) continue;
      for (final stride in [1, size]) {
        final previous = i - stride;
        if (previous >= 0 &&
            (stride == size || previous ~/ size == i ~/ size) &&
            board[previous]?.type == type)
          continue;
        final run = <int>[i];
        for (
          var j = i + stride;
          j < size * size &&
              (stride == size || j ~/ size == i ~/ size) &&
              board[j]?.type == type;
          j += stride
        ) {
          run.add(j);
        }
        if (run.length >= 3) result.add(run);
      }
    }
    return result;
  }

  static Set<int> matches(List<Sweet?> board) =>
      _runs(board).expand((r) => r).toSet();

  // One creation per connected match. Longest run wins; row-major breaks ties.
  Map<int, Special> _creations(List<List<int>> runs, List<int> preferred) {
    if (specials == SpecialRules.none) return {};
    final remaining = runs.toList();
    final result = <int, Special>{};
    while (remaining.isNotEmpty) {
      final group = [remaining.removeAt(0)];
      final cells = group.first.toSet();
      bool added;
      do {
        added = false;
        for (final run in remaining.toList()) {
          if (run.any(cells.contains)) {
            group.add(run);
            cells.addAll(run);
            remaining.remove(run);
            added = true;
          }
        }
      } while (added);
      group.sort((a, b) {
        final length = b.length.compareTo(a.length);
        return length != 0 ? length : a.first.compareTo(b.first);
      });
      final run = group.first;
      if (run.length < 4) continue;
      final candidates = [
        ...preferred,
        run[run.length ~/ 2],
        ...run,
      ].where((i) => run.contains(i) && _board[i]!.special == Special.none);
      if (candidates.isEmpty) continue;
      result[candidates.first] = run.length >= 5 && specials == SpecialRules.all
          ? Special.color
          : (run[1] - run[0] == 1 ? Special.row : Special.column);
    }
    return result;
  }

  bool _colorSwap(int a, int b) =>
      _board[a]?.special == Special.color ||
      _board[b]?.special == Special.color;

  void _exchange(int a, int b) {
    final temp = _board[a];
    _board[a] = _board[b];
    _board[b] = temp;
  }

  (int, int)? hint() {
    for (var a = 0; a < size * size; a++) {
      for (final b in [a + 1, a + size]) {
        if (!adjacent(a, b)) continue;
        _exchange(a, b);
        final valid = _colorSwap(a, b) || matches(_board).isNotEmpty;
        _exchange(a, b);
        if (valid) return (a, b);
      }
    }
    return null;
  }

  List<ResolutionStep> swap(int a, int b) {
    if (won || !adjacent(a, b)) return const [];
    final before = state;
    _exchange(a, b);
    if (!_colorSwap(a, b) && matches(_board).isEmpty) {
      _exchange(a, b);
      return const [];
    }
    _history.add(before);
    _moves++;
    final steps = [ResolutionStep('swap', state)];
    final colorTargets = <int, int>{};
    if (_board[a]!.special == Special.color) colorTargets[a] = _board[b]!.type;
    if (_board[b]!.special == Special.color) colorTargets[b] = _board[a]!.type;
    for (var cascade = 0; cascade < 100; cascade++) {
      final runs = _runs(_board);
      final cleared = runs.expand((r) => r).toSet();
      if (cascade == 0 && colorTargets.isNotEmpty) cleared.addAll([a, b]);
      if (cleared.isEmpty) break;
      final creations = _creations(runs, cascade == 0 ? [b, a] : []);
      // New specials survive their creation wave, and count only when cleared.
      cleared.removeAll(creations.keys);
      final queue = cleared.toList();
      for (var q = 0; q < queue.length; q++) {
        final i = queue[q];
        final piece = _board[i]!;
        final affected = switch (piece.special) {
          Special.none => <int>[],
          Special.row => List.generate(size, (col) => i ~/ size * size + col),
          Special.column => List.generate(size, (row) => row * size + i % size),
          Special.color => [
            for (var j = 0; j < size * size; j++)
              if (_board[j]?.type ==
                  (cascade == 0 ? colorTargets[i] ?? piece.type : piece.type))
                j,
          ],
        };
        for (final j in affected) {
          if (!creations.containsKey(j) && cleared.add(j)) queue.add(j);
        }
      }
      final activated = cleared.any((i) => _board[i]!.special != Special.none);
      for (final i in cleared) {
        _collected[_board[i]!.type]++;
        _board[i] = null;
      }
      for (final entry in creations.entries) {
        final old = _board[entry.key]!;
        _board[entry.key] = Sweet(old.id, old.type, entry.value);
      }
      if (activated) steps.add(ResolutionStep('special', state));
      if (creations.isNotEmpty) steps.add(ResolutionStep('create', state));
      steps.add(ResolutionStep('clear', state));
      for (var col = 0; col < size; col++) {
        final pieces = [
          for (var row = size - 1; row >= 0; row--)
            if (_board[row * size + col] != null) _board[row * size + col]!,
        ];
        for (var row = size - 1; row >= 0; row--) {
          final offset = size - 1 - row;
          _board[row * size + col] = offset < pieces.length
              ? pieces[offset]
              : null;
        }
      }
      steps.add(ResolutionStep('fall', state));
      for (var i = 0; i < size * size; i++) {
        _board[i] ??= Sweet(_nextId++, _roll(types));
      }
      steps.add(ResolutionStep('refill', state));
    }
    if (matches(_board).isNotEmpty || hint() == null) {
      _freshBoard();
      steps.add(ResolutionStep('reshuffle', state));
    }
    return List.unmodifiable(steps);
  }

  void undo() {
    if (!canUndo) return;
    final prior = _history.removeLast();
    _board = prior.board.toList();
    _collected = prior.collected.toList();
    _moves = prior.moves;
    _random = prior.randomState;
    _nextId = prior.nextId;
  }
}
