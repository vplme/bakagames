/// Result of one level, as persisted.
class LevelResult {
  final bool completed;

  /// Fewest moves the player has completed the level in, if completed.
  final int? bestMoves;

  const LevelResult({required this.completed, this.bestMoves});

  Map<String, Object?> toJson() => {
        'completed': completed,
        if (bestMoves != null) 'bestMoves': bestMoves,
      };

  factory LevelResult.fromJson(Map<String, Object?> json) => LevelResult(
        completed: json['completed'] as bool? ?? false,
        bestMoves: json['bestMoves'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      other is LevelResult &&
      other.completed == completed &&
      other.bestMoves == bestMoves;

  @override
  int get hashCode => Object.hash(completed, bestMoves);
}

/// Per-game progress. One instance per game id, stored as one JSON blob.
class GameProgress {
  /// Highest unlocked level index (0-based). Level 0 is always unlocked.
  final int highestUnlocked;

  /// Results keyed by level index.
  final Map<int, LevelResult> results;

  GameProgress({this.highestUnlocked = 0, Map<int, LevelResult>? results})
      : results = Map.unmodifiable(results ?? const <int, LevelResult>{});

  /// Progress after finishing [levelIndex] in [moves] moves.
  GameProgress withCompleted(int levelIndex, int moves) {
    final prior = results[levelIndex];
    final best = prior?.bestMoves;
    return GameProgress(
      highestUnlocked: highestUnlocked > levelIndex + 1
          ? highestUnlocked
          : levelIndex + 1,
      results: {
        ...results,
        levelIndex: LevelResult(
          completed: true,
          bestMoves: best == null || moves < best ? moves : best,
        ),
      },
    );
  }

  int get completedCount =>
      results.values.where((r) => r.completed).length;

  Map<String, Object?> toJson() => {
        'highestUnlocked': highestUnlocked,
        'results': {
          for (final e in results.entries) '${e.key}': e.value.toJson(),
        },
      };

  factory GameProgress.fromJson(Map<String, Object?> json) {
    final raw = json['results'];
    return GameProgress(
      highestUnlocked: json['highestUnlocked'] as int? ?? 0,
      results: {
        if (raw is Map<String, Object?>)
          for (final e in raw.entries)
            if (int.tryParse(e.key) != null && e.value is Map<String, Object?>)
              int.parse(e.key):
                  LevelResult.fromJson(e.value as Map<String, Object?>),
      },
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! GameProgress) return false;
    if (other.highestUnlocked != highestUnlocked) return false;
    if (other.results.length != results.length) return false;
    for (final e in results.entries) {
      if (other.results[e.key] != e.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
      highestUnlocked,
      Object.hashAllUnordered(
          results.entries.map((e) => Object.hash(e.key, e.value))));
}

/// Persistence contract implemented by the app (shared_preferences there).
abstract class ProgressStore {
  Future<GameProgress> load(String gameId);
  Future<void> save(String gameId, GameProgress p);
}
