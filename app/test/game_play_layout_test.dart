import 'package:baka_games/shell/game_play_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_menu_helpers.dart';

void main() {
  testWidgets('play fills viewport and menu preserves and blocks board', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var taps = 0;
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: GamePlayLayout(
                title: 'Test game',
                status: 'Level 1',
                overlay: const Text('Live objective'),
                onMenuOpened: () => opened++,
                menu: Column(
                  children: List.generate(30, (i) => Text('Information $i')),
                ),
                child: GestureDetector(
                  key: const Key('board'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('board'))).height, 520);
    expect(find.text('Information 0'), findsNothing);
    expect(find.text('Live objective'), findsOneWidget);
    final boardRect = tester.getRect(find.byKey(const Key('board')));
    await tester.tap(find.byKey(const Key('board')));
    expect(taps, 1);
    await tester.tapAt(tester.getCenter(find.byKey(const Key('gameOverlay'))));
    expect(taps, 2);
    await openGameMenu(tester);
    expect(opened, 1);
    expect(tester.getRect(find.byKey(const Key('board'))), boardRect);
    expect(
      tester.getSize(find.byKey(const Key('gameMenuPanel'))).height,
      lessThan(boardRect.height),
    );
    expect(find.byKey(const Key('board')), findsOneWidget);
    await tester.tapAt(const Offset(160, 300));
    expect(taps, 2);
    await tester.ensureVisible(find.text('Information 29'));
    expect(tester.takeException(), isNull);
    await closeGameMenu(tester);
    await tester.tap(find.byKey(const Key('board')));
    expect(taps, 3);
    await openGameMenu(tester);
    await tester.tapAt(Offset(boardRect.center.dx, boardRect.bottom - 4));
    await tester.pump();
    expect(find.byKey(const Key('gameMenuPanel')), findsNothing);
    expect(taps, 3);
  });

  testWidgets('system back closes menu before leaving the game', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(
                  body: GamePlayLayout(
                    title: 'Game',
                    status: 'Playing',
                    menu: Text('Help'),
                    child: Text('Board'),
                  ),
                ),
              ),
            ),
            child: const Text('Launch'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Launch'));
    await tester.pumpAndSettle();
    await openGameMenu(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Help'), findsNothing);
    expect(find.text('Board'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Launch'), findsOneWidget);
  });

  testWidgets('resume closes the menu and completed game reveals board', (
    tester,
  ) async {
    var paused = false;
    var completed = false;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return GamePlayLayout(
                title: 'Game',
                status: 'Playing',
                paused: paused,
                completed: completed,
                onMenuOpened: () => setState(() => paused = true),
                onTogglePause: () => setState(() => paused = !paused),
                menu: const Text('Help'),
                child: const Text('Board'),
              );
            },
          ),
        ),
      ),
    );
    await openGameMenu(tester);
    expect(paused, isTrue);
    await tester.tap(find.byTooltip('Resume'));
    await tester.pump();
    expect(paused, isFalse);
    expect(find.text('Help'), findsNothing);
    await openGameMenu(tester);
    update(() => completed = true);
    await tester.pump();
    expect(find.text('Help'), findsNothing);
  });
}
