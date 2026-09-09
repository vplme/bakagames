import 'package:baka_games/games/bird_sort/bird_sort_game.dart';
import 'package:baka_games/main.dart';
import 'package:baka_games/shell/progress_store.dart';
import 'package:baka_games/shell/registry.dart';
import 'package:baka_games/shell/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  BakaGamesApp buildApp() {
    final settings = AppSettings();
    settings.reducedMotion.value = true;
    final store = SharedPrefsProgressStore();
    return BakaGamesApp(
      registry: GameRegistry([birdSortEntry(store: store, settings: settings)]),
      store: store,
      settings: settings,
    );
  }

  testWidgets('home lists the registered game and a level can be opened', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Home lists Bird Sort with a progress summary.
    expect(find.text('Baka Games'), findsOneWidget);
    expect(find.text('Pocket Aviary'), findsOneWidget);
    expect(find.text('Ready for your first level'), findsOneWidget);
    expect(find.text('My birds'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('game-card-bird_sort')));
    await tester.pumpAndSettle();
    expect(find.text('All games'), findsOneWidget);
    expect(find.text('Play level 1'), findsOneWidget);
    expect(find.text('Kiwi is getting closer!'), findsOneWidget);
    expect(find.text('3 levels to discover · 3/8 birds'), findsOneWidget);

    // Open level select: level 1 unlocked, level 3 locked.
    await tester.scrollUntilVisible(
      find.text('Level path'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Level path'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    // Open level 1; the level generates in an isolate.
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Moves: 0'), findsOneWidget);
    expect(find.text('Kiwi is getting closer!'), findsNothing);
  });

  testWidgets('library supports another game and returning from its picker', (
    tester,
  ) async {
    final store = SharedPrefsProgressStore();
    final settings = AppSettings();
    await store.save('test_puzzle', GameProgress().withCompleted(0, 7));
    final second = GameEntry(
      definition: _TestGame(),
      buildPlayScreen: (_, _) => const SizedBox.shrink(),
      buildLevelSelect: (_) =>
          Scaffold(appBar: AppBar(title: const Text('Test puzzle levels'))),
    );
    await tester.pumpWidget(
      BakaGamesApp(
        registry: GameRegistry([
          birdSortEntry(store: store, settings: settings),
          second,
        ]),
        store: store,
        settings: settings,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pocket Aviary'), findsOneWidget);
    expect(find.text('Test Puzzle'), findsOneWidget);
    expect(find.text('1 levels completed · Level 2 next'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('game-card-test_puzzle')));
    await tester.pumpAndSettle();
    expect(find.text('Test puzzle levels'), findsOneWidget);
    expect(find.text('My birds'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Baka Games'), findsOneWidget);
  });

  testWidgets('compact library card opens aviary and returns to all games', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Pocket Aviary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pocket Aviary'));
    await tester.pumpAndSettle();
    expect(find.text('All games'), findsOneWidget);
    await tester.tap(find.text('All games'));
    await tester.pumpAndSettle();
    expect(find.text('All games'), findsNothing);
    expect(find.byKey(const ValueKey('game-card-bird_sort')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings screen toggles persist', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Sound'), findsOneWidget);
    await tester.tap(find.text('Haptics'));
    await tester.pumpAndSettle();

    // A fresh AppSettings sees the persisted value.
    final fresh = AppSettings();
    await tester.runAsync(fresh.load);
    expect(fresh.hapticsOn.value, isFalse);
    expect(fresh.soundOn.value, isTrue);
  });

  test('SharedPrefsProgressStore round-trips progress per game id', () async {
    final store = SharedPrefsProgressStore();
    expect((await store.load('bird_sort')).highestUnlocked, 0);
    final p = GameProgress(
      highestUnlocked: 3,
      results: {2: const LevelResult(completed: true, bestMoves: 9)},
    );
    await store.save('bird_sort', p);
    expect(await store.load('bird_sort'), p);
    // Other game ids are unaffected.
    expect((await store.load('other_game')).results, isEmpty);
  });
}

class _TestGame implements GameDefinition {
  @override
  String get id => 'test_puzzle';
  @override
  String get title => 'Test Puzzle';
  @override
  String get iconName => 'puzzle';
  @override
  int get levelCount => 10;
}
