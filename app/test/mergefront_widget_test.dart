import 'package:baka_games/games/mergefront/art.dart';
import 'package:baka_games/games/mergefront/audio.dart';
import 'package:baka_games/games/mergefront/mergefront_game.dart';
import 'package:baka_games/games/mergefront/model.dart';
import 'package:baka_games/main.dart';
import 'package:baka_games/shell/progress_store.dart';
import 'package:baka_games/shell/registry.dart';
import 'package:baka_games/shell/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class MemoryStore extends MergefrontStore {
  Profile value = Profile();
  bool fail = false;
  @override
  Future<Profile> load() async => value;
  @override
  Future<void> save(Profile p) async {
    if (fail) throw StateError('disk full');
    value = Profile.fromJson(p.toJson());
  }
}

void main() {
  late AppSettings settings;
  late MemoryStore store;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    settings = AppSettings();
    settings.soundOn.value = false;
    settings.hapticsOn.value = false;
    settings.reducedMotion.value = true;
    store = MemoryStore();
  });
  Future<void> open(WidgetTester tester, {bool compact = false}) async {
    if (compact) {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(compact ? 1.3 : 1)),
          child: child!,
        ),
        home: MergefrontScreen(settings: settings, store: store),
      ),
    );
    await tester.pump();
  }

  Future<void> deploy(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byKey(const Key('mergefrontStart')),
      150,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('mergefrontStart')));
    await tester.pump();
  }

  Run battlefield(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((w) => w.painter)
      .whereType<BattlefieldPainter>()
      .firstWhere((p) => p.run != null)
      .run!;
  testWidgets('compact battle shows base damage, squad hits and defeat cause', (
    tester,
  ) async {
    await open(tester, compact: true);
    await deploy(tester);
    final r = battlefield(tester);
    expect(find.text('BASE 100/100'), findsOneWidget);
    r.spawn(EnemyKind.rusher, .88);
    r.enemies.first.y = .80;
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('BASE 95/100'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('mergefrontBaseBar')),
          )
          .value,
      .95,
    );
    expect(find.textContaining('BASE HIT −5'), findsOneWidget);
    r.hurt(10);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('SQUAD −10 HP'), findsOneWidget);
    expect(tester.takeException(), isNull);
    r.baseHealth = 25;
    r.spawn(EnemyKind.boss, .5);
    r.bossSpawned = true;
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('BASE 25/100 • CRITICAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
    r.baseHealth = 5;
    r.spawn(EnemyKind.rusher, .88);
    r.enemies.firstWhere((e) => e.active && e.kind == EnemyKind.rusher).y = .80;
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.textContaining('Base overrun'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('compact battle explains attack lanes and active defenses', (
    tester,
  ) async {
    await open(tester, compact: true);
    await deploy(tester);
    final r = battlefield(tester)
      ..squad.last.armored = true
      ..shield = 24;
    r.warnings.add(Warning(r.x, 1.5));
    r.squad.last.hp = 10;
    await tester.pump(const Duration(milliseconds: 32));
    expect(
      find.text('Incoming strike! Steer out of the red lanes.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mergefrontDefenses')), findsOneWidget);
    expect(find.textContaining('Armor 1/3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('library registration opens dedicated landing screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      BakaGamesApp(
        registry: GameRegistry([mergefrontEntry(settings: settings)]),
        store: SharedPrefsProgressStore(),
        settings: settings,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('game-card-mergefront')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('All games'), findsOneWidget);
    expect(settings.lastPlayed, isEmpty);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('My squad'), 150);
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.text('My squad'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.descendant(
        of: find.byType(MergefrontScreen),
        matching: find.text('Squad Rusher'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mergefrontStart')), findsOneWidget);
  });
  testWidgets(
    'steering selects one gate, ignores secondary touches and cancellation',
    (tester) async {
      await open(tester);
      await deploy(tester);
      final rect = tester.getRect(
        find.byKey(const Key('mergefrontBattlefield')),
      );
      final gesture = await tester.startGesture(
        Offset(rect.center.dx, rect.top + rect.height * .7),
        pointer: 1,
      );
      await gesture.moveBy(Offset(-rect.width * .3, 0));
      final secondary = await tester.startGesture(
        Offset(rect.center.dx, rect.top + rect.height * .7),
        pointer: 2,
      );
      await secondary.moveBy(Offset(rect.width * .4, 0));
      expect(battlefield(tester).targetX, lessThan(.5));
      await gesture.cancel();
      await secondary.up();
      for (var i = 0; i < 42; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(battlefield(tester).gateCount, 1);
      expect(battlefield(tester).squad.length, 11);
    },
  );
  testWidgets('pause, lifecycle and restart preserve seed and stop time', (
    tester,
  ) async {
    await open(tester);
    await deploy(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('mergefrontPause')));
    await tester.pump();
    final before = battlefield(tester).time;
    await tester.pump(const Duration(seconds: 1));
    expect(battlefield(tester).time, before);
    await tester.tap(find.byKey(const Key('mergefrontRestart')));
    await tester.pump();
    expect(battlefield(tester).time, lessThan(before));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('TAKE A BREATHER'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
  testWidgets(
    'merge updates inventory and persists; failed save blocks deployment',
    (tester) async {
      await open(tester);
      final source = find.byKey(const ValueKey('unit-0'));
      await tester.scrollUntilVisible(source, 200);
      await tester.pump();
      await tester.tap(
        find.descendant(of: source, matching: find.text('Merge')),
      );
      await tester.tap(find.byKey(const ValueKey('unit-1')));
      await tester.pump();
      await tester.pump();
      expect(store.value.cards.where((c) => c.tier == 2).length, 1);
      store.fail = true;
      await tester.tap(find.byKey(const ValueKey('unit-2')));
      await tester.pump();
      await tester.pump();
      expect(find.text('Retry save'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('mergefrontStart')),
        -200,
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('mergefrontStart')))
            .onPressed,
        isNull,
      );
      store.fail = false;
      await tester.tap(find.text('Retry save'));
      await tester.pump();
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('mergefrontStart')))
            .onPressed,
        isNotNull,
      );
    },
  );
  testWidgets('real battle completion saves rewards then allows another run', (
    tester,
  ) async {
    await open(tester);
    await deploy(tester);
    final r = battlefield(tester);
    // Advance the real engine to the boss; defeat is a valid complete run.
    for (var i = 0; i < 800 && !r.finished; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('mergefrontLoadout')),
      150,
    );
    expect(find.byKey(const Key('mergefrontLoadout')), findsOneWidget);
    expect(store.value.runs, 1);
    expect(store.value.coins, greaterThan(0));
    await tester.ensureVisible(find.byKey(const Key('mergefrontLoadout')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('mergefrontLoadout')));
    await tester.pump();
    await deploy(tester);
    expect(battlefield(tester).finished, isFalse);
  });
  testWidgets('compact enlarged layout, reduced motion and settings', (
    tester,
  ) async {
    await open(tester, compact: true);
    expect(tester.takeException(), isNull);
    await deploy(tester);
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<BattlefieldPainter>()
        .first;
    expect(painter.reduced, isTrue);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Options'));
    await tester.pump();
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Master sound'),
          )
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Haptics'),
          )
          .value,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'results wait for reward save and retry never duplicates rewards',
    (tester) async {
      await open(tester);
      await deploy(tester);
      final r = battlefield(tester);
      store.fail = true;
      r.time = r.level.duration - .01;
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('Retry save'), findsOneWidget);
      final button = find.byKey(const Key('mergefrontLoadout'));
      await tester.scrollUntilVisible(button, 150);
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(r.rewarded, isTrue);
      store.fail = false;
      await tester.tap(find.text('Retry save'));
      await tester.pump();
      await tester.pump();
      expect(store.value.runs, 1);
      expect(store.value.cards.length, 6);
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    },
  );
  testWidgets('long-press drag merges matching inventory cards', (
    tester,
  ) async {
    await open(tester);
    final source = find.byKey(const ValueKey('unit-0'));
    await tester.scrollUntilVisible(source, 200);
    await tester.pump();
    final gesture = await tester.startGesture(tester.getCenter(source));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('unit-1'))),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump();
    expect(store.value.cards.where((c) => c.tier == 2).length, 1);
  });
  test(
    'audio events honor global haptics and master mute independently',
    () async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              calls.add(call.arguments as String);
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final audio = MergefrontAudio(settings, Profile());
      await audio.event('gate');
      await audio.event('merge');
      expect(calls, isEmpty);
      settings.hapticsOn.value = true;
      await audio.event('merge');
      expect(calls, ['HapticFeedbackType.mediumImpact']);
      expect(settings.soundOn.value, isFalse);
      audio.dispose();
    },
  );
  test('preferences store round trip uses independent game key', () async {
    final disk = MergefrontStore();
    final p = Profile()..coins = 321;
    p.merge(0, 1);
    await disk.save(p);
    expect((await disk.load()).toJson(), p.toJson());
  });
}
