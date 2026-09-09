import 'package:flutter/widgets.dart';
import 'package:game_core/game_core.dart';

import 'level_select_screen.dart';
import 'aviary_home_screen.dart';
import 'aviary_preview.dart';
import '../../shell/registry.dart';
import '../../shell/settings.dart';
import 'play_screen.dart';

class BirdSortDefinition implements GameDefinition {
  @override
  String get id => 'bird_sort';

  @override
  String get title => 'Pocket Aviary';

  @override
  String get iconName => 'bird';

  /// Levels are generated, so this is just how far the grid reaches.
  @override
  int get levelCount => 500;
}

/// The one line that registers Bird Sort with the shell.
GameEntry birdSortEntry({
  required ProgressStore store,
  required AppSettings settings,
}) {
  final definition = BirdSortDefinition();

  Future<void> saveWin(int levelIndex, int moves) async {
    final p = await store.load(definition.id);
    await store.save(definition.id, p.withCompleted(levelIndex, moves));
  }

  Widget buildPlay(BuildContext context, int levelIndex) => BirdSortPlayScreen(
    levelIndex: levelIndex,
    settings: settings,
    onWon: saveWin,
    store: store,
  );

  late final GameEntry entry;
  entry = GameEntry(
    definition: definition,
    category: 'Color sorting',
    subtitle: 'Bring tiny flocks together in a lush little world.',
    accentColor: const Color(0xFF386B55),
    buildPreview: (_) => const AviaryPreview(),
    buildHomeScreen: (_) =>
        AviaryHomeScreen(entry: entry, store: store, settings: settings),
    buildPlayScreen: buildPlay,
    buildLevelSelect: (context) => AviaryLevelSelectScreen(
      definition: definition,
      store: store,
      buildPlayScreen: buildPlay,
    ),
  );
  return entry;
}
