import 'package:match_three/match_three.dart';
import 'package:test/test.dart';

List<Object?> fingerprint(Snapshot s) => [
  for (final p in s.board) '${p?.id}:${p?.type}',
  ...s.collected,
  s.moves,
  s.randomState,
  s.nextId,
];

void main() {
  test('openings are stable, match free and playable across seeds', () {
    for (var seed = 0; seed < 100; seed++) {
      final game = MatchThree(seed: seed);
      expect(MatchThree.matches(game.state.board), isEmpty);
      expect(game.hint(), isNotNull);
      expect(
        fingerprint(game.state),
        fingerprint(MatchThree(seed: seed).state),
      );
    }
  });
  test('invalid swaps and hints do not mutate state', () {
    final game = MatchThree();
    final before = fingerprint(game.state);
    game.hint();
    expect(game.swap(6, 7), isEmpty);
    expect(game.swap(-1, 0), isEmpty);
    expect(fingerprint(game.state), before);
    expect(game.canUndo, isFalse);
  });
  test('undo restores randomness and IDs through a complete cascade', () {
    final game = MatchThree();
    final before = fingerprint(game.state);
    final move = game.hint()!;
    final steps = game.swap(move.$1, move.$2);
    expect(
      steps.map((s) => s.kind),
      containsAll(['swap', 'clear', 'fall', 'refill']),
    );
    final after = fingerprint(game.state);
    expect(game.state.moves, 1);
    expect(MatchThree.matches(game.state.board), isEmpty);
    expect(
      game.state.collected.reduce((a, b) => a + b),
      greaterThanOrEqualTo(3),
    );
    game.undo();
    expect(fingerprint(game.state), before);
    game.swap(move.$1, move.$2);
    expect(fingerprint(game.state), after);
    game.restart();
    expect(fingerprint(game.state), before);
  });
  test('intersecting matches count each cell once', () {
    final board = List<Sweet?>.generate(
      49,
      (i) => Sweet(i, (i ~/ 7 + i % 7) % 5),
    );
    for (final i in [15, 16, 17, 9, 23]) {
      board[i] = Sweet(i, 4);
    }
    final matches = MatchThree.matches(board);
    expect(matches.containsAll([15, 16, 17, 9, 23]), isTrue);
  });
  test(
    'repeated legal turns finish collection goals and preserve playable boards',
    () {
      for (var seed = 0; seed < 20; seed++) {
        final game = MatchThree(seed: seed);
        for (var turn = 0; turn < 500 && !game.won; turn++) {
          final move = game.hint()!;
          game.swap(move.$1, move.$2);
          expect(MatchThree.matches(game.state.board), isEmpty);
          expect(
            game.state.board.whereType<Sweet>().map((p) => p.id).toSet().length,
            49,
          );
          expect(game.hint(), isNotNull);
        }
        expect(game.won, isTrue);
        expect(game.swap(0, 1), isEmpty);
      }
    },
  );
}
