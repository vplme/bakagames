import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openGameMenu(WidgetTester tester) async {
  if (find.byTooltip('Game menu').evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('gameMenu')));
    await tester.pump();
  }
}

Future<void> closeGameMenu(WidgetTester tester) async {
  if (find.byTooltip('Close menu').evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('gameMenu')));
    await tester.pump();
  }
}
