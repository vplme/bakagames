import 'package:baka_games/games/match_three/match_three_game.dart';
import 'package:baka_games/shell/settings.dart';
import 'package:baka_games/games/match_three/sweets_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:match_three/match_three.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class RecordingSettings extends AppSettings {
  final sounds = <String>[];
  @override
  Future<void> playSound(String asset) async => sounds.add(asset);
}

class MemoryStore implements ProgressStore {
  GameProgress progress = GameProgress();
  bool fail = false;
  @override
  Future<GameProgress> load(String id) async => progress;
  @override
  Future<void> save(String id, GameProgress value) async {
    if (fail) throw StateError('disk unavailable');
    progress = value;
  }
}

Future<void> settleWorker(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  Future<void> open(
    WidgetTester tester,
    MemoryStore store, {
    bool compact = false,
    bool reduced = true,
    bool systemReduced = false,
    int levelIndex = 0,
    AppSettings? audioSettings,
  }) async {
    final settings = audioSettings ?? AppSettings();
    settings.reducedMotion.value = reduced;
    settings.soundOn.value = false;
    settings.hapticsOn.value = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: systemReduced,
            size: compact ? const Size(320, 568) : const Size(800, 600),
            textScaler: TextScaler.linear(compact ? 1.3 : 1),
          ),
          child: MatchThreePlayScreen(
            store: store,
            settings: settings,
            levelIndex: levelIndex,
          ),
        ),
      ),
    );
    await settleWorker(tester);
  }

  testWidgets('late campaign displays all unlocked collection goals', (
    tester,
  ) async {
    await open(tester, MemoryStore(), levelIndex: 75, compact: true);
    expect(find.bySemanticsLabel(RegExp('Caramel diamond:.*')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Raspberry ring:.*')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Peach twist:.*')), findsOneWidget);
    await tester.ensureVisible(find.text('Restart'));
    await tester.tap(find.text('Restart'));
    await settleWorker(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap swap, hint, undo and restart', (tester) async {
    await open(tester, MemoryStore());
    final move = MatchThree().hint()!;
    await tester.ensureVisible(find.text('Hint'));
    await tester.tap(find.text('Hint'));
    await settleWorker(tester);
    expect(find.text('Swap the two highlighted sweets.'), findsOneWidget);
    await tester.ensureVisible(find.byKey(ValueKey('sweet-cell-${move.$1}')));
    await tester.tap(find.byKey(ValueKey('sweet-cell-${move.$1}')));
    await tester.tap(find.byKey(ValueKey('sweet-cell-${move.$2}')));
    await settleWorker(tester);
    expect(find.text('Moves: 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Undo'));
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(find.text('Moves: 0'), findsOneWidget);
    await tester.tap(find.text('Restart'));
    await settleWorker(tester);
    expect(find.text('A fresh start!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'gameplay header opens settings and uses ordered circular controls',
    (tester) async {
      await open(tester, MemoryStore());
      expect(find.text('POCKET SWEETS'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Sound'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Moves: 0'), findsOneWidget);
      await tester.ensureVisible(find.text('Hint'));
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.text('Undo')).dx,
        lessThan(tester.getCenter(find.text('Restart')).dx),
      );
      expect(
        tester.getCenter(find.text('Restart')).dx,
        lessThan(tester.getCenter(find.text('Hint')).dx),
      );
    },
  );

  testWidgets('swipe resolves a legal move', (tester) async {
    await open(tester, MemoryStore());
    final move = MatchThree().hint()!;
    final first = find.byKey(ValueKey('sweet-cell-${move.$1}'));
    await tester.ensureVisible(first);
    await tester.drag(
      first,
      move.$2 - move.$1 == 1 ? const Offset(55, 0) : const Offset(0, 55),
    );
    await settleWorker(tester);
    expect(find.text('Moves: 1'), findsOneWidget);
  });

  testWidgets('compact enlarged text remains usable', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester, MemoryStore(), compact: true);
    await tester.ensureVisible(find.text('Restart'));
    await tester.tap(find.text('Restart'));
    await settleWorker(tester);
    expect(tester.takeException(), isNull);
    final slide = find.byTooltip('Show right side of board');
    await tester.ensureVisible(slide);
    await tester.tap(slide);
    await tester.pumpAndSettle();
    final last = find.byKey(const ValueKey('sweet-cell-48'));
    expect(tester.getCenter(last).dx, lessThan(320));
    await tester.tap(last);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'normal motion blocks overlapping moves and undo during resolution',
    (tester) async {
      final audio = RecordingSettings();
      await open(tester, MemoryStore(), reduced: false, audioSettings: audio);
      final move = MatchThree().hint()!;
      final a = find.byKey(ValueKey('sweet-cell-${move.$1}'));
      final b = find.byKey(ValueKey('sweet-cell-${move.$2}'));
      await tester.ensureVisible(a);
      await tester.tap(a);
      await tester.tap(b);
      await tester.pump();
      expect(find.text('Collecting…'), findsOneWidget);
      await tester.tap(a);
      await tester.tap(b);
      final undo = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'Undo',
        ),
      );
      expect(undo.onPressed, isNull);
      var sawBurst = false;
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 170)),
        );
        await tester.pump(const Duration(milliseconds: 170));
        sawBurst = sawBurst || find.byType(SugarBurst).evaluate().isNotEmpty;
      }
      final engine = MatchThree();
      final steps = engine.swap(move.$1, move.$2);
      final waves = steps.where((step) => step.kind == 'clear').length;
      expect(audio.sounds, [
        for (var wave = 1; wave <= waves; wave++)
          wave == 1
              ? 'sweets/match.wav'
              : 'sweets/cascade_${(wave - 1).clamp(1, 5)}.wav',
        if (engine.won) 'sweets/complete.wav',
      ]);
      expect(sawBurst, isTrue);
      expect(find.byType(SugarBurst), findsNothing);
      expect(find.text('Moves: 1'), findsOneWidget);
      expect(find.text('Collecting…'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'system reduced motion resolves instantly with app motion enabled',
    (tester) async {
      await open(tester, MemoryStore(), reduced: false, systemReduced: true);
      final move = MatchThree().hint()!;
      await tester.ensureVisible(find.byKey(ValueKey('sweet-cell-${move.$1}')));
      await tester.tap(find.byKey(ValueKey('sweet-cell-${move.$1}')));
      await tester.tap(find.byKey(ValueKey('sweet-cell-${move.$2}')));
      await settleWorker(tester);
      expect(find.text('Moves: 1'), findsOneWidget);
      expect(find.text('Collecting…'), findsNothing);
      expect(find.byType(SugarBurst), findsNothing);
    },
  );

  for (final compact in [false, true]) {
    testWidgets(
      'completion overlay retries save and advances (compact: $compact)',
      (tester) async {
        if (compact) {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
        }
        final store = MemoryStore()..fail = true;
        await open(tester, store, compact: compact);
        final engine = MatchThree();
        for (var turn = 0; turn < 100 && !engine.won; turn++) {
          final move = engine.hint()!;
          await tester.ensureVisible(
            find.byKey(ValueKey('sweet-cell-${move.$1}')),
          );
          await tester.tap(find.byKey(ValueKey('sweet-cell-${move.$1}')));
          await tester.ensureVisible(
            find.byKey(ValueKey('sweet-cell-${move.$2}')),
          );
          await tester.tap(find.byKey(ValueKey('sweet-cell-${move.$2}')));
          await settleWorker(tester);
          engine.swap(move.$1, move.$2);
        }
        expect(engine.won, isTrue);
        expect(find.text('Progress could not be saved.'), findsOneWidget);
        expect(find.text('Back to levels'), findsNothing);
        expect(find.text('Next level'), findsNothing);
        store.fail = false;
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Retry save').hitTestable(), findsOneWidget);
        await tester.tap(find.text('Retry save'));
        await tester.pumpAndSettle();
        expect(store.progress.completedCount, 1);
        expect(find.text('Back to levels'), findsOneWidget);
        expect(find.text('Next level').hitTestable(), findsOneWidget);
        await tester.tap(find.byTooltip('Back to board'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
        await tester.ensureVisible(find.text('Show completion'));
        await tester.tap(find.text('Show completion'));
        await tester.pumpAndSettle();
        expect(find.text('Next level').hitTestable(), findsOneWidget);
        await tester.tap(find.text('Next level'));
        await settleWorker(tester);
        expect(find.text('Level 2'), findsOneWidget);
        expect(find.text('MINT MEADOW'), findsOneWidget);
        expect(find.text('Moves: 0'), findsOneWidget);
      },
    );
  }
}
