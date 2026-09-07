import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [ProgressStore] on shared_preferences: one JSON blob per game id.
class SharedPrefsProgressStore implements ProgressStore {
  final SharedPreferencesAsync _prefs;

  SharedPrefsProgressStore([SharedPreferencesAsync? prefs])
      : _prefs = prefs ?? SharedPreferencesAsync();

  String _key(String gameId) => 'progress.$gameId';

  @override
  Future<GameProgress> load(String gameId) async {
    final raw = await _prefs.getString(_key(gameId));
    if (raw == null) return GameProgress();
    try {
      return GameProgress.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return GameProgress(); // corrupt blob — start fresh rather than crash
    }
  }

  @override
  Future<void> save(String gameId, GameProgress p) =>
      _prefs.setString(_key(gameId), jsonEncode(p.toJson()));
}
