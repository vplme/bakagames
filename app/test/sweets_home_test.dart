import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baka_games/games/match_three/match_three_game.dart';
import 'package:baka_games/shell/home_screen.dart';
import 'package:baka_games/shell/registry.dart';
import 'package:baka_games/shell/settings.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'match_three_test.dart' show MemoryStore;

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  testWidgets(
    'compact sweets home supports guide, settings, level path and all games',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettings();
      settings.reducedMotion.value = true;
      final store = MemoryStore();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.3)),
            child: child!,
          ),
          home: HomeScreen(
            registry: GameRegistry([
              matchThreeEntry(store: store, settings: settings),
            ]),
            store: store,
            settings: settings,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('game-card-match_three'));
      await tester.scrollUntilVisible(
        card,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.scrollUntilVisible(
        find.text('Pocket Sweets'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pocket Sweets'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pocket Sweets'));
      await tester.pumpAndSettle();
      expect(find.text('All games'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Play level 1'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Play level 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Sweet guide'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sweet guide'));
      await tester.pumpAndSettle();
      expect(find.text('Striped sweets'), findsOneWidget);
      expect(find.text('Rainbow sweets'), findsOneWidget);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.text('Striped sweets'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Level path'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Settings'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Sound'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('All games'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('game-card-match_three')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
