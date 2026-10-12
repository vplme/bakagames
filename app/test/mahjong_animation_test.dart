import 'package:baka_games/games/mahjong/lantern_art.dart';
import 'package:game_core/game_core.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:baka_games/games/mahjong/mahjong_game.dart';
import 'package:baka_games/games/mahjong/model.dart';
import 'package:baka_games/shell/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'table_games_widget_test.dart' show MemoryStore;

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  Future<void> tapTile(WidgetTester tester, int id) async {
    final tile = find.byKey(Key('mahjongTile$id'));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pump();
  }

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(844, 390),
  ]) {
    testWidgets('asymmetric beginner footprint is centered at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettings()
        ..hapticsOn.value = false
        ..reducedMotion.value = true;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: MahjongScreen(store: MemoryStore(), settings: settings),
        ),
      );
      Rect tile(int id) => tester.getRect(find.byKey(Key('mahjongTile$id')));
      final model = MahjongBoard.deal(0);
      final footprint = model.tiles
          .map((t) => tile(t.id))
          .reduce((a, b) => a.expandToInclude(b));
      expect(
        footprint.left,
        closeTo(size.width - footprint.right, .01),
        reason: 'The asymmetric layout must still have balanced margins.',
      );
      expect(footprint.left, greaterThanOrEqualTo(12));
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(844, 390),
  ]) {
    testWidgets(
      'expert layout stays centered with visible four-layer stacks at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final settings = AppSettings()
          ..hapticsOn.value = false
          ..reducedMotion.value = true;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: MahjongScreen(
              store: MemoryStore(),
              settings: settings,
              initialDeal: 29,
            ),
          ),
        );
        final model = MahjongBoard.deal(29);
        Rect tile(int id) => tester.getRect(find.byKey(Key('mahjongTile$id')));
        final footprint = model.tiles
            .map((t) => tile(t.id))
            .reduce((a, b) => a.expandToInclude(b));
        expect(footprint.left, closeTo(size.width - footprint.right, .01));
        expect(find.text('Expert · 4 layers'), findsOneWidget);
        final motif = find.descendant(
          of: find.byKey(const Key('mahjongTile0')),
          matching: find.byType(FestivalMotif),
        );
        expect(tester.getSize(motif).shortestSide, greaterThanOrEqualTo(24));
        expect(find.text('0 / 30 pairs'), findsOneWidget);
        for (final upper in model.tiles.where((t) => t.layer > 0)) {
          final lower = model.tiles.firstWhere(
            (t) =>
                t.x == upper.x && t.y == upper.y && t.layer == upper.layer - 1,
          );
          expect(tile(upper.id).left - tile(lower.id).left, closeTo(0, .01));
          expect(
            tile(lower.id).bottom - tile(upper.id).bottom,
            greaterThanOrEqualTo(7),
          );
        }
        for (final a in model.tiles) {
          for (final b in model.tiles) {
            if (a.x != b.x || a.y != b.y) {
              expect(
                tile(a.id).overlaps(tile(b.id)),
                isFalse,
                reason: 'Stacks must not overlap neighbouring cells.',
              );
            }
          }
        }
        for (final id in model.solution.first) {
          await tapTile(tester, id);
        }
        expect(find.text('1 / 30 pairs'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final deal in [3, 12, 29]) {
    testWidgets('deal ${deal + 1} plays to a saved win on a compact screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettings()
        ..hapticsOn.value = false
        ..reducedMotion.value = true;
      final store = MemoryStore();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: MahjongScreen(
            store: store,
            settings: settings,
            initialDeal: deal,
          ),
        ),
      );
      final model = MahjongBoard.deal(deal);
      final footprint = model.tiles
          .map((t) => tester.getRect(find.byKey(Key('mahjongTile${t.id}'))))
          .reduce((a, b) => a.expandToInclude(b));
      expect(footprint.left, closeTo(320 - footprint.right, .01));
      for (final pair in model.solution) {
        for (final id in pair) {
          await tapTile(tester, id);
        }
      }
      await tester.pumpAndSettle();
      expect(find.text('Garden aglow!'), findsOneWidget);
      expect(store.data['mahjong']!.results[deal]!.completed, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('deal menu explains progression and retains completed deals', (
    tester,
  ) async {
    final store = MemoryStore();
    store.data['mahjong'] = GameProgress().withCompleted(0, 22);
    final settings = AppSettings()..hapticsOn.value = false;
    final entry = mahjongEntry(store: store, settings: settings);
    await tester.pumpWidget(
      MaterialApp(home: Builder(builder: entry.buildHomeScreen!)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Play deal 2'), findsOneWidget);
    expect(
      find.text('30 deals · lantern objectives · timed expert levels'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Choose a deal'), 300);
    await tester.tap(find.text('Choose a deal'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gentle · 12 pairs · 1 layer'), findsWidgets);
    expect(find.textContaining('Completed · best 22 moves'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Deal 25'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Expert · 28 pairs · 4 layers'), findsWidgets);
    expect(store.data['mahjong']!.completedCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selection lifts; pairs collect concurrently; undo cancels flight',
    (tester) async {
      final settings = AppSettings()..hapticsOn.value = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MahjongScreen(store: MemoryStore(), settings: settings),
        ),
      );
      final solution = MahjongBoard.deal(0).solution;
      final sourceRect = tester.getRect(
        find.byKey(Key('mahjongTile${solution[0][0]}')),
      );
      await tapTile(tester, solution[0][0]);
      await tester.pump(const Duration(milliseconds: 180));
      final selected = find.descendant(
        of: find.byKey(Key('mahjongTile${solution[0][0]}')),
        matching: find.byType(AnimatedScale),
      );
      expect(tester.widget<AnimatedScale>(selected).scale, 1.06);
      await tapTile(tester, solution[0][1]);
      expect(find.byType(PairCollection), findsOneWidget);
      final flyingTile = find
          .descendant(
            of: find.byType(PairCollection),
            matching: find.byType(Opacity),
          )
          .first;
      expect(
        tester.getRect(flyingTile),
        sourceRect,
        reason: 'Collection must start at the centered, raised tile origin.',
      );
      expect(find.byKey(Key('mahjongTile${solution[0][0]}')), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      for (final id in solution[1]) {
        await tapTile(tester, id);
      }
      expect(find.byType(PairCollection), findsNWidgets(2));
      expect(
        find.text('2 / ${MahjongBoard.deal(0).pairCount} pairs'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(find.byType(PairCollection), findsNothing);
      for (final id in solution[1]) {
        expect(find.byKey(Key('mahjongTile$id')), findsOneWidget);
      }
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.text('1 / ${MahjongBoard.deal(0).pairCount} pairs'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final system in [false, true]) {
    testWidgets(
      '${system ? 'System' : 'App'} reduced motion skips pair flight',
      (tester) async {
        final settings = AppSettings()
          ..hapticsOn.value = false
          ..reducedMotion.value = !system;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: system),
              child: child!,
            ),
            home: MahjongScreen(store: MemoryStore(), settings: settings),
          ),
        );
        for (final id in MahjongBoard.deal(0).solution.first) {
          await tapTile(tester, id);
        }
        expect(find.byType(PairCollection), findsNothing);
        expect(
          find.text('1 / ${MahjongBoard.deal(0).pairCount} pairs'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'last pair saves immediately and finishes collecting before celebration',
    (tester) async {
      final store = MemoryStore();
      final settings = AppSettings()..hapticsOn.value = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MahjongScreen(store: store, settings: settings),
        ),
      );
      for (final pair in MahjongBoard.deal(0).solution) {
        for (final id in pair) {
          await tapTile(tester, id);
        }
      }
      expect(find.text('Garden aglow!'), findsNothing);
      expect(store.data['mahjong']!.completedCount, 1);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      expect(find.text('Garden aglow!'), findsOneWidget);
      expect(store.data['mahjong']!.completedCount, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
