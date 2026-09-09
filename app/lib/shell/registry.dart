import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

/// Pairs a [GameDefinition] with the widgets that play it.
/// Adding a game to the app = adding one entry to [GameRegistry].
class GameEntry {
  final GameDefinition definition;
  final Widget Function(BuildContext context, int levelIndex) buildPlayScreen;
  final Widget Function(BuildContext context) buildLevelSelect;

  /// Optional game-owned landing screen; otherwise open its level picker.
  final WidgetBuilder? buildHomeScreen;

  /// Game-owned artwork displayed inside the shared library card.
  final WidgetBuilder? buildPreview;
  final String subtitle;
  final String category;
  final Color accentColor;

  const GameEntry({
    required this.definition,
    required this.buildPlayScreen,
    required this.buildLevelSelect,
    this.buildHomeScreen,
    this.buildPreview,
    this.subtitle = 'A little challenge for your next break.',
    this.category = 'Puzzle',
    this.accentColor = const Color(0xFF62609B),
  });
}

class GameRegistry {
  final List<GameEntry> games;

  const GameRegistry(this.games);
}

/// Maps game_core's Flutter-free icon names to real icons.
IconData iconFor(String iconName) => switch (iconName) {
  'bird' => Icons.flutter_dash,
  _ => Icons.extension,
};
