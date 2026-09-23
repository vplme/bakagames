import 'package:baka_games/games/coin_pusher/coin_pusher_game.dart';
import 'package:baka_games/games/mergefront/mergefront_game.dart';
import 'package:baka_games/shell/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  for (final squad in [true, false]) {
    testWidgets(
      '${squad ? 'Squad' : 'Pusher'} compact menu opens its collection without playing',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final settings = AppSettings();
        settings.soundOn.value = false;
        settings.reducedMotion.value = true;
        final entry = squad
            ? mergefrontEntry(settings: settings)
            : coinPusherEntry(settings: settings);
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
        expect(tester.takeException(), isNull);
        final tile = find.text(squad ? 'My squad' : 'My toys');
        await tester.scrollUntilVisible(tile, 180);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(settings.lastPlayed, isEmpty);
        if (squad) {
          await tester.scrollUntilVisible(
            find.text('YOUR SQUAD  3/3'),
            180,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.pump();
        }
        expect(
          find.text(squad ? 'YOUR SQUAD  3/3' : 'Your cuddly collection'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('Squad play button starts a mission directly', (tester) async {
    final settings = AppSettings();
    settings.soundOn.value = false;
    settings.hapticsOn.value = false;
    settings.reducedMotion.value = true;
    final entry = mergefrontEntry(settings: settings);
    await tester.pumpWidget(
      MaterialApp(home: Builder(builder: entry.buildHomeScreen!)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Play mission 1'), 150);
    await tester.tap(find.text('Play mission 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('mergefrontBattlefield')), findsOneWidget);
    expect(settings.lastPlayed['mergefront'], isNotNull);
    await tester.pumpWidget(const SizedBox());
  });
}
