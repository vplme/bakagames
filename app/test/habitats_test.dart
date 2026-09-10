import 'dart:ui' as ui;

import 'package:baka_games/games/bird_sort/aviary.dart';
import 'package:baka_games/games/bird_sort/aviary_levels.dart';
import 'package:baka_games/games/bird_sort/bird_sort_game.dart';
import 'package:baka_games/games/bird_sort/play_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('long habitat name fits a compact phone with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: const TextScaler.linear(1.3),
          ),
          child: child!,
        ),
        home: BirdSortPlayScreen(
          levelIndex: 450,
          debugLevel: aviaryLevelFor(450),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('BOUGAINVILLEA COURTYARD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'every ten-level habitat has distinct, decodable bundled artwork',
    () async {
      final chapters = (BirdSortDefinition().levelCount / 10).ceil();
      expect(aviaryHabitats, hasLength(chapters));
      final assets = <String>{};
      final names = <String>{};
      for (var chapter = 0; chapter < chapters; chapter++) {
        final level = chapter * 10;
        final asset = habitatAsset(level);
        expect(assets.add(asset), isTrue, reason: 'habitat ${chapter + 1}');
        expect(names.add(habitatName(level)), isTrue);
        expect(habitatAsset(level + 9), asset);
        expect(habitatName(level + 9), habitatName(level));
        final data = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 768, reason: asset);
        expect(frame.image.height, 1152, reason: asset);
        frame.image.dispose();
        codec.dispose();
      }
      expect(habitatAsset(0), 'assets/aviary/garden.webp');
      expect(habitatAsset(10), 'assets/aviary/cherry.webp');
      expect(habitatAsset(20), 'assets/aviary/moon.webp');
      expect(habitatName(499), 'Rainbow valley');
    },
  );
}
