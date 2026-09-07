import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  group('GameProgress', () {
    test('JSON round-trip preserves everything', () {
      final p = GameProgress(highestUnlocked: 7, results: {
        0: const LevelResult(completed: true, bestMoves: 12),
        3: const LevelResult(completed: true, bestMoves: 30),
        7: const LevelResult(completed: false),
      });
      final decoded = GameProgress.fromJson(
          jsonDecode(jsonEncode(p.toJson())) as Map<String, Object?>);
      expect(decoded, equals(p));
      expect(decoded.results[0]!.bestMoves, 12);
    });

    test('fromJson tolerates empty/garbage blobs', () {
      expect(GameProgress.fromJson(const {}).highestUnlocked, 0);
      expect(
          GameProgress.fromJson(const {'results': 'nope'}).results, isEmpty);
    });

    test('withCompleted unlocks the next level and keeps best moves', () {
      var p = GameProgress();
      p = p.withCompleted(0, 20);
      expect(p.highestUnlocked, 1);
      expect(p.results[0], const LevelResult(completed: true, bestMoves: 20));
      p = p.withCompleted(0, 25); // worse — best stays
      expect(p.results[0]!.bestMoves, 20);
      expect(p.highestUnlocked, 1);
      p = p.withCompleted(0, 15); // better — best improves
      expect(p.results[0]!.bestMoves, 15);
      expect(p.completedCount, 1);
    });
  });
}
