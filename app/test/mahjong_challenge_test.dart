import 'package:baka_games/games/mahjong/levels.dart';
import 'package:baka_games/games/mahjong/mahjong_game.dart';
import 'package:baka_games/games/mahjong/model.dart';
import 'package:baka_games/shell/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'table_games_widget_test.dart' show MemoryStore;

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'challenge progression adds ordered lanterns and decreasing time limits',
    () {
      for (var deal = 0; deal < 30; deal++) {
        final board = MahjongBoard.deal(deal);
        expect(board.lanternTargets.length, mahjongLanternCount(deal));
        expect(board.lanternProgress, 0);
        for (final id in board.lanternTargets) {
          expect(board.isFree(id), isFalse);
          final t = board.tiles[id];
          expect(
            board.tiles.any(
              (u) => u.x == t.x && u.y == t.y && u.layer > t.layer,
            ),
            isTrue,
          );
        }
        for (final pair in board.solution) {
          final before = board.lanternProgress;
          expect(
            board.match(pair[0], pair[1]),
            isTrue,
            reason: 'Deal ${deal + 1}',
          );
          expect(board.lanternProgress, greaterThanOrEqualTo(before));
        }
        expect(board.won, isTrue);
        expect(board.lanternProgress, board.lanternTargets.length);
        while (board.undo()) {}
        expect(board.lanternProgress, 0);
        expect(board.remaining, board.tiles.length);
        if (deal < 24) {
          expect(mahjongTimeLimit(deal), isNull);
        } else if (deal > 24) {
          expect(
            mahjongTimeLimit(deal)!,
            lessThan(mahjongTimeLimit(deal - 1)!),
          );
        }
      }
      expect(mahjongTimeLimit(24), const Duration(minutes: 8));
      expect(mahjongTimeLimit(29), const Duration(minutes: 5));
    },
  );

  test(
    'wrong-order reveals are rejected atomically; hints and undo obey order',
    () {
      final board = MahjongBoard.fromTiles(
        const [
          GardenTile(0, 0, 0, 0, 0), // lantern 1, under a matching cover pair
          GardenTile(1, 1, 0, 0, 1),
          GardenTile(2, 3, 0, 0, 0), // lantern 2
          GardenTile(3, 4, 0, 0, 1),
          GardenTile(4, 0, 0, 1, 2),
          GardenTile(5, 1, 0, 1, 2),
          GardenTile(6, 3, 0, 1, 3),
          GardenTile(7, 4, 0, 1, 3),
        ],
        lanternTargets: [0, 2],
      );
      expect(board.match(6, 7), isFalse);
      expect(board.removed, isEmpty);
      expect(board.history, isEmpty);
      expect(board.lanternProgress, 0);
      expect(board.hint, [4, 5]);
      expect(board.legalPairs, [
        [4, 5],
      ]);
      expect(board.removed, isEmpty); // querying hints must not mutate the game
      expect(board.match(4, 5), isTrue);
      expect(board.lanternProgress, 1);
      expect(board.match(6, 7), isTrue);
      expect(board.lanternProgress, 2);
      expect(board.undo(), isTrue);
      expect(board.lanternProgress, 1);
      expect(board.undo(), isTrue);
      expect(board.lanternProgress, 0);
      expect(board.canMatch(6, 7), isFalse);
    },
  );

  Future<void> launch(
    WidgetTester tester,
    MemoryStore store, {
    int deal = 29,
    bool reduce = true,
  }) async {
    final settings = AppSettings()
      ..hapticsOn.value = false
      ..reducedMotion.value = reduce;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: child!,
        ),
        home: MahjongScreen(
          store: store,
          settings: settings,
          initialDeal: deal,
        ),
      ),
    );
  }

  String clock(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('mahjongClock'))).data!;
  Future<void> tap(WidgetTester tester, int id) async {
    final tile = find.byKey(Key('mahjongTile$id'));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pump();
  }

  testWidgets(
    'timer starts on input, ignores reduced motion and pauses for menu and background',
    (tester) async {
      await launch(tester, MemoryStore());
      expect(clock(tester), '5:00 · tap to start');
      await tester.pump(const Duration(minutes: 1));
      expect(clock(tester), '5:00 · tap to start');
      await tap(tester, MahjongBoard.deal(29).solution.first.first);
      await tester.pump(const Duration(seconds: 12));
      expect(clock(tester), '4:48 left');
      await tester.tap(find.byKey(const Key('gameMenu')));
      await tester.pump();
      expect(clock(tester), '4:48 · paused');
      await tester.pump(const Duration(minutes: 2));
      expect(clock(tester), '4:48 · paused');
      // System back is a distinct menu-closing path.
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(clock(tester), '4:45 left');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 3));
      expect(clock(tester), '4:45 left');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(clock(tester), '4:40 left');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'time expiry gives retry, no credit, no undo loophole; restart resets clock and lanterns',
    (tester) async {
      final store = MemoryStore();
      await launch(tester, store);
      final board = MahjongBoard.deal(29);
      for (final pair in board.solution) {
        for (final id in pair) {
          await tap(tester, id);
        }
        board.match(pair[0], pair[1]);
        if (board.lanternProgress > 0) break;
      }
      expect(find.text('Lanterns 1/4'), findsOneWidget);
      await tester.pump(const Duration(minutes: 6));
      expect(find.byKey(const Key('mahjongTimedOut')), findsOneWidget);
      expect(store.data, isEmpty);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Undo',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Hint',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(find.byKey(const Key('mahjongTimedOut')), findsNothing);
      expect(clock(tester), '5:00 · tap to start');
      expect(find.text('Lanterns 0/4'), findsOneWidget);
      expect(find.text('0 / 30 pairs'), findsOneWidget);
      expect(store.data, isEmpty);
    },
  );

  testWidgets('undo restores a lit lantern without refunding elapsed time', (
    tester,
  ) async {
    await launch(tester, MemoryStore());
    final board = MahjongBoard.deal(29);
    for (final pair in board.solution) {
      for (final id in pair) {
        await tap(tester, id);
      }
      board.match(pair[0], pair[1]);
      if (board.lanternProgress > 0) break;
    }
    await tester.pump(const Duration(seconds: 10));
    expect(clock(tester), '4:50 left');
    expect(find.text('Lanterns 1/4'), findsOneWidget);
    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    expect(find.text('Lanterns 0/4'), findsOneWidget);
    expect(clock(tester), '4:50 left');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'last pair before deadline stops clock, finishes animation and saves once',
    (tester) async {
      final store = MemoryStore();
      await launch(tester, store, reduce: false);
      final pairs = MahjongBoard.deal(29).solution;
      for (final pair in pairs.take(pairs.length - 1)) {
        for (final id in pair) {
          await tap(tester, id);
        }
      }
      await tester.pump(const Duration(seconds: 299));
      expect(clock(tester), '0:01 left');
      for (final id in pairs.last) {
        await tap(tester, id);
      }
      expect(store.data['mahjong']!.completedCount, 1);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Garden aglow!'), findsOneWidget);
      expect(find.byKey(const Key('mahjongTimedOut')), findsNothing);
      expect(store.data['mahjong']!.completedCount, 1);
    },
  );
}
