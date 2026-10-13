import 'package:baka_games/games/coin_pusher/pusher_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> board({
  int charge = PusherModel.boostTarget - 1,
  int seed = 700,
}) => {
  'version': 3,
  'randomState': seed,
  'prizesIntroduced': true,
  'collection': <String, dynamic>{},
  'balance': 0,
  'collected': 0,
  'bonus': 0,
  'drops': 0,
  'phase': 0,
  'boostCharge': charge,
  'coins': [
    [5, 12, 0, 0, 1, 0, 0, 0],
  ],
};

void main() {
  test('animal and side falls charge boost with overflow preserved', () {
    final state = board(charge: PusherModel.boostTarget - 3);
    state['coins'] = [
      [0, 8, 0, 0, 5, 0, 0, 1],
      [5, 12, 0, 0, 1, 0, 0, 0],
    ];
    final model = PusherModel(saved: state);
    expect(model.update(1 / 60), 1);
    expect(model.boostCharge, 2);
    expect(model.justRewards, hasLength(1));
    expect(model.collection, isEmpty);
  });

  test('shower awards forty physical coins for free and resumes', () {
    final model = PusherModel(saved: board());
    model.update(1 / 60);
    expect(model.lastPerk, 'Coin shower');
    expect(model.pendingShowerCoins + model.coins.length, 40);
    expect(model.balance, 1);
    final restored = PusherModel(saved: model.toJson());
    expect(restored.toJson(), model.toJson());
    for (var i = 0; i < 300; i++) {
      restored.update(1 / 60);
    }
    expect(restored.pendingShowerCoins, 0);
    expect(restored.coins.length, 40);
    expect(restored.balance, 1);
  });

  test('turbo doubles paddle phase speed and expires after ten seconds', () {
    final model = PusherModel(saved: board(seed: 0));
    model.update(1 / 60);
    expect(model.lastPerk, 'Turbo pusher');
    expect(model.turboRemaining, 10);
    final restored = PusherModel(saved: model.toJson());
    final phase = restored.phase;
    restored.update(1 / 60);
    expect(restored.phase - phase, closeTo(3.2 / 60, .00001));
    for (var i = 0; i < 601; i++) {
      restored.update(1 / 60);
    }
    expect(restored.turboRemaining, 0);
    final normalPhase = restored.phase;
    restored.update(1 / 60);
    expect(restored.phase - normalPhase, closeTo(1.6 / 60, .00001));
  });

  test('mega coin survives save and pays twenty-five exactly once', () {
    final model = PusherModel(saved: board(seed: 300));
    model.update(1 / 60);
    expect(model.lastPerk, 'Mega coin');
    final restored = PusherModel(saved: model.toJson());
    final mega = restored.coins.single;
    expect(mega.isMegaCoin, isTrue);
    expect(mega.isGoldBar, isFalse);
    expect(mega.radius, .85);
    mega.body.setTransform(mega.body.position.clone()..setValues(5, 12), 0);
    expect(restored.update(1 / 60), 25);
    expect(restored.update(1 / 60), 0);
    expect(restored.balance, 26);
    expect(restored.comboCoins, 1);
  });

  test('queued shower waits for capacity and reset clears perks', () {
    final state = board(charge: 0);
    state['coins'] = [
      for (var i = 0; i < PusherModel.maxBoardCoins; i++)
        [1 + i % 20 * .42, 4 + i ~/ 20 * .4, 0, 0, 1, 0, 0, 0],
    ];
    state['pendingShowerCoins'] = 40;
    final model = PusherModel(saved: state);
    model.update(1 / 60);
    expect(model.coins.length, PusherModel.maxBoardCoins);
    expect(model.pendingShowerCoins, 40);
    expect(PusherModel(saved: model.toJson()).pendingShowerCoins, 40);
    model.resetBoard();
    expect(model.boostCharge, 0);
    expect(model.pendingShowerCoins, 0);
    expect(model.pendingMegaCoins, 0);
    expect(model.turboRemaining, 0);
    expect(model.lastPerk, isNull);
  });

  test('invalid saved boost progress is rejected', () {
    for (final entry in {
      'boostCharge': PusherModel.boostTarget,
      'pendingShowerCoins': -1,
      'pendingMegaCoins': -1,
      'turboRemaining': double.nan,
      'showerCooldown': -1,
    }.entries) {
      expect(
        () => PusherModel(saved: board()..[entry.key] = entry.value),
        throwsFormatException,
      );
    }
  });
}
