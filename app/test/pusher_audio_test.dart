import 'package:baka_games/games/coin_pusher/pusher_audio.dart';
import 'package:baka_games/games/coin_pusher/pusher_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nearby coins build cascades, then reset after a quiet gap', () {
    final sounds = <String>[];
    final mixer = PusherSoundMixer(sounds.add);
    mixer.update(.1, ['collect']);
    mixer.update(.1, ['collect']);
    mixer.update(.1, ['collect', 'collect', 'collect']);
    mixer.update(.7, ['collect']);
    expect(sounds, ['collect', 'cascade', 'cascade_big', 'collect']);
  });

  test('batch duplicate effects without losing toy and side distinctions', () {
    final sounds = <String>[];
    final mixer = PusherSoundMixer(sounds.add);
    mixer.update(.04, ['side', 'side', 'toy_side']);
    expect(sounds, isEmpty);
    mixer.update(.06, ['toy_collect', 'reward_spawn']);
    expect(sounds, ['side', 'toy_side', 'toy_collect', 'reward_spawn']);
    mixer.update(.01, ['collect']);
    mixer.clear();
    mixer.update(.1, []);
    expect(sounds, hasLength(4));
  });

  test(
    'physics distinguishes front coins, toys, valuables and side losses',
    () {
      final model = PusherModel(
      saved: {
        ...PusherModel().toJson(),
          'version': 3,
          'balance': 40,
          'collected': 0,
          'bonus': 0,
          'drops': 0,
          'phase': 0,
          'coins': [
            [2, 12, 0, 0, 1, 0, 0, 0],
            [4, 12, 0, 0, 5, 0, 0, 1],
            [6, 12, 0, 0, 10, 0, 0, 0],
            [-1, 8, 0, 0, 1, 0, 0, 0],
            [11, 8, 0, 0, 5, 0, 0, 2],
          ],
        },
      );
      model.update(1 / 60);
      expect(
        model.soundEvents,
        containsAll(['collect', 'toy_collect', 'valuable', 'side', 'toy_side']),
      );
      expect(model.toJson().containsKey('soundEvents'), isFalse);
    },
  );
}
