import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:baka_games/games/mahjong/model.dart';
import 'package:baka_games/games/solitaire/model.dart';

void main() {
  test('every garden deal has a legal full solution and undo restores it', () {
    for (var seed = 0; seed < 30; seed++) {
      final b = MahjongBoard.deal(seed);
      expect(b.tiles.length, [24, 32, 40, 48, 56][seed ~/ 6] + (seed % 3) * 2);
      expect(b.tiles.any((t) => !b.isFree(t.id)), isTrue);
      expect(b.match(0, 0), isFalse);
      for (final pair in b.solution) {
        expect(b.match(pair[0], pair[1]), isTrue, reason: 'deal $seed');
      }
      expect(b.won, isTrue);
      expect(b.history.length, b.pairCount);
      while (b.undo()) {}
      expect(b.remaining, b.tiles.length);
      expect(b.hint, isNotNull);
    }
  });

  test(
    'all 30 layouts are distinct, supported and deterministic without mirrored faces',
    () {
      final shapes = <String>{};
      for (var deal = 0; deal < 30; deal++) {
        final a = MahjongBoard.deal(deal), b = MahjongBoard.deal(deal);
        String data(MahjongBoard board) => board.tiles
            .map((t) => '${t.x},${t.y},${t.layer},${t.face}')
            .join(';');
        expect(data(a), data(b));
        expect(a.solution, b.solution);
        shapes.add(a.tiles.map((t) => '${t.x},${t.y},${t.layer}').join(';'));
        expect(a.columns, inInclusiveRange(5, 6));
        expect(a.tiles.map((t) => t.x).reduce(min), 0);
        expect(a.tiles.map((t) => t.y).reduce(min), 0);
        expect(a.rows, inInclusiveRange(5, 6));
        expect(a.layers, [1, 2, 3, 3, 4][deal ~/ 6]);
        for (final tile in a.tiles) {
          expect(tile.face, inInclusiveRange(0, 10));
          if (tile.layer > 0) {
            expect(
              a.tiles.any(
                (t) =>
                    t.x == tile.x && t.y == tile.y && t.layer == tile.layer - 1,
              ),
              isTrue,
            );
          }
        }
        for (var face = 0; face < 11; face++) {
          expect(a.tiles.where((t) => t.face == face).length.isEven, isTrue);
        }
        var mirrors = 0, matchingMirrors = 0;
        for (final left in a.tiles) {
          for (final right in a.tiles) {
            if (left.x < right.x &&
                left.x + right.x == a.columns - 1 &&
                left.y == right.y &&
                left.layer == right.layer) {
              mirrors++;
              if (left.face == right.face) matchingMirrors++;
            }
          }
        }
        expect(
          matchingMirrors / mirrors,
          lessThanOrEqualTo(.25),
          reason: 'Deal ${deal + 1} must not reveal partners by symmetry.',
        );
      }
      expect(shapes.length, 30);
    },
  );

  test('unplanned play gets substantially harder across difficulty bands', () {
    final wins = List.filled(5, 0);
    var recoveredDeadEnd = false;
    for (var deal = 0; deal < 30; deal++) {
      final random = Random(90001 + deal);
      for (var trial = 0; trial < 48; trial++) {
        final board = MahjongBoard.fromTiles(MahjongBoard.deal(deal).tiles);
        while (!board.won) {
          final pairs = board.legalPairs;
          if (pairs.isEmpty) break;
          final pair = pairs[random.nextInt(pairs.length)];
          expect(board.match(pair[0], pair[1]), isTrue);
        }
        if (board.won) {
          wins[deal ~/ 6]++;
        } else if (deal >= 24 && !recoveredDeadEnd) {
          final remaining = board.remaining;
          expect(board.undo(), isTrue);
          expect(board.remaining, remaining + 2);
          expect(board.hint, isNotNull);
          recoveredDeadEnd = true;
        }
      }
    }
    expect(wins.first / 288, greaterThan(.7));
    expect(wins.last / 288, lessThan(.3));
    for (var tier = 1; tier < 5; tier++) {
      expect(
        wins[tier],
        lessThan(wins[tier - 1]),
        reason: 'Independent random-play wins by tier: $wins',
      );
    }
    expect(recoveredDeadEnd, isTrue);
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
