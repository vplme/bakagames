import 'package:baka_games/games/bird_sort/aviary.dart';
import 'package:baka_games/games/bird_sort/aviary_levels.dart';
import 'package:baka_games/games/bird_sort/board.dart';
import 'package:baka_games/games/bird_sort/play_screen.dart';
import 'package:bird_sort/bird_sort.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'paced levels are deterministic, solvable, and feature all fifteen species',
    () {
      final seen = <int>{};
      for (final i in [
        0,
        3,
        4,
        8,
        9,
        10,
        15,
        20,
        24,
        30,
        35,
        40,
        47,
        48,
        60,
        62,
        63,
        70,
        79,
        80,
        98,
        99,
        119,
        120,
        142,
        143,
        167,
        168,
        178,
        180,
        199,
        499,
      ]) {
        final level = aviaryLevelFor(i);
        expect(level, aviaryLevelFor(i));
        seen.addAll(level.branches.expand((b) => b.birds));
        final result = solveLevel(level);
        expect(result.solvable, true, reason: 'level $i');
        var state = GameState.initial(level);
        for (final move in result.moves) {
          state = applyMove(state, move);
        }
        expect(state.isWon, true);
        if (i % 5 == 4) expect(level.colourCount, 3);
      }
      expect(seen, {for (var i = 0; i < 15; i++) i});
      expect(collectedCount(0), 3);
      expect(collectedCount(3), 4);
      expect(collectedCount(35), 8);
      expect(collectedCount(47), 8);
      expect(collectedCount(48), 9);
      expect(collectedCount(62), 9);
      expect(collectedCount(63), 10);
      expect(collectedCount(500), 15);
      for (var species = 10; species < birdNames.length; species++) {
        expect(collectedCount(unlockAt[species] - 1), species);
        expect(collectedCount(unlockAt[species]), species + 1);
        final introduced = <int>{};
        for (var i = unlockAt[species]; i < unlockAt[species] + 15; i++) {
          introduced.addAll(aviaryLevelFor(i).branches.expand((b) => b.birds));
        }
        expect(introduced, contains(species));
      }
    },
  );

  for (final pair in [
    [8, 9],
    [10, 11],
    [12, 13],
    [13, 14],
  ]) {
    testWidgets('species $pair render and animate on compact screens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: BirdSortPlayScreen(
            levelIndex: 63,
            debugLevel: Level(
              removeBranchOnComplete: false,
              capacity: 4,
              branches: [
                Branch(
                  side: Side.left,
                  birds: [pair[0], pair[1], pair[0], pair[1]],
                ),
                Branch(
                  side: Side.right,
                  birds: [pair[1], pair[0], pair[1], pair[0]],
                ),
                Branch(side: Side.left, birds: const []),
                Branch(side: Side.right, birds: const []),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.bySemanticsLabel(birdNames[pair[0]]), findsWidgets);
      expect(find.bySemanticsLabel(birdNames[pair[1]]), findsWidgets);
      // Cover idle blinking as well as flight with IDs beyond the original eight.
      for (var frame = 0; frame < 100; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.byKey(const ValueKey('branch0')));
      await tester.ensureVisible(find.byKey(const ValueKey('branch2')));
      await tester.tap(find.byKey(const ValueKey('branch2')));
      expect(
        tester
            .widget<BirdSortBoard>(find.byType(BirdSortBoard))
            .controller
            .moveCount,
        1,
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final remove in [false, true]) {
    testWidgets(
      'departed flocks stay offscreen on later completions (remove=$remove)',
      (tester) async {
        final level = Level(
          capacity: 4,
          removeBranchOnComplete: remove,
          branches: [
            for (var species = 0; species < 3; species++) ...[
              Branch(side: Side.right, birds: [species, species, species]),
              Branch(side: Side.left, birds: [species]),
            ],
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: BirdSortPlayScreen(levelIndex: 0, debugLevel: level),
          ),
        );
        await tester.pump();
        final board = find.byType(BirdSortBoard);
        final c = tester.widget<BirdSortBoard>(board).controller;
        final firstFlock = [...c.birdIds[0], ...c.birdIds[1]];
        void expectFirstFlockOffscreen() {
          final bounds = tester.getRect(board);
          for (final uid in firstFlock) {
            expect(
              tester.getRect(find.byKey(ValueKey('bird$uid'))).overlaps(bounds),
              isFalse,
              reason: 'Departed bird $uid returned during move ${c.moveCount}',
            );
          }
        }

        c.applyExternalMove(const Move(from: 1, to: 0, count: 1));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expectFirstFlockOffscreen();
        for (final move in [
          const Move(from: 3, to: 2, count: 1),
          const Move(from: 5, to: 4, count: 1),
        ]) {
          c.applyExternalMove(move);
          await tester.pump();
          for (var frame = 0; frame < 20; frame++) {
            await tester.pump(const Duration(milliseconds: 50));
            expectFirstFlockOffscreen();
          }
        }
        expect(c.state.isWon, isTrue);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(740, 650));
        await tester.pump();
        for (var frame = 0; frame < 20; frame++) {
          await tester.pump(const Duration(milliseconds: 50));
          expectFirstFlockOffscreen();
        }
        c.undoMove();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expectFirstFlockOffscreen();
        expect(c.birdIds[4], hasLength(3));
        for (final uid in [...c.birdIds[4], ...c.birdIds[5]]) {
          expect(
            tester
                .getRect(find.byKey(ValueKey('bird$uid')))
                .overlaps(tester.getRect(board)),
            isTrue,
          );
        }
        c.restartLevel();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(c.departed, isEmpty);
        for (final uid in firstFlock) {
          expect(
            tester
                .getRect(find.byKey(ValueKey('bird$uid')))
                .overlaps(tester.getRect(board)),
            isTrue,
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('320px phone keeps birds readable and controls usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: const TextScaler.linear(1.3),
          ),
          child: child!,
        ),
        home: BirdSortPlayScreen(levelIndex: 0, debugLevel: aviaryLevelFor(0)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final birds = find.descendant(
      of: find.byType(BirdSortBoard),
      matching: find.byType(BirdArt),
    );
    expect(tester.getSize(birds.first).height, greaterThanOrEqualTo(48));
    await tester.tap(find.byKey(const ValueKey('branch0')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a glowing perch to land.'), findsOneWidget);
    await tester.ensureVisible(find.byIcon(Icons.lightbulb_outline));
    await tester.tap(find.byIcon(Icons.lightbulb_outline));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Moves: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rapid input stays responsive during flight and idle workload is bounded',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BirdSortPlayScreen(
            levelIndex: 60,
            debugLevel: aviaryLevelFor(60),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final screen = tester.widget<BirdSortBoard>(find.byType(BirdSortBoard));
      final c = screen.controller;
      final move = solve(c.state).moves.first;
      c.applyExternalMove(move);
      await tester.pump(const Duration(milliseconds: 40));
      c.undoMove();
      await tester.pump(const Duration(milliseconds: 40));
      expect(c.state, GameState.initial(c.level));
      c.applyExternalMove(move);
      await tester.pump(const Duration(milliseconds: 500));
      expect(c.moveCount, 1);
      final watch = Stopwatch()..start();
      for (var frame = 0; frame < 120; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      watch.stop();
      // Framework work only; simulator/physical-device GPU timings are separate.
      debugPrint(
        'Aviary framework workload: ${watch.elapsedMicroseconds / 120 / 1000} ms/frame over 120 frames',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'save failure is recoverable and next level waits for persistence',
    (tester) async {
      var attempts = 0;
      final level = Level(
        capacity: 4,
        branches: [
          Branch(side: Side.left, birds: const [0, 0, 0]),
          Branch(side: Side.right, birds: const [0]),
        ],
        removeBranchOnComplete: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: BirdSortPlayScreen(
            levelIndex: 0,
            debugLevel: level,
            onWon: (_, _) async {
              if (++attempts == 1) throw StateError('disk unavailable');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('branch1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('branch0')));
      await tester.pumpAndSettle();
      expect(find.text('Save failed · Tap to retry'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Next level'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Save failed · Tap to retry'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Next level'),
            )
            .onPressed,
        isNotNull,
      );
    },
  );
}
