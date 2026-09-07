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
    final store = SharedPrefsProgressStore();
    return BakaGamesApp(
      registry:
          GameRegistry([birdSortEntry(store: store, settings: settings)]),
      store: store,
      settings: settings,
    );
  }

  testWidgets('home lists the registered game and a level can be opened',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Home lists Bird Sort with a progress summary.
    expect(find.text('Baka Games'), findsOneWidget);
    expect(find.text('Bird Sort'), findsOneWidget);
    expect(find.text('Not started'), findsOneWidget);

    // Open level select: level 1 unlocked, level 3 locked.
    await tester.tap(find.text('Bird Sort'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    // Open level 1; the level generates in an isolate.
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 600)));
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Moves: 0'), findsOneWidget);
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
    final p = GameProgress(highestUnlocked: 3, results: {
      2: const LevelResult(completed: true, bestMoves: 9),
    });
    await store.save('bird_sort', p);
    expect(await store.load('bird_sort'), p);
    // Other game ids are unaffected.
    expect((await store.load('other_game')).results, isEmpty);
  });
}
