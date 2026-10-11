import 'package:flutter_test/flutter_test.dart';
import 'package:baka_games/games/mahjong/model.dart';
import 'package:baka_games/games/solitaire/model.dart';

void main() {
  test('every garden deal has a legal full solution and undo restores it', () {
    for (var seed = 0; seed < 30; seed++) {
      final b = MahjongBoard.deal(seed);
      expect(b.tiles.length, 44);
      expect(b.isFree(14), isFalse);
      expect(b.match(0, 0), isFalse);
      for (final pair in b.solution) {
        expect(b.match(pair[0], pair[1]), isTrue, reason: 'deal $seed');
      }
      expect(b.won, isTrue);
      expect(b.history.length, 22);
      while (b.undo()) {}
      expect(b.remaining, 44);
      expect(b.hint, isNotNull);
    }
  });

  test(
    'Klondike deals contain exactly 52 distinct cards and correct hidden counts',
    () {
      for (var seed = 0; seed < 30; seed++) {
        final b = SolitaireBoard.deal(seed);
        expect(
          [
            ...b.stock,
            ...b.columns.expand((c) => c),
          ].map((c) => c.id).toSet().length,
          52,
        );
        expect(b.stock.length, 24);
        expect(b.hidden, [0, 1, 2, 3, 4, 5, 6]);
        expect(b.columns.map((c) => c.length), [1, 2, 3, 4, 5, 6, 7]);
        expect(b.cards(const CardSource(6, 0)), isEmpty);
      }
    },
  );

  test('stock recycles in order and draw/recycle undo precisely', () {
    final b = SolitaireBoard.deal(7);
    final initial = b.stock.map((c) => c.id).toList();
    for (var i = 0; i < 24; i++) {
      expect(b.draw(), isTrue);
    }
    expect(b.stock, isEmpty);
    expect(b.draw(), isTrue);
    expect(b.stock.map((c) => c.id), initial);
    expect(b.waste, isEmpty);
    expect(b.undo(), isTrue);
    expect(b.stock, isEmpty);
    expect(b.waste.length, 24);
    for (var i = 0; i < 24; i++) {
      b.undo();
    }
    expect(b.stock.map((c) => c.id), initial);
    expect(b.moves, 0);
  });

  SolitaireBoard empty() {
    final b = SolitaireBoard.deal(0);
    b.columns = List.generate(7, (_) => []);
    b.hidden = List.filled(7, 0);
    b.stock = [];
    b.waste = [];
    return b;
  }

  test(
    'stack moves obey alternating colors and ranks, and reveal is undone',
    () {
      final b = empty();
      b.columns[0] = [
        const MoonCard(3, 2),
        const MoonCard(1, 12),
        const MoonCard(0, 11),
      ];
      b.hidden[0] = 1;
      b.columns[1] = [const MoonCard(3, 13)];
      b.columns[2] = [const MoonCard(2, 13)];
      expect(b.move(const CardSource(0, 1), 2), isFalse);
      expect(b.move(const CardSource(0, 1), 3), isFalse);
      expect(b.move(const CardSource(0, 1), 1), isTrue);
      expect(b.columns[1].map((c) => c.rank), [13, 12, 11]);
      expect(b.hidden[0], 0);
      b.undo();
      expect(b.hidden[0], 1);
      expect(b.columns[0].length, 3);
      expect(b.columns[1].length, 1);
    },
  );

  test('moon pocket holds only one exposed card and can return it to play', () {
    final b = empty();
    b.columns[0] = [const MoonCard(0, 13), const MoonCard(1, 12)];
    expect(b.move(const CardSource(0, 0), 8), isFalse);
    expect(b.move(const CardSource(0, 1), 8), isTrue);
    expect(b.move(const CardSource(0), 8), isFalse);
    expect(b.move(const CardSource(8), 0), isTrue);
    expect(b.pocket, isEmpty);
    expect(b.columns[0].length, 2);
    b.undo();
    expect(b.pocket.single.rank, 12);
  });

  test(
    'foundations require suit and sequence and completing all four wins',
    () {
      final b = empty();
      b.waste = [const MoonCard(1, 1)];
      expect(b.move(const CardSource(7), 9), isFalse);
      expect(b.move(const CardSource(7), 10), isTrue);
      b.waste = [const MoonCard(1, 3)];
      expect(b.move(const CardSource(7), 10), isFalse);
      b.foundations = [
        for (var s = 0; s < 4; s++)
          [for (var r = 1; r <= (s == 3 ? 12 : 13); r++) MoonCard(s, r)],
      ];
      b.waste = [const MoonCard(3, 13)];
      expect(b.won, isFalse);
      expect(b.move(const CardSource(7), 12), isTrue);
      expect(b.won, isTrue);
      b.undo();
      expect(b.won, isFalse);
    },
  );
}
