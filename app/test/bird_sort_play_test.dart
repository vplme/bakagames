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
      final c = PlayController(Level(
        capacity: 4,
        branches: [
          Branch(side: Side.left, birds: const [1]),
          Branch(side: Side.right, birds: const [2, 2, 2, 2]),
        ],
        removeBranchOnComplete: false,
      ));
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
    testWidgets('renders board, plays to a win, shows win sheet',
        (tester) async {
      int? wonMoves;
      await tester.pumpWidget(MaterialApp(
        home: BirdSortPlayScreen(
          levelIndex: 0,
          debugLevel: tinyLevel(),
          onWon: (m) => wonMoves = m,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Moves: 0'), findsOneWidget);

      // Tap branch 1 (right side), then branch 0 (left side) → win.
      final size = tester.getSize(find.byType(Scaffold));
      final boardTop = tester.getTopLeft(find.text('Moves: 0')).dy;
      // Branch rows: 3 rows over the board area. Tap by hitting the row's
      // half: row 1 is right side, row 0 left side.
      final board = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'BirdSortBoard');
      final boardRect = tester.getRect(board);
      final rowH = boardRect.height.clamp(0, boardTop) / 3;
      Offset rowCenter(int row, bool left) => Offset(
          left ? size.width * 0.25 : size.width * 0.75,
          boardRect.top + rowH * (row + 0.5));

      await tester.tapAt(rowCenter(1, false)); // select source
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(rowCenter(0, true)); // target → completes
      await tester.pumpAndSettle();

      expect(wonMoves, 1);
      expect(find.text('Level 1 complete!'), findsOneWidget);
      expect(find.text('Next level'), findsOneWidget);
    });

    testWidgets('undo button reverts a move', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: BirdSortPlayScreen(levelIndex: 4, debugLevel: tinyLevel()),
      ));
      await tester.pumpAndSettle();
      final undo = find.widgetWithIcon(IconButton, Icons.undo);
      expect(tester.widget<IconButton>(undo).onPressed, isNull);

      final board = find.byType(BirdSortPlayScreen);
      final rect = tester.getRect(board);
      // Select row 0 (left), move to row 2 (left, empty).
      // Rows are inside the board area; approximate via screen thirds.
      await tester.tapAt(Offset(rect.width * 0.25, rect.height * 0.30));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(Offset(rect.width * 0.25, rect.height * 0.62));
      await tester.pumpAndSettle();
      expect(find.text('Moves: 1'), findsOneWidget);

      await tester.tap(undo);
      await tester.pumpAndSettle();
      expect(find.text('Moves: 0'), findsOneWidget);
    });
  });
}
