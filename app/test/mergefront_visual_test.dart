import 'dart:io';
import 'dart:ui' as ui;
import 'package:baka_games/games/mergefront/art.dart';
import 'package:baka_games/games/mergefront/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Optional local visual review artifacts, not golden-image assertions.
// MERGEFRONT_CAPTURE=1 flutter test test/mergefront_visual_test.dart
void main() {
  testWidgets('all role ranks and live coastal battle paint without errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final capture = Platform.environment['MERGEFRONT_CAPTURE'] == '1';
    if (capture) {
      final font = File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
      if (font.existsSync()) {
        final loader = FontLoader('Roboto')
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
        await tester.runAsync(loader.load);
      }
    }
    final run = Run(Level.all.first, Profile().loadout)..steer(.27);
    for (var i = 0; i < 7 * 60; i++) {
      run.step(1 / 60);
    }
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundary,
          child: Scaffold(
            backgroundColor: cream,
            body: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'SQUAD RUSHER • ORIGINAL TOY KIT',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      for (final role in Role.values)
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(width: 65, child: Text(role.label)),
                              for (var tier = 1; tier <= 6; tier++)
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      UnitPortrait(role, tier),
                                      Text('$tier'),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 190, child: MergefrontPreview()),
                    ],
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: CustomPaint(
                    painter: BattlefieldPainter(run, reduced: true),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    if (capture) {
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/tmp/mergefront-visual.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
  testWidgets('every mission setting paints in preview and combat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    expect(
      Level.all.map((level) => level.style).toSet(),
      BattlefieldStyle.values.toSet(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundary,
          child: Scaffold(
            body: Row(
              children: [
                for (final style in BattlefieldStyle.values)
                  Expanded(
                    child: Column(
                      children: [
                        Text(style.label),
                        SizedBox(
                          height: 150,
                          child: MergefrontPreview(
                            level: Level.all.firstWhere(
                              (level) => level.style == style,
                            ),
                          ),
                        ),
                        Expanded(
                          child: CustomPaint(
                            painter: BattlefieldPainter(
                              Run(
                                Level.all.firstWhere(
                                  (level) => level.style == style,
                                ),
                                Profile().loadout,
                              )..step(.1),
                              reduced: false,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    if (Platform.environment['MERGEFRONT_CAPTURE'] == '1') {
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/tmp/squad-rusher-settings.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
