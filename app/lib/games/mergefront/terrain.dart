import 'dart:math';
import 'package:flutter/material.dart';
import 'model.dart';

/// Decorative scenery stays outside the playable lanes. No simulation randomness.
void paintTerrain(
  Canvas canvas,
  Size size,
  BattlefieldStyle style,
  double scroll,
) {
  final w = size.width, h = size.height;
  final (surround, ground, trim, detail) = switch (style) {
    BattlefieldStyle.garden => (0xFF235A49, 0xFFCAD3AB, 0xFF718965, 0xFF93BE73),
    BattlefieldStyle.desert => (0xFFC98A54, 0xFFF0D4A1, 0xFFB78C60, 0xFFE9B676),
    BattlefieldStyle.foundry => (
      0xFF293E50,
      0xFFACB8BC,
      0xFF526977,
      0xFFE9A65B,
    ),
    BattlefieldStyle.harbor => (0xFF192F54, 0xFF9BAFC4, 0xFF4F6684, 0xFF88CFE0),
    BattlefieldStyle.coast => (0xFF359FAF, 0xFFE8D5AA, 0xFF98896C, 0xFF88DCD0),
  };
  final p = Paint();
  void box(
    double x,
    double y,
    double width,
    double height,
    int color, [
    double radius = 0,
  ]) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, height),
        Radius.circular(radius),
      ),
      p..color = Color(color),
    );
  }

  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(surround),
          Color.lerp(Color(surround), Color(detail), .25)!,
        ],
      ).createShader(Offset.zero & size),
  );
  for (var i = -1; i < (h / 112).ceil() + 1; i++) {
    final y = i * 112.0 + scroll % 112;
    for (final x in [w * .035, w * .965]) {
      switch (style) {
        case BattlefieldStyle.garden:
          for (var leaf = 0; leaf < 5; leaf++) {
            canvas.drawCircle(
              Offset(x + cos(leaf * 1.26) * 10, y + sin(leaf * 1.26) * 17),
              13,
              p..color = Color(leaf.isEven ? detail : 0xFF398164),
            );
          }
          canvas.drawCircle(
            Offset(x, y),
            4,
            p..color = const Color(0xFFF2C780),
          );
        case BattlefieldStyle.desert:
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, y), width: 52, height: 90),
            p..color = Color(detail),
          );
          final rock = Path()
            ..moveTo(x - 12, y + 35)
            ..lineTo(x - 7, y + 13)
            ..lineTo(x + 8, y + 9)
            ..lineTo(x + 17, y + 35)
            ..close();
          canvas.drawPath(rock, p..color = Color(trim));
        case BattlefieldStyle.foundry:
          box(x - 5, y, 10, 90, trim, 3);
          for (var j = 0; j < 3; j++) {
            box(x - 8, y + 12 + j * 26, 16, 5, detail, 2);
          }
        case BattlefieldStyle.harbor:
          for (var j = 0; j < 4; j++) {
            box(x - 12, y + j * 18, 18 + j * 3, 2, j.isEven ? trim : detail, 2);
          }
        case BattlefieldStyle.coast:
          break;
      }
    }
  }
  box(w * .08 + 4, 0, w * .84, h, 0x440B2033);
  box(w * .08, 0, w * .84, h, trim);
  box(w * .12, 0, w * .76, h, ground);
  canvas.save();
  canvas.clipRect(Rect.fromLTWH(w * .12, 0, w * .76, h));
  for (var i = -1; i < (h / 96).ceil() + 1; i++) {
    final y = i * 96.0 + scroll % 96;
    if (style == BattlefieldStyle.foundry) {
      box(w * .12, y, w * .76, 3, trim);
      for (final x in [.16, .84]) {
        canvas.drawCircle(Offset(w * x, y + 9), 2, p..color = Color(trim));
        box(w * x - 3, y + 37, 6, 22, detail);
      }
      box(w * .5, y, 1, 96, trim);
    } else if (style == BattlefieldStyle.harbor) {
      for (var plank = 0; plank < 4; plank++) {
        box(w * .12, y + plank * 24, w * .76, 1, trim);
        box(w * (.25 + plank % 2 * .5), y + plank * 24, 1, 24, trim);
      }
    } else {
      box(w * .12, y, w * .76, 2, trim);
      box(w * (i.isEven ? .38 : .62), y, 2, 96, trim);
      if (style == BattlefieldStyle.garden) {
        box(w * .12, y + 2, 5, 40, detail, 3);
        box(w * .86, y + 45, 7, 30, detail, 3);
      } else {
        for (var grain = 0; grain < 6; grain++) {
          box(
            w * (.18 + grain * .12),
            y + 25 + grain % 3 * 13,
            3,
            2,
            detail,
            1,
          );
        }
      }
    }
  }
  canvas.restore();
  for (var i = -1; i < (h / 144).ceil() + 1; i++) {
    final y = i * 144.0 + scroll % 144;
    for (final x in [w * .09, w * .91]) {
      box(x - 5, y, 10, 110, trim, 3);
      box(x - 6, y + 110, 12, 18, ground, 3);
      if (style == BattlefieldStyle.harbor ||
          style == BattlefieldStyle.foundry) {
        canvas.drawCircle(
          Offset(x, y + 116),
          10,
          p..color = Color(detail).withValues(alpha: .16),
        );
        box(x - 3, y + 113, 6, 5, detail, 2);
      }
    }
  }
}
