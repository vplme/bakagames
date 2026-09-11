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
    'all 30 levels are deterministic, playable and finish under legal hint play',
    () {
      expect(sweetLevels.length, 30);
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
