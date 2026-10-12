import 'package:baka_games/games/mahjong/model.dart';
import 'package:baka_games/shell/home_screen.dart';
import 'package:baka_games/shell/registry.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:baka_games/games/mahjong/mahjong_game.dart';
import 'package:baka_games/games/solitaire/solitaire_game.dart';
import 'package:baka_games/games/shared/table_game.dart';
import 'package:baka_games/shell/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

class MemoryStore implements ProgressStore {
  final data = <String, GameProgress>{};
  bool fail = false;
  @override
  Future<GameProgress> load(String gameId) async =>
      data[gameId] ?? GameProgress();
  @override
  Future<void> save(String gameId, GameProgress progress) async {
    if (fail) throw StateError('Offline');
    data[gameId] = progress;
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  for (final mahjong in [true, false]) {
    testWidgets(
      '${mahjong ? 'Mahjong' : 'Solitaire'} compact board and menu retain state',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final settings = AppSettings()..hapticsOn.value = false;
        final store = MemoryStore();
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: mahjong
                ? MahjongScreen(store: store, settings: settings)
                : SolitaireScreen(store: store, settings: settings),
          ),
        );
        expect(tester.takeException(), isNull);
        if (mahjong) {
          await tester.tap(find.byTooltip('Hint'));
          await tester.pump();
          expect(
            find.text('The golden tiles are a free matching pair.'),
            findsOneWidget,
          );
        } else {
          await tester.tap(find.byKey(const Key('solitaireStock')));
          await tester.pump();
          expect(find.textContaining('Drawn '), findsOneWidget);
        }
        await tester.tap(find.byKey(const Key('gameMenu')));
        await tester.pump();
        expect(find.byKey(const Key('gameMenuPanel')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('gameMenu')));
        await tester.pump();
        if (!mahjong) {
          await tester.tap(find.byTooltip('Undo'));
          await tester.pump();
          expect(
            find.text('One move back. A new possibility.'),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in [
    const Size(390, 844),
    const Size(768, 1024),
    const Size(844, 390),
  ]) {
    for (final mahjong in [true, false]) {
      testWidgets(
        '${mahjong ? 'Mahjong' : 'Solitaire'} uses available board space at $size',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final settings = AppSettings()..hapticsOn.value = false;
          final store = MemoryStore();
          await tester.pumpWidget(
            MaterialApp(
              home: mahjong
                  ? MahjongScreen(store: store, settings: settings)
                  : SolitaireScreen(store: store, settings: settings),
            ),
          );
          final board = find.byKey(
            Key(mahjong ? 'mahjongBoard' : 'solitaireBoard'),
          );
          // Test fonts wrap more widely than device fonts; keep the header
          // within a compact band while allowing its instructions to wrap.
          expect(tester.getRect(board).top, lessThan(180));
          if (size.height > size.width) {
            expect(
              tester.getSize(board).height,
              greaterThan(size.height * .70),
            );
            expect(
              tester.getRect(board).bottom,
              lessThanOrEqualTo(size.height),
            );
          }
          final first = find.byKey(
            Key(mahjong ? 'mahjongTile0' : 'solitaireStock'),
          );
          expect(tester.getSize(first).width, greaterThanOrEqualTo(36));
          final last = find.byKey(
            Key(
              mahjong
                  ? 'mahjongTile${MahjongBoard.deal(0).tiles.length - 1}'
                  : 'solitaireCard6_6',
            ),
          );
          await tester.ensureVisible(last);
          await tester.tap(last);
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('Mahjong can be played through to a saved win', (tester) async {
    final store = MemoryStore();
    final settings = AppSettings()..hapticsOn.value = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MahjongScreen(store: store, settings: settings),
      ),
    );
    for (final pair in MahjongBoard.deal(0).solution) {
      for (final id in pair) {
        final tile = find.byKey(Key('mahjongTile$id'));
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pump();
      }
    }
    await tester.pumpAndSettle();
    expect(find.text('Garden aglow!'), findsOneWidget);
    expect(store.data['mahjong']!.completedCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Solitaire moon pocket moves a card and undo restores the column',
    (tester) async {
      final settings = AppSettings()..hapticsOn.value = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SolitaireScreen(store: MemoryStore(), settings: settings),
        ),
      );
      await tester.tap(find.byKey(const Key('solitaireCard0_0')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('solitairePile8')));
      await tester.pump();
      expect(find.byKey(const Key('solitaireCard0_0')), findsNothing);
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(find.byKey(const Key('solitaireCard0_0')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mahjong in [true, false]) {
    testWidgets(
      '${mahjong ? 'Mahjong' : 'Solitaire'} opens from library through themed home',
      (tester) async {
        final settings = AppSettings()..hapticsOn.value = false;
        final store = MemoryStore();
        final entry = mahjong
            ? mahjongEntry(store: store, settings: settings)
            : solitaireEntry(store: store, settings: settings);
        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(
              registry: GameRegistry([entry]),
              store: store,
              settings: settings,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(entry.definition.title));
        await tester.tap(find.text(entry.definition.title));
        await tester.pumpAndSettle();
        expect(find.text('All games'), findsOneWidget);
        await tester.ensureVisible(find.text('Play deal 1'));
        await tester.tap(find.text('Play deal 1'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('gameMenu')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('completion retries failed save and credits a deal only once', (
    tester,
  ) async {
    final store = MemoryStore()..fail = true;
    final settings = AppSettings();
    Widget screen(bool won) => MaterialApp(
      home: TablePlay(
        id: 'mahjong',
        title: 'Test',
        rules: '',
        status: '',
        deal: 0,
        moves: 22,
        won: won,
        canUndo: false,
        accent: Colors.teal,
        settings: settings,
        store: store,
        undo: () {},
        hint: () {},
        restart: () {},
        next: () {},
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(screen(false));
    await tester.pumpWidget(screen(true));
    await tester.pumpAndSettle();
    expect(find.text('Retry save'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next deal'))
          .onPressed,
      isNull,
    );
    store.fail = false;
    await tester.tap(find.text('Retry save'));
    await tester.pumpAndSettle();
    expect(store.data['mahjong']!.completedCount, 1);
    await tester.pumpWidget(screen(false));
    await tester.pumpWidget(screen(true));
    await tester.pumpAndSettle();
    expect(store.data['mahjong']!.completedCount, 1);
  });
}
