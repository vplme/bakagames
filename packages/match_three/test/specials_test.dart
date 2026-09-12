import 'package:match_three/match_three.dart';
import 'package:match_three/levels.dart';
import 'package:test/test.dart';

List<Sweet> fixture(Map<int, Sweet> edits) =>
    List.generate(49, (i) => edits[i] ?? Sweet(i, (i ~/ 7 + i % 7) % 5));
MatchThree game(List<Sweet> board) => MatchThree(
  opening: board,
  specials: SpecialRules.all,
  targets: [999, 999, 999, 999, 999],
);
List<String> signature(MatchThree g) => [
  for (final p in g.state.board) '${p?.id}/${p?.type}/${p?.special}',
  '${g.state.randomState}',
  '${g.state.collected}',
];

void main() {
  test('variety effects stop at board edges without wrapping', () {
    expect(MatchThree.varietyEffect(5, 0), {1, 7});
    expect(MatchThree.varietyEffect(6, 0), {8});
    expect(MatchThree.varietyEffect(7, 6), {4, 5});
    expect(MatchThree.varietyEffect(4, 24), isEmpty);
  });
  for (final type in [5, 6, 7]) {
    test('variety $type clears its footprint once and restores on undo', () {
      final g = MatchThree(
        opening: fixture({
          22: Sweet(22, type),
          24: Sweet(24, type),
          16: Sweet(16, type),
        }),
        targets: List.filled(8, 999),
        specials: SpecialRules.all,
      );
      final before = signature(g);
      final steps = g.swap(16, 23);
      final clear = steps.firstWhere((s) => s.kind == 'clear').state;
      final expected = switch (type) {
        5 => {16, 22, 23, 24, 30},
        6 => {15, 17, 22, 23, 24, 29, 31},
        _ => {21, 22, 23, 24, 25},
      };
      expect({
        for (var i = 0; i < 49; i++)
          if (clear.board[i] == null) i,
      }, expected);
      expect(clear.collected.reduce((a, b) => a + b), expected.length);
      expect(clear.collected[type], 3);
      expect(steps.any((s) => s.kind == 'special'), isTrue);
      final after = signature(g);
      g.undo();
      expect(signature(g), before);
      g.swap(16, 23);
      expect(signature(g), after);
    });
  }

  test('unlock boundaries restrict spawning and preserve undo and restart', () {
    for (final number in [15, 16, 30, 31, 45, 46, 60, 61, 75, 76, 90]) {
      final game = sweetLevels[number - 1].create();
      final expected = number < 46
          ? 5
          : number < 61
          ? 6
          : number < 76
          ? 7
          : 8;
      expect(game.typeCount, expected);
      expect(
        game.specials,
        number <= 15
            ? SpecialRules.none
            : number <= 30
            ? SpecialRules.lines
            : SpecialRules.all,
      );
      final before = signature(game);
      final move = game.hint()!;
      final steps = game.swap(move.$1, move.$2);
      for (final step in steps) {
        expect(step.state.collected.length, expected);
        expect(
          step.state.board.whereType<Sweet>().every((p) => p.type < expected),
          isTrue,
        );
      }
      final after = signature(game);
      game.undo();
      expect(signature(game), before);
      game.swap(move.$1, move.$2);
      expect(signature(game), after);
      game.restart();
      expect(signature(game), before);
    }
  });
  test(
    'four creates a stripe at the destination, preserving its ID and credit',
    () {
      final g = game(
        fixture({
          0: const Sweet(0, 0),
          1: const Sweet(1, 0),
          2: const Sweet(2, 1),
          3: const Sweet(3, 0),
          9: const Sweet(9, 0),
        }),
      );
      final steps = g.swap(9, 2);
      final created = steps.firstWhere((s) => s.kind == 'create').state;
      expect(created.board[2]!.special, Special.row);
      expect(created.board[2]!.id, 9);
      expect(created.collected[0], 3);
      expect(created.board[0], isNull);
      final after = signature(g);
      g.undo();
      expect(g.state.board.every((p) => p!.special == Special.none), isTrue);
      g.swap(9, 2);
      expect(signature(g), after);
    },
  );
  test('vertical four creates a column stripe', () {
    final horizontal = fixture({
      0: const Sweet(0, 0),
      1: const Sweet(1, 0),
      2: const Sweet(2, 1),
      3: const Sweet(3, 0),
      9: const Sweet(9, 0),
    });
    final vertical = List.generate(49, (i) => horizontal[i % 7 * 7 + i ~/ 7]);
    final g = game(vertical);
    final created = g.swap(15, 14).firstWhere((s) => s.kind == 'create').state;
    expect(created.board[14]!.special, Special.column);
  });
  test('five creates a rainbow', () {
    final g = game(
      fixture({
        0: const Sweet(0, 0),
        1: const Sweet(1, 0),
        2: const Sweet(2, 1),
        3: const Sweet(3, 0),
        4: const Sweet(4, 0),
        5: const Sweet(5, 2),
        9: const Sweet(9, 0),
      }),
    );
    final created = g.swap(9, 2).firstWhere((s) => s.kind == 'create').state;
    expect(created.board[2]!.special, Special.color);
    expect(created.collected[0], 4);
  });
  test('rainbow swap clears target color and chains through a stripe', () {
    final board = fixture({
      0: const Sweet(0, 0, Special.color),
      8: const Sweet(8, 1, Special.row),
    });
    final g = game(board);
    expect(g.hint(), (0, 1));
    final steps = g.swap(0, 1);
    final cleared = steps.firstWhere((s) => s.kind == 'clear').state;
    for (var i = 7; i < 14; i++) {
      expect(cleared.board[i], isNull);
    }
    expect(cleared.board[0], isNull);
    expect(cleared.board[1], isNull);
    final removed = cleared.board.where((p) => p == null).length;
    expect(cleared.collected.reduce((a, b) => a + b), removed);
  });
  test(
    'dead authored board recovers reproducibly without collection credit',
    () {
      final dead = fixture({});
      final g = game(dead);
      expect(g.hint(), isNotNull);
      expect(MatchThree.matches(g.state.board), isEmpty);
      expect(g.state.moves, 0);
      expect(g.state.collected, [0, 0, 0, 0, 0]);
      final first = signature(g);
      g.restart();
      expect(signature(g), first);
    },
  );
  test(
    'all 90 levels are deterministic, playable and finish under legal hint play',
    () {
      expect(sweetLevels.length, 90);
      final turns = <int>[];
      for (final level in sweetLevels) {
        final g = level.create();
        expect(signature(g), signature(level.create()));
        expect(MatchThree.matches(g.state.board), isEmpty);
        for (var t = 0; t < 1000 && !g.won; t++) {
          final move = g.hint()!;
          g.swap(move.$1, move.$2);
          expect(MatchThree.matches(g.state.board), isEmpty);
          expect(g.state.board.map((p) => p!.id).toSet().length, 49);
        }
        expect(g.won, isTrue, reason: level.title);
        turns.add(g.state.moves);
      }
      print('Campaign hint-play moves (not a difficulty rating): $turns');
    },
  );
}
