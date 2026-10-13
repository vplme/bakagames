import 'package:baka_games/games/solitaire/moon_garden_art.dart';
import 'package:baka_games/games/solitaire/solitaire_game.dart';
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
  testWidgets('moon garden home scrolls at compact size and enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettings()..reducedMotion.value = true;
    final entry = solitaireEntry(store: MemoryStore(), settings: settings);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Builder(builder: entry.buildHomeScreen!),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MoonGardenBackdrop), findsOneWidget);
    await tester.ensureVisible(find.text('How to play'));
    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Play a new deal'));
    await tester.tap(find.text('Play a new deal'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('solitaireStock')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final system in [false, true]) {
    testWidgets(
      '${system ? 'system' : 'app'} reduced motion suppresses garden twinkles',
      (tester) async {
        final settings = AppSettings()..reducedMotion.value = !system;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: system),
              child: child!,
            ),
            home: SolitaireScreen(store: MemoryStore(), settings: settings),
          ),
        );
        expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
