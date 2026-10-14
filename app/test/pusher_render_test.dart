import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import 'package:baka_games/games/coin_pusher/pusher_game.dart';
import 'package:baka_games/games/coin_pusher/pusher_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('animal sprites survive remount and board reset', (tester) async {
    final game = PusherGame(PusherModel(), (_) {}, () => true);
    addTearDown(game.disposeResources);
    Widget board() => Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(width: 360, height: 640, child: GameWidget(game: game)),
    );
    await tester.pumpWidget(board());
    await tester.runAsync(() async {
      await game.toBeLoaded();
    });
    await tester.pump();
    expect(game.toys.keys, containsAll(prizeIds));
    final bear = game.toys['bear'];
    await tester.pumpWidget(const SizedBox.shrink());
    game.model.resetBoard();
    await tester.pumpWidget(board());
    await tester.pump();
    expect(game.toys['bear'], same(bear));
    for (final animal in game.model.coins.where((coin) => coin.prize > 0)) {
      expect(game.toys[prizeIds[animal.prize - 1]], isNotNull);
    }
    expect(game.model.coins.where((coin) => coin.prize > 0), hasLength(3));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    game.disposeResources();
    expect(game.toys, isEmpty);
  });

  test('all coin faces render without aborting the frame', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    try {
      for (final value in [1, 5, 10, 25]) {
        drawSolidCoin(canvas, 5, 7, 0, value);
      }
      drawSolidCoin(canvas, 5, 7, 0, 25, mega: true);
      for (final rare in [RareCoin.rainbow, RareCoin.heart]) {
        drawSolidCoin(canvas, 5, 7, 0, 1, rare: rare);
      }
    } finally {
      recorder.endRecording().dispose();
    }
  });
}
