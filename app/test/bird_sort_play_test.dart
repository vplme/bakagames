import 'package:baka_games/games/bird_sort/play_controller.dart';
import 'package:baka_games/games/bird_sort/play_screen.dart';
import 'package:bird_sort/bird_sort.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Level tinyLevel({bool remove = false}) => Level(
  capacity: 4,
  branches: [
    Branch(side: Side.left, birds: const [1, 1, 1]),
    Branch(side: Side.right, birds: const [1]),
    Branch(side: Side.left, birds: const []),
  ],
  removeBranchOnComplete: remove,
  partialMovesAllowed: true,
);

void main() {
  group('PlayController', () {
    test('tap source then target applies the move and keeps ids aligned', () {
      final c = PlayController(tinyLevel());
      expect(c.birdIds[0], hasLength(3));
      c.tapBranch(1); // select
      expect(c.selected, 1);
      c.tapBranch(0); // move the lone 1 over → branch 0 completes → flock
      expect(c.selected, isNull);
      expect(c.state.isWon, isTrue);
      expect(c.birdIds.every((b) => b.isEmpty), isTrue);
      expect(c.departed, hasLength(4));
    });

    test('invalid tap shakes, selection cleared', () {
      final c = PlayController(
        Level(
          capacity: 4,
          branches: [
            Branch(side: Side.left, birds: const [1]),
            Branch(side: Side.right, birds: const [2, 2, 2, 2]),
          ],
          removeBranchOnComplete: false,
        ),
      );
      c.tapBranch(0);
      final tick = c.shakeTick;
      c.tapBranch(1); // full target → invalid
      expect(c.shakeTick, tick + 1);
      expect(c.shakeBranch, 1);
      expect(c.selected, isNull);
      expect(c.state.moveCount, 0);
    });

    test('undo and restart restore engine state and bird mirror', () {
      final c = PlayController(tinyLevel());
      c.tapBranch(0);
      c.tapBranch(2); // move group of 3 to empty branch
      expect(c.birdIds[2], hasLength(3));
      c.undoMove();
      expect(c.birdIds[0], hasLength(3));
      expect(c.birdIds[2], isEmpty);
      expect(c.state, GameState.initial(tinyLevel()));
      c.tapBranch(0);
      c.tapBranch(2);
      c.tapBranch(1);
      c.tapBranch(2);
      c.restartLevel();
      expect(c.state.moveCount, 0);
      expect(c.birdIds[0], hasLength(3));
      expect(c.departed, isEmpty);
    });
  });

  group('BirdSortPlayScreen', () {
    testWidgets('renders board, plays to a win, shows win sheet', (
      tester,
    ) async {
      int? wonMoves;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: BirdSortPlayScreen(
            levelIndex: 0,
            debugLevel: tinyLevel(),
            onWon: (i, m) => wonMoves = m,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Moves: 0'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('branch1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('branch0')));
      await tester.pumpAndSettle();

      expect(wonMoves, 1);
      expect(find.text('Level 1 complete!'), findsOneWidget);
      expect(find.text('Next level'), findsOneWidget);
    });

    testWidgets('undo button reverts a move', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: BirdSortPlayScreen(levelIndex: 4, debugLevel: tinyLevel()),
        ),
      );
      await tester.pumpAndSettle();
      final undo = find.widgetWithIcon(IconButton, Icons.undo);
      expect(tester.widget<IconButton>(undo).onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('branch0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('branch2')));
      await tester.pumpAndSettle();
      expect(find.text('Moves: 1'), findsOneWidget);

      await tester.tap(undo);
      await tester.pumpAndSettle();
      expect(find.text('Moves: 0'), findsOneWidget);
    });
  });

  group('boosters', () {
    test('extra branch: adds one empty branch, once per level, undoable', () {
      final c = PlayController(tinyLevel());
      expect(c.birdIds, hasLength(3));
      c.useExtraBranch();
      expect(c.birdIds, hasLength(4));
      expect(c.state.branches, hasLength(4));
      expect(c.extraBranchUsed, isTrue);
      c.useExtraBranch(); // second use is a no-op
      expect(c.birdIds, hasLength(4));
      c.undoMove(); // booster is a history transition
      expect(c.birdIds, hasLength(3));
      expect(c.state.branches, hasLength(3));
      expect(c.extraBranchUsed, isTrue); // not refunded
    });

    testWidgets('hint solves in an isolate and plays the move', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: BirdSortPlayScreen(levelIndex: 0, debugLevel: tinyLevel()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lightbulb_outline));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();
      // tinyLevel is one move from won: the hint plays it.
      expect(find.text('Level 1 complete!'), findsOneWidget);
    });

    testWidgets('+ Branch button adds a branch and disables itself', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: BirdSortPlayScreen(levelIndex: 0, debugLevel: tinyLevel()),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithIcon(IconButton, Icons.park_outlined);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(button).onPressed, isNull);
    });
  });
}
