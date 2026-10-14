import 'package:baka_games/games/coin_pusher/pusher_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> board(List<List<num>> coins) => {
  'version': 3,
  'randomState': 700,
  'prizesIntroduced': true,
  'collection': <String, dynamic>{},
  'balance': 40,
  'collected': 0,
  'bonus': 0,
  'drops': 0,
  'phase': 0,
  'coins': coins,
};

void main() {
  test('rainbow doubles tray values and bonus, refreshes and expires', () {
    final model = PusherModel(
      saved: board([
        [5, 12, 0, 0, 1, 0, 0, 0, 2],
      ])..['bonus'] = 19,
    );
    expect(model.update(1 / 60), 22);
    expect(model.rainbowRemaining, 60);
    expect(model.collected, 2);
    final restored = PusherModel(saved: model.toJson());
    expect(restored.rainbowRemaining, 60);
    for (var i = 0; i < 3601; i++) {
      restored.update(1 / 60);
    }
    expect(restored.earningsMultiplier, 1);
    final refresh = PusherModel(
      saved: board([
        [5, 12, 0, 0, 1, 0, 0, 0, 2],
      ])..['rainbowRemaining'] = 20,
    );
    refresh.update(1 / 60);
    expect(refresh.rainbowRemaining, 60);
    refresh.resetBoard();
    expect(refresh.rainbowRemaining, 0);
  });

  test('heart fills partially charged boost and triggers one perk', () {
    final model = PusherModel(
      saved: board([
        [5, 12, 0, 0, 1, 0, 0, 0, 3],
      ])..['boostCharge'] = 57,
    );
    expect(model.update(1 / 60), 1);
    expect(model.boostCharge, 0);
    expect(model.lastPerk, 'Coin shower');
    expect(model.pendingShowerCoins + model.coins.length, 40);
    expect(model.comboCoins, 0);
  });

  test('side losses activate neither rare effect', () {
    final model = PusherModel(
      saved: board([
        [0, 6, 0, 0, 1, 0, 0, 0, 2],
        [0, 9, 0, 0, 1, 0, 0, 0, 3],
      ]),
    );
    expect(model.update(1 / 60), 0);
    expect(model.rainbowRemaining, 0);
    expect(model.boostCharge, 2);
    expect(model.lastPerk, isNull);
  });

  test('rare identities round trip and old coins still load', () {
    final model = PusherModel(
      saved: board([
        [3, 7, 0, 0, 1, 0, 0, 0, 2],
        [5, 7, 0, 0, 1, 0, 0, 0, 3],
        [7, 7, 0, 0, 1, 0, 0, 0],
      ]),
    );
    final restored = PusherModel(saved: model.toJson());
    expect(restored.coins.map((c) => c.rare), [
      RareCoin.rainbow,
      RareCoin.heart,
      RareCoin.none,
    ]);
    expect(restored.toJson(), model.toJson());
  });

  test('invalid rare saves are rejected', () {
    for (final duration in [-1, 61, double.nan]) {
      expect(
        () => PusherModel(saved: board([])..['rainbowRemaining'] = duration),
        throwsFormatException,
      );
    }
    expect(
      () => PusherModel(
        saved: board([
          [5, 7, 0, 0, 25, 0, 0, 0, 2],
        ]),
      ),
      throwsFormatException,
    );
  });

  test('paid drops produce both rare types at their intended frequencies', () {
    final model = PusherModel(saved: board([]));
    var hearts = 0, rainbows = 0;
    for (var i = 0; i < 10000; i++) {
      model.balance = 1;
      model.cooldown = 0;
      expect(model.drop(5), isTrue);
      hearts += model.coins.first.rare == RareCoin.heart ? 1 : 0;
      rainbows += model.coins.first.rare == RareCoin.rainbow ? 1 : 0;
      for (final coin in model.coins) {
        model.world.destroyBody(coin.body);
      }
      model.coins.clear();
    }
    expect(hearts, inInclusiveRange(8, 35));
    expect(rainbows, inInclusiveRange(70, 130));
  });
}
