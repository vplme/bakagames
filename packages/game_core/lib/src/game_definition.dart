/// Describes a game to the shell. Implemented once per game.
abstract class GameDefinition {
  /// Stable identifier, used as the persistence key. Never change it.
  String get id;

  /// Human-readable title shown on the home screen.
  String get title;

  /// Flutter-free icon descriptor; the app maps it to an [IconData].
  String get iconName;

  /// Number of selectable levels. May be effectively unbounded for
  /// generated games (pick a large finite number for the grid).
  int get levelCount;
}
