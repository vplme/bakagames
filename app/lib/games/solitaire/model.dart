import 'dart:math';

class MoonCard {
  final int suit, rank;
  const MoonCard(this.suit, this.rank);
  bool get red => suit == 1 || suit == 2;
  String get symbol => ['♠', '♥', '♦', '♣'][suit];
  String get label =>
      '${switch (rank) {
        1 => 'A',
        11 => 'J',
        12 => 'Q',
        13 => 'K',
        _ => '$rank',
      }}$symbol';
  int get id => suit * 13 + rank - 1;
}

/// Sources: 0–6 tableau, 7 waste, 8 moon pocket, 9–12 foundations.
class CardSource {
  final int pile, index;
  const CardSource(this.pile, [this.index = 0]);
}

class SolitaireBoard {
  List<List<MoonCard>> columns;
  List<int> hidden;
  List<MoonCard> stock, waste, pocket;
  List<List<MoonCard>> foundations;
  int moves;
  final List<SolitaireBoard> _history = [];
  SolitaireBoard._(
    this.columns,
    this.hidden,
    this.stock,
    this.waste,
    this.pocket,
    this.foundations,
    this.moves,
  );

  factory SolitaireBoard.deal([int? seed]) {
    final deck = [
      for (var s = 0; s < 4; s++)
        for (var r = 1; r <= 13; r++) MoonCard(s, r),
    ]..shuffle(Random(seed));
    final columns = <List<MoonCard>>[];
    for (var i = 0; i < 7; i++) {
      columns.add([for (var j = 0; j <= i; j++) deck.removeLast()]);
    }
    return SolitaireBoard._(
      columns,
      List.generate(7, (i) => i),
      deck,
      [],
      [],
      List.generate(4, (_) => []),
      0,
    );
  }
  bool get won => foundations.every((f) => f.length == 13);
  bool get canUndo => _history.isNotEmpty;
  int get gathered => foundations.fold(0, (n, p) => n + p.length);
  SolitaireBoard _copy() => SolitaireBoard._(
    [
      for (final c in columns) [...c],
    ],
    [...hidden],
    [...stock],
    [...waste],
    [...pocket],
    [
      for (final f in foundations) [...f],
    ],
    moves,
  );
  void _remember() {
    _history.add(_copy());
    moves++;
  }

  bool undo() {
    if (_history.isEmpty) return false;
    final b = _history.removeLast();
    columns = b.columns;
    hidden = b.hidden;
    stock = b.stock;
    waste = b.waste;
    pocket = b.pocket;
    foundations = b.foundations;
    moves = b.moves;
    return true;
  }

  bool draw() {
    if (won || (stock.isEmpty && waste.isEmpty)) return false;
    _remember();
    if (stock.isEmpty) {
      stock = waste.reversed.toList();
      waste = [];
    } else {
      waste.add(stock.removeLast());
    }
    return true;
  }

  List<MoonCard> pile(int id) => id < 7
      ? columns[id]
      : id == 7
      ? waste
      : id == 8
      ? pocket
      : foundations[id - 9];
  List<MoonCard> cards(CardSource source) {
    if (source.pile < 0 || source.pile > 12) return [];
    final p = pile(source.pile);
    if (source.index < 0 || source.index >= p.length) return [];
    if (source.pile < 7) {
      if (source.index < hidden[source.pile]) return [];
      for (var i = source.index; i < p.length - 1; i++) {
        if (p[i].red == p[i + 1].red || p[i].rank != p[i + 1].rank + 1) {
          return [];
        }
      }
    } else if (source.index != p.length - 1) {
      return [];
    }
    return p.sublist(source.index);
  }

  bool canMove(CardSource source, int destination) {
    if (won ||
        destination < 0 ||
        destination > 12 ||
        destination == 7 ||
        source.pile == destination) {
      return false;
    }
    final moving = cards(source);
    if (moving.isEmpty) return false;
    final target = pile(destination), card = moving.first;
    if (destination == 8) {
      return target.isEmpty && moving.length == 1 && source.pile < 9;
    }
    if (destination >= 9) {
      return moving.length == 1 &&
          card.suit == destination - 9 &&
          card.rank == target.length + 1;
    }
    return target.isEmpty
        ? card.rank == 13
        : target.last.red != card.red && target.last.rank == card.rank + 1;
  }

  bool move(CardSource source, int destination) {
    if (!canMove(source, destination)) return false;
    _remember();
    final from = pile(source.pile), moving = from.sublist(source.index);
    from.removeRange(source.index, from.length);
    pile(destination).addAll(moving);
    if (source.pile < 7 &&
        hidden[source.pile] > 0 &&
        from.length == hidden[source.pile]) {
      hidden[source.pile]--;
    }
    return true;
  }

  (CardSource, int)? get hint {
    final sources = <CardSource>[
      for (var i = 0; i < 9; i++)
        for (
          var j = i < 7 ? hidden[i] : pile(i).length - 1;
          j < pile(i).length;
          j++
        )
          if (j >= 0) CardSource(i, j),
    ];
    for (final destination in [9, 10, 11, 12, 0, 1, 2, 3, 4, 5, 6, 8]) {
      for (final source in sources) {
        if (destination < 7 &&
            source.pile < 7 &&
            source.index == 0 &&
            columns[destination].isEmpty) {
          continue;
        }
        if (canMove(source, destination)) return (source, destination);
      }
    }
    return null;
  }
}
