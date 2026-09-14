import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'pusher_model.dart';

const gold = Color(0xFFFFCF65);
const teal = Color(0xFF59775C);

/// Oblique perspective with a height axis, shared by all cabinet geometry.
Offset projectCoin(double x, double y, double z) =>
    Offset(6 + (x - 5) * (.60 + y * .03), 3 + y * .72 - z * .85);

double aimFromBoard(double screenX, double width, double y) =>
    (5 + (screenX / width * 12 - 6) / (.60 + y * .03)).clamp(
      PusherModel.dropMinX,
      PusherModel.dropMaxX,
    );

// Raising an object does not bring it in front of a nearer object. Height
// orders vertically stacked objects only when their depth is identical.
int comparePusherDepth(PusherCoin a, PusherCoin b) {
  final depth = a.body.position.y.compareTo(b.body.position.y);
  return depth != 0 ? depth : a.z.compareTo(b.z);
}

void paintCabinet(
  Canvas canvas,
  Size size,
  PusherModel model, {
  Map<String, Image> toys = const {},
  void Function(Canvas canvas)? paintFalling,
}) {
  canvas.save();
  canvas.scale(size.width / 12, size.height / 15);
  final paint = Paint();
  void face(List<Offset> points, List<Color> colors) {
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(
      path,
      paint
        ..color = const Color(0xFFFFFFFF)
        ..shader = Gradient.linear(
          points.first,
          points[points.length ~/ 2],
          colors,
        ),
    );
    paint.shader = null;
  }

  void plane(
    double left,
    double back,
    double right,
    double front,
    double z,
    List<Color> colors,
  ) => face([
    projectCoin(left, back, z),
    projectCoin(right, back, z),
    projectCoin(right, front, z),
    projectCoin(left, front, z),
  ], colors);
  void label(String text, double y, double fontSize, Color color) {
    // Lay out text at pixel scale so sub-unit cabinet coordinates do not
    // collapse glyph spacing or font hinting on compact screens.
    const textScale = 64.0;
    final p =
        ParagraphBuilder(
            ParagraphStyle(
              fontFamily: 'sans-serif',
              fontSize: fontSize * textScale,
              textAlign: TextAlign.center,
            ),
          )
          ..pushStyle(TextStyle(color: color, fontWeight: FontWeight.w800))
          ..addText(text);
    canvas.save();
    canvas.translate(0, y);
    canvas.scale(1 / textScale);
    canvas.drawParagraph(
      p.build()..layout(const ParagraphConstraints(width: 12 * textScale)),
      Offset.zero,
    );
    canvas.restore();
  }

  void edge(Offset a, Offset b, Color color, [double width = .045]) {
    canvas.drawLine(
      a,
      b,
      paint
        ..color = color
        ..strokeWidth = width,
    );
  }

  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 12, 15),
    paint
      ..shader = Gradient.linear(Offset.zero, const Offset(12, 15), [
        const Color(0xFFFFF3DF),
        const Color(0xFFF1D4BB),
      ]),
  );
  paint.shader = null;
  void rounded(Rect rect, double radius, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint..color = color,
    );
  }

  // A little enamel toy-shop sign, with a bear mascot and piped cream trim.
  rounded(
    const Rect.fromLTWH(1.1, .38, 9.8, 1.95),
    .65,
    const Color(0xFFC28C80),
  );
  rounded(
    const Rect.fromLTWH(1.1, .25, 9.8, 1.95),
    .65,
    const Color(0xFFFFF3DA),
  );
  rounded(
    const Rect.fromLTWH(1.22, .37, 9.56, 1.7),
    .55,
    const Color(0xFFF3B8B0),
  );
  label('Pocket Pusher', .61, .65, const Color(0xFF754F53));
  label('tiny treasures, happy hearts', 1.42, .26, const Color(0xFF754F53));
  for (final x in [1.95, 10.05]) {
    for (final dx in [-.24, .24]) {
      canvas.drawCircle(
        Offset(x + dx, .92),
        .19,
        paint..color = const Color(0xFFD39D70),
      );
      canvas.drawCircle(
        Offset(x + dx, .92),
        .10,
        paint..color = const Color(0xFFF3B8B0),
      );
    }
    rounded(
      Rect.fromCenter(center: Offset(x, 1.23), width: .76, height: .67),
      .28,
      const Color(0xFFF5D5A0),
    );
    for (final dx in [-.15, .15]) {
      canvas.drawCircle(
        Offset(x + dx, 1.19),
        .035,
        paint..color = const Color(0xFF754F53),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + dx * 1.5, 1.31),
          width: .13,
          height: .075,
        ),
        paint..color = const Color(0xFFEDA6A0),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, 1.32), width: .09, height: .065),
      paint..color = const Color(0xFF754F53),
    );
  }
  // A dark well surrounds the supported playfield. Its floor is lower
  // than the tabletop, with exposed vertical walls at the loss edges.
  plane(-1, 0, 11, 12, -1.15, [
    const Color(0xFF4B4B59),
    const Color(0xFF697279),
  ]);
  for (final x in [.25, 9.75]) {
    face(
      [
        projectCoin(x, 0, 0),
        projectCoin(x, 11.5, 0),
        projectCoin(x, 11.5, -1.15),
        projectCoin(x, 0, -1.15),
      ],
      [const Color(0xFF78858A), const Color(0xFF454653)],
    );
  }
  plane(.25, 0, 9.75, 11.5, 0, [
    const Color(0xFFBDD9B0),
    const Color(0xFF8CB69C),
  ]);
  for (var y = 1.0; y < 11.5; y += 1) {
    canvas.drawLine(
      projectCoin(.25, y, 0),
      projectCoin(9.75, y, 0),
      paint
        ..color = const Color(0x3389A978)
        ..strokeWidth = .02,
    );
  }
  // Bright edges separate the felt surface from the deep loss channels.
  for (final x in [.25, 9.75]) {
    edge(
      projectCoin(x, 0, .015),
      projectCoin(x, 11.5, .015),
      const Color(0xFFE5C58C),
      .065,
    );
  }
  const paddleLeft = PusherModel.pusherLeft;
  const paddleRight = PusherModel.pusherRight;
  final paddleFront = model.pusherY + PusherModel.pusherHalfDepth;
  // Stationary shoulders frame the narrow rear opening and flare out toward
  // the full-width coin bed. They sit outside the paddle's travel path.
  for (final right in [false, true]) {
    Offset shoulder(double x, double y, double z) =>
        projectCoin(right ? 10 - x : x, y, z);
    face(
      [
        shoulder(-.1, 0, .68),
        shoulder(1.85, 0, .68),
        shoulder(1.85, 3.6, .68),
        shoulder(-.1, 5.2, .68),
      ],
      [const Color(0xFFFFEBD0), const Color(0xFFF0BDB0)],
    );
    face(
      [
        shoulder(1.85, 0, .68),
        shoulder(1.85, 3.6, .68),
        shoulder(-.1, 5.2, .68),
        shoulder(-.1, 5.2, 0),
        shoulder(1.85, 3.6, 0),
        shoulder(1.85, 0, 0),
      ],
      [const Color(0xFFC49389), const Color(0xFF946F72)],
    );
    edge(
      shoulder(1.85, 0, .69),
      shoulder(1.85, 3.6, .69),
      const Color(0xFFFFF4DC),
      .07,
    );
    edge(
      shoulder(1.85, 3.6, .69),
      shoulder(-.1, 5.2, .69),
      const Color(0xFFFFF4DC),
      .07,
    );
  }
  plane(paddleLeft, 0, paddleRight, paddleFront, .6, [
    const Color(0xFFFFE9C1),
    const Color(0xFFDBAD84),
  ]);
  face(
    [
      projectCoin(paddleLeft, paddleFront, .6),
      projectCoin(paddleRight, paddleFront, .6),
      projectCoin(paddleRight, paddleFront, 0),
      projectCoin(paddleLeft, paddleFront, 0),
    ],
    [const Color(0xFFFFF0CB), const Color(0xFFB48465)],
  );
  for (var y = .4; y < model.pusherY; y += .35) {
    canvas.drawLine(
      projectCoin(paddleLeft + .15, y, .61),
      projectCoin(paddleRight - .15, y + .1, .61),
      paint
        ..color = const Color(0x33734F2B)
        ..strokeWidth = .025,
    );
  }
  // Cast shadows before the depth-sorted solid coins.
  for (final c in model.coins) {
    final pos = c.body.position;
    final scale = .60 + pos.y * .03;
    canvas.drawOval(
      Rect.fromCenter(
        center: projectCoin(pos.x + .12 + c.z * .12, pos.y + .12, 0),
        width: c.radius * 2.2 * scale,
        height: c.radius * 1.2 * scale,
      ),
      paint..color = const Color(0x444D3C49),
    );
  }
  final sorted = [...model.coins]..sort(comparePusherDepth);
  for (final c in sorted) {
    if (c.prize > 0) {
      drawPrize(
        canvas,
        c.body.position.x,
        c.body.position.y,
        c.z,
        toys[prizeIds[c.prize - 1]],
      );
    } else {
      drawSolidCoin(canvas, c.body.position.x, c.body.position.y, c.z, c.value);
    }
  }
  // The payout opening exposes the tabletop thickness and a lower tray.
  face(
    [
      projectCoin(.25, 11.5, 0),
      projectCoin(9.75, 11.5, 0),
      projectCoin(9.75, 11.5, -.45),
      projectCoin(.25, 11.5, -.45),
    ],
    [const Color(0xFFFFE1B3), const Color(0xFFAC7E64)],
  );
  edge(
    projectCoin(.25, 11.5, .02),
    projectCoin(9.75, 11.5, .02),
    const Color(0xFFFFE5AA),
    .09,
  );
  face(
    [
      const Offset(.65, 11.65),
      const Offset(11.35, 11.65),
      const Offset(10.65, 13.7),
      const Offset(1.35, 13.7),
    ],
    [const Color(0xFF4B4B59), const Color(0xFF9BC3B3)],
  );
  face(
    [
      const Offset(.65, 11.65),
      const Offset(1.35, 13.7),
      const Offset(1.35, 12.95),
      const Offset(.65, 11.1),
    ],
    [const Color(0xFFE6BA9A), const Color(0xFFA37C79)],
  );
  face(
    [
      const Offset(11.35, 11.65),
      const Offset(10.65, 13.7),
      const Offset(10.65, 12.95),
      const Offset(11.35, 11.1),
    ],
    [const Color(0xFFA37C79), const Color(0xFFF5D8AE)],
  );
  label('Treasures land here', 12.45, .34, const Color(0xFFFFF5DF));

  // Falling objects pass behind the solid cabinet rails and tray lip.
  paintFalling?.call(canvas);
  for (final x in [-1.15, 10.85]) {
    face(
      [
        projectCoin(x, 0, .5),
        projectCoin(x, 12, .5),
        projectCoin(x, 12, -1.15),
        projectCoin(x, 0, -1.15),
      ],
      [const Color(0xFFF3C8AA), const Color(0xFFB78776)],
    );
    plane(x, 0, x + .3, 12, .5, [
      const Color(0xFFFFF0D0),
      const Color(0xFFD4A087),
    ]);
    edge(
      projectCoin(x, 0, .51),
      projectCoin(x, 12, .51),
      const Color(0xFFFFE9BA),
    );
  }
  // Close the ends of both side channels with solid cabinet cheeks.
  // These join the rail ends to the tray lip, hiding the exposed well corners.
  for (final right in [false, true]) {
    Offset mirror(Offset p) => right ? Offset(12 - p.dx, p.dy) : p;
    face(
      [
        mirror(const Offset(.10, 11.12)),
        mirror(const Offset(.65, 11.1)),
        mirror(const Offset(1.35, 13.05)),
        mirror(const Offset(.55, 13.3)),
        mirror(const Offset(.10, 12.65)),
      ],
      [const Color(0xFFFFE6C4), const Color(0xFFD8A58F)],
    );
    edge(
      mirror(const Offset(.65, 11.1)),
      mirror(const Offset(1.35, 13.05)),
      const Color(0xFFFFF1D5),
      .07,
    );
  }
  face(
    [
      const Offset(.55, 13.3),
      const Offset(11.45, 13.3),
      const Offset(11.45, 14.6),
      const Offset(.55, 14.6),
    ],
    [const Color(0xFFF2BCB0), const Color(0xFFCF918E)],
  );
  face(
    [
      const Offset(.55, 13.3),
      const Offset(1.35, 13.05),
      const Offset(10.65, 13.05),
      const Offset(11.45, 13.3),
    ],
    [const Color(0xFFFFF0D6), const Color(0xFFE6BAA0)],
  );
  edge(
    const Offset(.55, 13.3),
    const Offset(11.45, 13.3),
    const Color(0xFFFFE8BF),
    .07,
  );
  // Hand-painted daisies on the wooden front corners.
  for (final x in [1.05, 10.95]) {
    final center = Offset(x, 13.7);
    canvas.drawLine(
      center + const Offset(0, .15),
      center + const Offset(.08, .65),
      paint
        ..color = const Color(0xFF648459)
        ..strokeWidth = .055,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + const Offset(.16, .4),
        width: .28,
        height: .12,
      ),
      paint..color = const Color(0xFF819866),
    );
    for (var i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * .15,
        .12,
        paint..color = const Color(0xFFFFF0D1),
      );
    }
    canvas.drawCircle(center, .085, paint..color = gold);
  }
  rounded(
    const Rect.fromLTWH(2.65, 13.53, 6.7, .78),
    .35,
    const Color(0xFFFFEEDA),
  );
  label('Your treasure pocket', 13.66, .40, const Color(0xFF80585B));
  label(
    'Side gaps lose • Front tray collects',
    14.65,
    .24,
    const Color(0xFF533928),
  );
  canvas.restore();
}

void drawPrize(Canvas canvas, double x, double y, double z, Image? sprite) {
  if (sprite == null) return;
  final foot = projectCoin(x, y, z);
  final width = 1.85 * (.60 + y * .03);
  final height = width * sprite.height / sprite.width;
  canvas.drawImageRect(
    sprite,
    Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
    Rect.fromLTWH(foot.dx - width / 2, foot.dy - height, width, height),
    Paint()..filterQuality = FilterQuality.medium,
  );
}

void drawSolidCoin(Canvas canvas, double x, double y, double z, int value) {
  if (value == 25) {
    drawGoldBar(canvas, x, y, z);
    return;
  }
  final p = projectCoin(x, y, z + PusherCoin.thickness);
  final scale = (.60 + y * .03) * (value == 10 ? 1.625 : 1);
  final rect = Rect.fromCenter(
    center: p,
    width: .8 * scale,
    height: .46 * scale,
  );
  final paint = Paint();
  final blue = value == 5;
  final dark = blue ? const Color(0xFF267B8A) : const Color(0xFF98601D);
  final light = blue ? const Color(0xFFD6FFFF) : const Color(0xFFFFF1AF);
  final mid = blue ? const Color(0xFF65CDDA) : gold;
  final base = rect.shift(const Offset(0, PusherCoin.thickness * .85));
  canvas.drawOval(base, paint..color = dark);
  canvas.drawRect(
    Rect.fromLTRB(rect.left, rect.center.dy, rect.right, base.center.dy),
    paint..color = dark,
  );
  for (var i = 1; i < 8; i++) {
    final xx = rect.left + rect.width * i / 8;
    canvas.drawLine(
      Offset(xx, rect.center.dy + .08),
      Offset(xx, base.center.dy + .07),
      paint
        ..color = mid
        ..strokeWidth = .016,
    );
  }
  canvas.drawOval(
    rect,
    paint
      ..shader = Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [light, mid, dark],
        [0, .55, 1],
      ),
  );
  paint.shader = null;
  canvas.drawOval(
    rect.deflate(.065 * scale),
    paint
      ..color = light
      ..style = PaintingStyle.stroke
      ..strokeWidth = .018,
  );
  canvas.drawOval(
    rect.deflate(.12 * scale),
    paint
      ..color = dark
      ..strokeWidth = .014,
  );
  paint.style = PaintingStyle.fill;
  final star = Path()
    ..moveTo(p.dx, p.dy - .10 * scale)
    ..lineTo(p.dx + .10 * scale, p.dy)
    ..lineTo(p.dx, p.dy + .10 * scale)
    ..lineTo(p.dx - .10 * scale, p.dy)
    ..close();
  canvas.drawPath(star, paint..color = light);
}

void drawGoldBar(Canvas canvas, double x, double y, double z) {
  Offset point(double dx, double dy, double dz) =>
      projectCoin(x + dx, y + dy, z + dz);
  final top = [
    point(-.68, -.3, .38),
    point(.68, -.3, .38),
    point(.68, .3, .38),
    point(-.68, .3, .38),
  ];
  final base = [
    point(-.8, -.4, 0),
    point(.8, -.4, 0),
    point(.8, .4, 0),
    point(-.8, .4, 0),
  ];
  final paint = Paint();
  void face(List<Offset> points, Color light, Color dark) {
    canvas.drawPath(
      Path()..addPolygon(points, true),
      paint..shader = Gradient.linear(points.first, points[2], [light, dark]),
    );
    paint.shader = null;
  }

  face(
    [top[1], base[1], base[2], top[2]],
    const Color(0xFFD99832),
    const Color(0xFF966020),
  );
  face(
    [top[3], top[2], base[2], base[3]],
    const Color(0xFFEAB64B),
    const Color(0xFFA66D22),
  );
  face(top, const Color(0xFFFFF0AF), gold);
  canvas.drawPath(
    Path()..addPolygon(top, true),
    paint
      ..color = const Color(0xFFFFF5C6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .035,
  );
  paint.style = PaintingStyle.fill;
  final center = point(0, 0, .39);
  canvas.drawOval(
    Rect.fromCenter(center: center, width: .44, height: .20),
    paint..color = const Color(0xFFC18A32),
  );
  canvas.drawOval(
    Rect.fromCenter(center: center, width: .32, height: .12),
    paint..color = const Color(0xFFFFE79E),
  );
}

class _FallingCoin {
  final double x, y;
  final int value, prize;
  double age = 0;
  _FallingCoin(this.x, this.y, this.value, this.prize);
}

class PusherGame extends FlameGame {
  final PusherModel model;
  final void Function(int earned) onTick;
  final bool Function() reducedMotion;
  final void Function(double dt, List<String> events)? onSounds;
  final List<_FallingCoin> _falling = [];
  final Map<String, Image> toys = {};
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final id in prizeIds) {
      final data = await rootBundle.load('assets/pusher/$id.webp');
      final codec = await instantiateImageCodec(data.buffer.asUint8List());
      toys[id] = (await codec.getNextFrame()).image;
      codec.dispose();
    }
  }

  @override
  void onRemove() {
    for (final image in toys.values) {
      image.dispose();
    }
    toys.clear();
    super.onRemove();
  }

  PusherGame(this.model, this.onTick, this.reducedMotion, {this.onSounds});
  @override
  Color backgroundColor() => const Color(0xFFF6DFC0);
  @override
  void update(double dt) {
    super.update(dt);
    final previous = {
      for (final c in model.coins) c: (c.body.position.x, c.body.position.y),
    };
    final earned = model.update(dt);
    onSounds?.call(dt.clamp(0, .1), model.soundEvents);
    model.soundEvents.clear();
    if (reducedMotion()) {
      _falling.clear();
    } else {
      for (final c in _falling) {
        c.age += dt;
      }
      _falling.removeWhere((c) => c.age > .4);
      for (final entry in previous.entries) {
        if (!model.coins.contains(entry.key)) {
          _falling.add(
            _FallingCoin(
              entry.value.$1,
              entry.value.$2,
              entry.key.value,
              entry.key.prize,
            ),
          );
        }
      }
    }
    onTick(earned);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    paintCabinet(
      canvas,
      Size(size.x, size.y),
      model,
      toys: toys,
      paintFalling: _paintFalling,
    );
  }

  void _paintFalling(Canvas canvas) {
    for (final c in _falling) {
      final t = c.age / .4;
      if (c.prize > 0) {
        drawPrize(canvas, c.x, c.y, -t * 2, toys[prizeIds[c.prize - 1]]);
        continue;
      }
      drawSolidCoin(canvas, c.x, c.y, -t * 1.8, c.value);
    }
  }
}
