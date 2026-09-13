import 'dart:convert';
import 'package:baka_games/games/coin_pusher/pusher_game.dart';
import 'package:baka_games/shell/home_screen.dart';
import 'package:baka_games/shell/progress_store.dart';
import 'package:baka_games/shell/registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:baka_games/games/coin_pusher/pusher_model.dart';
import 'package:baka_games/games/coin_pusher/coin_pusher_game.dart';
import 'package:baka_games/shell/settings.dart';

Map<String, dynamic> saved(
  List<List<num>> coins, {
  int balance = 0,
  int bonus = 0,
}) => {
  'version': 1,
  'balance': balance,
  'collected': 0,
  'bonus': bonus,
  'drops': 0,
  'phase': 0,
  'coins': coins,
};

void main() {
  test('raised rear toys stay behind nearer toys; equal-depth stacks rise', () {
    final state = PusherModel(saved: saved([])).toJson();
    state['coins'] = [
      [5, 8, 0, 0, 5, 2, 0, 2],
      [5, 8.5, 0, 0, 5, 0, 0, 1],
    ];
    final model = PusherModel(saved: state);
    expect(
      comparePusherDepth(model.coins.first, model.coins.last),
      lessThan(0),
    );
    model.coins.last.body.setTransform(
      model.coins.last.body.position.clone()..setValues(5, 8),
      0,
    );
    expect(
      comparePusherDepth(model.coins.first, model.coins.last),
      greaterThan(0),
    );
  });

  test('ten simultaneous coins earn one large coin and one gold bar', () {
    final model = PusherModel(
      saved: saved([
        for (var i = 0; i < 10; i++) [1 + i * .8, 12, 0, 0, 1],
      ]),
    );
    expect(model.update(1 / 60), 10);
    expect(model.coins.where((c) => c.isLargeCoin), hasLength(1));
    expect(model.coins.where((c) => c.isGoldBar), hasLength(1));
    expect(model.justRewards, hasLength(2));
    expect(model.balance, 10);
    expect(model.collected, 10);
    final restored = PusherModel(saved: model.toJson());
    expect(restored.toJson(), model.toJson());
    final large = restored.coins.firstWhere((c) => c.isLargeCoin);
    final bar = restored.coins.firstWhere((c) => c.isGoldBar);
    expect(large.radius, greaterThan(.4));
    expect(bar.height, greaterThan(PusherCoin.thickness));
    for (final c in restored.coins) {
      c.body.setTransform(
        c.body.position.clone()..setValues(c.value == 10 ? 3 : 7, 12),
        0,
      );
    }
    expect(restored.update(1 / 60), 35);
    expect(restored.balance, 45);
    expect(restored.collected, 45);
    expect(restored.justRewards, isEmpty);
    expect(restored.coins, isEmpty);
    expect(restored.update(1 / 60), 0);
  });

  test(
    'combo window survives reload and expires independently of frame rate',
    () {
      for (final dt in [1 / 60, .1]) {
        final model = PusherModel(
          saved: saved([
            for (var i = 0; i < 4; i++) [2 + i, 12, 0, 0, 1],
            [7, 9, 0, 0, 1],
          ]),
        );
        model.update(dt);
        final restored = PusherModel(saved: model.toJson());
        expect(restored.comboCoins, 4);
        final last = restored.coins.single;
        last.body.setTransform(last.body.position.clone()..setValues(7, 12), 0);
        restored.update(dt);
        expect(restored.coins.where((c) => c.isLargeCoin), hasLength(1));
        expect(restored.justRewards, hasLength(1));
        for (var i = 0; i < 120; i++) {
          restored.update(dt);
        }
        expect(restored.comboCoins, 0);
        expect(restored.comboRemaining, 0);
        expect(restored.justRewards, isEmpty);
      }
    },
  );

  test('blue value, toys and side losses cannot masquerade as five coins', () {
    final state = PusherModel(saved: saved([])).toJson();
    state['coins'] = [
      [3, 12, 0, 0, 5, 0, 0, 0],
      [6, 12, 0, 0, 5, 0, 0, 1],
      for (var i = 0; i < 5; i++) [0, 6 + i, 0, 0, 1, 0, 0, 0],
    ];
    final model = PusherModel(saved: state);
    model.update(1 / 60);
    expect(model.comboCoins, 1);
    expect(model.justRewards, isEmpty);
    expect(model.coins, isEmpty);
  });

  test('full special slots queue rewards across saves, then spawn once', () {
    final state = PusherModel(saved: saved([])).toJson();
    state['pendingLargeCoins'] = 1;
    state['coins'] = [
      for (var i = 0; i < 10; i++)
        [
          1.4 + (i % 5) * 1.8,
          7 + (i ~/ 5) * 2,
          0,
          0,
          i.isEven ? 10 : 25,
          0,
          0,
          0,
        ],
    ];
    final model = PusherModel(saved: state);
    model.update(1 / 60);
    expect(model.pendingLargeCoins, 1);
    final restored = PusherModel(saved: model.toJson());
    restored.coins.first.body.setTransform(
      restored.coins.first.body.position.clone()..setValues(0, 8),
      0,
    );
    expect(restored.update(1 / 60), 0);
    expect(restored.pendingLargeCoins, 0);
    expect(restored.coins, hasLength(10));
    restored.resetBoard();
    expect(restored.coins.any((c) => c.isSpecial), isFalse);
    expect(restored.comboCoins, 0);
  });

  test(
    'all eight milestones unlock exactly at their lifetime coin thresholds',
    () {
      for (var target = 250; target <= 2000; target += 250) {
        final state = saved([
          [5, 12, 0, 0, 1],
        ], balance: 10)..['collected'] = target - 1;
        final model = PusherModel(saved: state);
        expect(model.unlockedPrizeCount, 2 + target ~/ 250);
        expect(model.update(1 / 60), 1);
        expect(model.unlockedPrizeCount, 3 + target ~/ 250);
        expect(model.justUnlocked, [prizeNames[2 + target ~/ 250]]);
        model.update(1 / 60);
        expect(model.justUnlocked, isEmpty);
        final restored = PusherModel(saved: model.toJson());
        expect(restored.unlockedPrizeCount, model.unlockedPrizeCount);
        restored.resetBoard();
        expect(restored.collected, target);
        expect(restored.unlockedPrizeCount, model.unlockedPrizeCount);
      }
      final complete = PusherModel(saved: saved([])..['collected'] = 9000);
      expect(complete.unlockedPrizeCount, 11);
      expect(complete.nextPrizeIndex, isNull);
    },
  );

  test(
    'losses, bonus coins and free refills do not inflate unlock progress',
    () {
      final model = PusherModel(
        saved: saved([
          [0, 12, 0, 0, 5],
          [5, 12, 0, 0, 1],
        ], bonus: 19)..['collected'] = 249,
      );
      expect(model.update(1 / 60), 11);
      expect(model.collected, 250);
      expect(model.justUnlocked, ['Apricot Fox']);
      model.balance = 0;
      model.refill();
      expect(model.collected, 250);
      expect(model.drop(5), isTrue);
      expect(model.collected, 250);
    },
  );

  test('new unlocks spawn, collect and restore with stable toy IDs', () {
    for (var target = 250; target <= 2000; target += 250) {
      final model = PusherModel(
        saved: saved([], balance: 40)..['collected'] = target,
      );
      // Earlier unlocks have already been collected, so the newest is next.
      for (var i = 3; i < model.unlockedPrizeCount - 1; i++) {
        model.collection[prizeIds[i]] = 1;
      }
      model.introducePrizes();
      final newest = model.coins.first;
      expect(newest.prize, model.unlockedPrizeCount);
      expect(
        model.coins.every((c) => c.prize <= model.unlockedPrizeCount),
        isTrue,
      );
      expect(PusherModel(saved: model.toJson()).toJson(), model.toJson());
      newest.body.setTransform(
        newest.body.position.clone()..setValues(5, 12),
        0,
      );
      model.update(1 / 60);
      expect(model.collection[prizeIds[newest.prize - 1]], 1);
      expect(PusherModel(saved: model.toJson()).collection, model.collection);
    }
  });

  testWidgets('completed progression shelf fits compact enlarged text', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final state = PusherModel(
      saved: saved([], balance: 40)..['collected'] = 2000,
    ).toJson();
    await SharedPreferencesAsync().setString(
      'coin_pusher.session.v1',
      jsonEncode(state),
    );
    final settings = AppSettings();
    settings.soundOn.value = false;
    settings.hapticsOn.value = false;
    settings.reducedMotion.value = true;
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
        home: PusherScreen(settings: settings),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Petal Axolotl'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('pusherCollection')));
    await tester.tap(find.byKey(const Key('pusherCollection')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Petal Axolotl'));
    expect(
      find.text('All 8 milestones reached · All 11 toys unlocked!'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    await tester.tap(find.byTooltip('Close collection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Petal Axolotl'), findsNothing);
    expect(find.byTooltip('Pause'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Pause'));
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('pusherCollection')));
    await tester.tap(find.byKey(const Key('pusherCollection')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close collection'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Resume'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('narrow paddle pushes the centre while outer bed coins stay put', () {
    final model = PusherModel(
      saved: saved([
        [5, 3, 0, 0, 1],
        [1, 5.8, 0, 0, 1],
        [9, 5.8, 0, 0, 1],
      ]),
    );
    for (var i = 0; i < 180; i++) {
      model.update(1 / 60);
    }
    expect(model.coins.first.body.position.y, greaterThan(3.2));
    expect(model.coins[1].body.position.x, closeTo(1, .001));
    expect(model.coins[1].body.position.y, closeTo(5.8, .001));
    expect(model.coins[2].body.position.x, closeTo(9, .001));
    expect(model.coins[2].body.position.y, closeTo(5.8, .001));
  });

  test(
    'outer aims drop inside the central opening without hitting shoulders',
    () {
      for (final aim in [-100.0, 100.0]) {
        final model = PusherModel(saved: saved([], balance: 4));
        expect(model.drop(aim), isTrue);
        final coin = model.coins.single;
        expect(
          coin.body.position.x,
          inInclusiveRange(PusherModel.dropMinX, PusherModel.dropMaxX),
        );
        for (var i = 0; i < 180; i++) {
          model.update(1 / 60);
        }
        expect(model.coins, hasLength(1));
        expect(coin.z, 0);
        expect(model.balance, 3);
        expect(PusherModel(saved: model.toJson()).toJson(), model.toJson());
      }
    },
  );

  test(
    'third coin allowed, fourth and airborne overlaps rejected without charge',
    () {
      final state = saved([
        [5, 3, 0, 0, 1, 0, 0],
        [5, 3, 0, 0, 1, .22, 0],
      ], balance: 10)..['version'] = 2;
      final model = PusherModel(saved: state);
      expect(model.drop(5), isTrue);
      expect(model.balance, 9);
      model.cooldown = 0;
      expect(model.drop(5), isFalse);
      expect(model.balance, 9);
      expect(model.drops, 1);
      expect(model.dropBlockedReason, contains('Three coins'));
      final full = saved([
        [5, 3, 0, 0, 1, 0, 0],
        [5, 3, 0, 0, 1, .22, 0],
        [5, 3, 0, 0, 1, .44, 0],
      ], balance: 10)..['version'] = 2;
      final restored = PusherModel(saved: PusherModel(saved: full).toJson());
      expect(restored.drop(5), isFalse);
      expect(restored.balance, 10);
      expect(restored.drop(8), isTrue);
    },
  );
  test('off-centre coins slip off instead of balancing on a sliver', () {
    final state = saved([
      [5, 8, 0, 0, 1, 0, 0],
      [5.6, 8, 0, 0, 1, .22, 0],
    ])..['version'] = 2;
    final model = PusherModel(saved: state);
    for (var i = 0; i < 180; i++) {
      model.update(1 / 60);
    }
    expect(model.coins[1].z, 0);
    expect(model.coins[1].body.position.x, greaterThan(5.75));
  });
  test('legacy fourth-layer coins slide down rather than remain tall', () {
    final state = saved([
      for (var i = 0; i < 4; i++) [5, 8, 0, 0, 1, i * .22, 0],
    ])..['version'] = 2;
    final model = PusherModel(saved: state);
    for (var i = 0; i < 240; i++) {
      model.update(1 / 60);
    }
    expect(model.coins.length, 4);
    expect(
      model.coins.every((c) => c.z <= PusherModel.maxCoinBase + .01),
      isTrue,
    );
  });
  test('reset refreshes board and wallet but preserves collected toys', () {
    final model = PusherModel(saved: saved([], balance: 2));
    model.collection['bear'] = 3;
    model.collected = 75;
    model.bonus = 12;
    model.drop(5);
    model.resetBoard();
    expect(model.balance, 40);
    expect(model.bonus, 0);
    expect(model.drops, 0);
    expect(model.collected, 75);
    expect(model.collection, {'bear': 3});
    expect(model.coins.where((c) => c.prize > 0).length, 3);
    expect(PusherModel(saved: model.toJson()).toJson(), model.toJson());
  });
  test('settled coins and toys do not drift without contact', () {
    final state = PusherModel(saved: saved([], balance: 40)).toJson();
    state['coins'] = [
      [3, 7, 0, 0, 1, 0, 0, 0],
      [3, 7, 0, 0, 1, PusherCoin.thickness, 0, 0],
      [7, 9, 0, 0, 5, 0, 0, 1],
    ];
    final model = PusherModel(saved: state);
    final before = [for (final c in model.coins) c.body.position.clone()];
    for (var i = 0; i < 1800; i++) {
      model.update(1 / 60);
    }
    for (var i = 0; i < before.length; i++) {
      expect((model.coins[i].body.position - before[i]).length, lessThan(.001));
    }
    expect(model.balance, 40);
    expect(model.collected, 0);
    expect(model.collection, isEmpty);
  });
  test('moving pusher still nudges coins through physical contact', () {
    final model = PusherModel(
      saved: saved([
        [5, 3, 0, 0, 1],
      ]),
    );
    for (var i = 0; i < 60; i++) {
      model.update(1 / 60);
    }
    expect(model.coins.single.body.position.y, greaterThan(3.2));
  });
  testWidgets('cosy library cover opens the toy collection', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final settings = AppSettings();
    settings.soundOn.value = false;
    settings.hapticsOn.value = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          registry: GameRegistry([coinPusherEntry(settings: settings)]),
          store: SharedPrefsProgressStore(),
          settings: settings,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        'A cosy wooden coin pusher filled with plush toy prizes',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('game-card-coin_pusher')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Your cuddly collection'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('pusherCollection')));
    await tester.tap(find.byKey(const Key('pusherCollection')));
    await tester.pumpAndSettle();
    expect(find.text('Your cuddly collection'), findsOneWidget);
    expect(find.text('Honey Bear'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(8));
    expect(find.text('250 coins'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test('toy payouts collect once; side losses do not; collection resumes', () {
    final state = PusherModel(saved: saved([], balance: 4)).toJson();
    state['coins'] = [
      [5, 12, 0, 0, 5, 0, 0, 1],
      [0, 12, 0, 0, 5, 0, 0, 2],
    ];
    final model = PusherModel(saved: state);
    expect(model.update(1 / 60), 5);
    expect(model.collection, {'bear': 1});
    expect(model.justCollected, ['Honey Bear']);
    expect(model.update(1 / 60), 0);
    expect(model.collection, {'bear': 1});
    expect(PusherModel(saved: model.toJson()).collection, {'bear': 1});
  });
  test('random toys are bounded and old sessions receive them only once', () {
    final model = PusherModel(saved: saved([], balance: 40));
    model.introducePrizes();
    expect(model.coins.where((c) => c.prize > 0).length, 3);
    expect(model.balance, 40);
    expect(model.coins.every((c) => c.radius > .4), isTrue);
    final restored = PusherModel(saved: model.toJson());
    restored.introducePrizes();
    expect(restored.coins.length, 3);
    expect(restored.toJson(), model.toJson());
  });
  test('coins stack, ride their support, and fall when it leaves', () {
    final state = saved([
      [5, 8, 0, 0, 1, 0, 0],
      [5, 8, 0, 0, 5, 1, 0],
    ])..['version'] = 2;
    final model = PusherModel(saved: state);
    for (var i = 0; i < 90; i++) {
      model.update(1 / 60);
    }
    final lower = model.coins[0], upper = model.coins[1];
    expect(upper.z, closeTo(PusherCoin.thickness, .001));
    expect((upper.body.position - lower.body.position).length, lessThan(.1));
    lower.body.linearVelocity.setValues(1, 0);
    for (var i = 0; i < 15; i++) {
      model.update(1 / 60);
    }
    expect(upper.body.position.x, greaterThan(5));
    final roundtrip = PusherModel(saved: model.toJson());
    expect(roundtrip.toJson(), model.toJson());
    lower.body.setTransform(lower.body.position.clone()..setValues(8, 8), 0);
    for (var i = 0; i < 60; i++) {
      model.update(1 / 60);
    }
    expect(upper.z, 0);
  });
  test('drop over an occupied spot succeeds and old saves gain height', () {
    final model = PusherModel(
      saved: saved([
        [5, 3, 0, 0, 1],
      ], balance: 2),
    );
    expect(model.coins.single.z, 0);
    expect(model.drop(5), isTrue);
    expect(model.coins.last.z, PusherModel.dropHeight);
    expect(model.toJson()['version'], 3);
  });
  test('front payouts occur once; sides never pay; bonus awards ten', () {
    final model = PusherModel(
      saved: saved([
        [5, 12, 0, 0, 5],
        [0, 12, 0, 0, 1],
      ], bonus: 19),
    );
    expect(model.update(1 / 60), 15);
    expect(model.balance, 15);
    expect(model.collected, 5);
    expect(model.bonus, 0);
    expect(model.coins, isEmpty);
    expect(model.update(1 / 60), 0);
  });
  test(
    'spending, cooldown, refill and roundtrip preserve economy and board',
    () {
      final model = PusherModel(saved: saved([], balance: 1));
      expect(model.drop(5), isTrue);
      expect(model.balance, 0);
      expect(model.drop(7), isFalse);
      expect(model.refill(), isTrue);
      expect(model.refill(), isFalse);
      for (var i = 0; i < 60; i++) {
        model.update(1 / 60);
      }
      final restored = PusherModel(saved: model.toJson());
      expect(restored.toJson(), model.toJson());
    },
  );
  test('crowded board stays finite through sustained pushing', () {
    final model = PusherModel();
    for (var i = 0; i < 3600; i++) {
      if (i % 30 == 0) model.drop(1 + (i ~/ 30 % 9));
      if (model.balance == 0) model.refill();
      model.update(1 / 60);
    }
    expect(model.coins.length, lessThanOrEqualTo(160));
    // Random piles need not pay out within a fixed time; verify stability.
    expect(model.balance, greaterThanOrEqualTo(0));
    expect(
      model.coins.every(
        (c) => c.body.position.x.isFinite && c.body.position.y.isFinite,
      ),
      isTrue,
    );
  });
  testWidgets('compact enlarged text screen loads, drops and pauses', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final settings = AppSettings(SharedPreferencesAsync());
    settings.soundOn.value = false;
    settings.hapticsOn.value = false;
    settings.reducedMotion.value = true;
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
        home: PusherScreen(settings: settings),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('40 coins'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('pusherDrop')));
    await tester.tap(find.byKey(const Key('pusherDrop')));
    await tester.pump();
    expect(find.text('39 coins'), findsOneWidget);
    await tester.tap(find.byTooltip('Reset board'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('39 coins'), findsOneWidget);
    await tester.tap(find.byTooltip('Reset board'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmPusherReset')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('40 coins'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Pause'));
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.byTooltip('Resume'), findsOneWidget);
    expect(find.text('Machine paused'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    final raw = await SharedPreferencesAsync().getString(
      'coin_pusher.session.v1',
    );
    expect(raw, contains('"balance":40'));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
