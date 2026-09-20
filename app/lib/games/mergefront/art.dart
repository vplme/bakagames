import 'dart:math';
import 'package:flutter/material.dart';
import 'model.dart';
import 'terrain.dart';

const ink = Color(0xFF17354B);
const cyan = Color(0xFF39C7CF);
const cream = Color(0xFFFFF5D9);
const gold = Color(0xFFF6C45E);
const coral = Color(0xFFE77575);

/// Original vector toy kit. Same silhouettes in cards, preview and battlefield.
void paintUnit(
  Canvas canvas,
  Offset center,
  double size,
  Role role,
  int tier, {
  bool enemy = false,
  double bounce = 0,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(size / 48);
  final p = Paint();
  void oval(Rect rect, Color color) => canvas.drawOval(rect, p..color = color);
  void box(Rect rect, Color color, [double radius = 6]) => canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(radius)),
    p..color = color,
  );
  final body = enemy ? coral : cyan;
  oval(const Rect.fromLTWH(-19, 13, 39, 13), ink.withValues(alpha: .18));
  canvas.translate(0, bounce);
  if (role == Role.drone) {
    for (final dx in [-17.0, 17.0]) {
      box(Rect.fromLTWH(dx - 5, -8, 10, 25), ink);
      oval(Rect.fromLTWH(dx - 12, -12, 24, 7), cream);
    }
    box(const Rect.fromLTWH(-14, -11, 28, 27), body, 12);
    box(const Rect.fromLTWH(-9, -5, 18, 7), ink, 4);
    oval(const Rect.fromLTWH(-3, -4, 6, 5), gold);
  } else {
    box(const Rect.fromLTWH(-13, 12, 10, 10), ink, 3);
    box(const Rect.fromLTWH(3, 12, 10, 10), ink, 3);
    box(
      Rect.fromLTWH(
        -17 - (role == Role.heavy ? 3 : 0),
        -1,
        role == Role.heavy ? 40 : 34,
        19,
      ),
      ink,
    );
    box(const Rect.fromLTWH(-13, -5, 26, 23), body);
    box(const Rect.fromLTWH(-10, -23, 24, 24), cream, 10);
    box(Rect.fromLTWH(-14, -25, role == Role.heavy ? 33 : 30, 17), body, 9);
    box(
      const Rect.fromLTWH(-10, -22, 20, 4),
      Colors.white.withValues(alpha: .4),
      3,
    );
    box(const Rect.fromLTWH(-8, -7, 18, 6), ink, 3);
    oval(const Rect.fromLTWH(3, -6, 4, 3), cyan);
    if (role == Role.support) {
      box(const Rect.fromLTWH(-4, -20, 5, 11), cream, 1);
      box(const Rect.fromLTWH(-7, -17, 11, 5), cream, 1);
      box(const Rect.fromLTWH(10, 1, 15, 17), gold, 5);
      oval(const Rect.fromLTWH(13, 4, 9, 9), cream);
    } else {
      final width = role == Role.heavy
          ? 15.0
          : role == Role.scatter
          ? 18.0
          : 9.0;
      box(Rect.fromLTWH(10, -10, width, 26), ink, 3);
      box(Rect.fromLTWH(12, -12, width - 4, 9), gold, 2);
      if (role == Role.scatter) {
        box(const Rect.fromLTWH(16, -13, 3, 13), cream, 1);
      }
    }
  }
  // Chest plating, inset vents and metallic fasteners retain each role silhouette.
  box(
    const Rect.fromLTWH(-9, 2, 17, 11),
    enemy ? const Color(0xFFB95662) : const Color(0xFF238FAD),
    3,
  );
  box(
    const Rect.fromLTWH(-8, 2, 15, 2),
    Colors.white.withValues(alpha: .35),
    1,
  );
  for (var vent = 0; vent < 3; vent++) {
    box(Rect.fromLTWH(-5 + vent * 4, 6, 2, 4), ink.withValues(alpha: .6), 1);
  }
  for (final dx in [-11.0, 9.0]) {
    oval(Rect.fromLTWH(dx, 0, 2.5, 2.5), cream);
  }
  if (role != Role.drone) {
    box(const Rect.fromLTWH(-12, -15, 26, 2), ink.withValues(alpha: .2), 1);
    box(const Rect.fromLTWH(-11, 18, 7, 2), const Color(0xFF527082), 1);
    box(const Rect.fromLTWH(4, 18, 7, 2), const Color(0xFF527082), 1);
    box(const Rect.fromLTWH(-6, -6, 6, 1), cream.withValues(alpha: .7), 1);
  }
  // Each rank adds geometry: crest, shoulders, pack, antenna, crown fins.
  if (tier >= 2) box(const Rect.fromLTWH(-3, -29, 8, 8), gold, 2);
  if (tier >= 3) {
    box(const Rect.fromLTWH(-21, -2, 10, 10), gold, 3);
    box(const Rect.fromLTWH(13, -2, 10, 10), gold, 3);
  }
  if (tier >= 4) box(const Rect.fromLTWH(-24, 4, 11, 17), body, 3);
  if (tier >= 5) {
    box(const Rect.fromLTWH(-21, -29, 3, 25), ink, 1);
    oval(const Rect.fromLTWH(-24, -32, 9, 9), gold);
  }
  if (tier >= 6) {
    final path = Path()
      ..moveTo(-14, -24)
      ..lineTo(-18, -38)
      ..lineTo(-4, -29)
      ..lineTo(4, -39)
      ..lineTo(14, -24)
      ..close();
    canvas.drawPath(path, p..color = gold);
  }
  canvas.restore();
}

class UnitPortrait extends StatelessWidget {
  final Role role;
  final int tier;
  const UnitPortrait(this.role, this.tier, {super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _UnitPainter(role, tier), size: const Size(64, 72));
}

class _UnitPainter extends CustomPainter {
  final Role role;
  final int tier;
  _UnitPainter(this.role, this.tier);
  @override
  void paint(Canvas canvas, Size size) => paintUnit(
    canvas,
    Offset(size.width / 2, size.height * .59),
    54,
    role,
    tier,
  );
  @override
  bool shouldRepaint(_UnitPainter old) => role != old.role || tier != old.tier;
}

/// Illustrated library cover; mission previews retain their selected terrain.
class SquadRusherCover extends StatelessWidget {
  const SquadRusherCover({super.key});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/mergefront/squad-rusher-cover.webp',
    fit: BoxFit.cover,
    alignment: Alignment.center,
    width: double.infinity,
    height: double.infinity,
    semanticLabel: 'A cyan toy squad rushing across a sunny island causeway',
  );
}

class MergefrontPreview extends StatelessWidget {
  final Level? level;
  const MergefrontPreview({super.key, this.level});
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Squad Rusher squad crossing ${level?.style.label ?? BattlefieldStyle.coast.label}',
    child: CustomPaint(
      painter: BattlefieldPainter(null, reduced: true, previewLevel: level),
      child: const SizedBox.expand(),
    ),
  );
}

class MergeReveal extends StatelessWidget {
  final UnitCard card;
  final bool reduced;
  const MergeReveal({super.key, required this.card, required this.reduced});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: reduced ? 1 : 0, end: 1),
    duration: reduced ? Duration.zero : const Duration(milliseconds: 850),
    builder: (context, value, _) => SizedBox(
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (value < .45) ...[
            Transform.translate(
              offset: Offset(-65 * (1 - value / .45), 0),
              child: UnitPortrait(card.role, card.tier - 1),
            ),
            Transform.translate(
              offset: Offset(65 * (1 - value / .45), 0),
              child: UnitPortrait(card.role, card.tier - 1),
            ),
          ] else ...[
            if (!reduced && value < .95)
              Container(
                width: 100 * value,
                height: 100 * value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: gold.withValues(alpha: 1 - value),
                    width: 7,
                  ),
                ),
              ),
            Transform.scale(
              scale: reduced
                  ? 1
                  : .8 +
                        .2 * (value - .45) / .55 +
                        .2 * sin((value - .45) / .55 * pi),
              child: UnitPortrait(card.role, card.tier),
            ),
          ],
          Positioned(
            bottom: 0,
            child: Text(
              'RANK ${card.tier} • READY TO DEPLOY',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: ink,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class BattlefieldPainter extends CustomPainter {
  final Run? run;
  final bool reduced;
  final Level? previewLevel;
  BattlefieldPainter(this.run, {required this.reduced, this.previewLevel});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final w = size.width, h = size.height;
    final p = Paint();
    final t = run?.time ?? 8;
    void rect(Rect r, Color c, [double radius = 0]) => canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      p..color = c,
    );
    final level = run?.level ?? previewLevel ?? Level.all.first;
    if (level.style != BattlefieldStyle.coast) {
      paintTerrain(canvas, size, level.style, reduced ? 0 : t * 24);
    } else {
      final theme = level.index % 3;
      final water = [
        const Color(0xFF359FAF),
        const Color(0xFF438CA8),
        const Color(0xFF4AAB9C),
      ][theme];
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [water, const Color(0xFF88DCD0)],
          ).createShader(Offset.zero & size),
      );
      final scroll = reduced ? 0.0 : t * 24;
      // Water ripples, submerged shelves and foam sit below the raised causeway.
      for (var i = -1; i < (h / 72).ceil() + 1; i++) {
        final y = i * 72.0 + scroll * .55 % 72;
        for (final side in [0.0, .93]) {
          rect(
            Rect.fromLTWH(w * side, y, w * .07, 25),
            const Color(0xFFB4DBBC).withValues(alpha: .45),
            12,
          );
          rect(
            Rect.fromLTWH(w * side + 3, y + 34, w * .045, 2),
            cream.withValues(alpha: .55),
            2,
          );
          rect(
            Rect.fromLTWH(w * side - 5, y + 42, w * .035, 2),
            cream.withValues(alpha: .25),
            2,
          );
        }
      }
      rect(Rect.fromLTWH(w * .095, 0, w * .84, h), ink.withValues(alpha: .22));
      rect(Rect.fromLTWH(w * .075, 0, w * .85, h), const Color(0xFF98896C));
      rect(Rect.fromLTWH(w * .105, 0, w * .79, h), const Color(0xFFCFB988));
      final stone = [
        const Color(0xFFE8D5AA),
        const Color(0xFFD7D8BC),
        const Color(0xFFE4C59D),
      ][theme];
      rect(Rect.fromLTWH(w * .12, 0, w * .76, h), stone);
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(w * .12, 0, w * .76, h));
      for (var i = -1; i < (h / 96).ceil() + 1; i++) {
        final y = i * 96.0 + scroll % 96;
        rect(Rect.fromLTWH(w * .12, y, w * .76, 2), const Color(0xFFBCA77F));
        rect(
          Rect.fromLTWH(w * .12, y + 3, w * .76, 2),
          cream.withValues(alpha: .45),
        );
        for (var col = 0; col < 4; col++) {
          final dx = w * (.12 + col * .23);
          rect(Rect.fromLTWH(dx, y, 1, 96), const Color(0xFFCCB98F));
          // Small chips, mortar cracks and recessed road reflectors.
          final crack = Path()
            ..moveTo(dx + 9, y + 13)
            ..lineTo(dx + 15, y + 21)
            ..lineTo(dx + 12, y + 29);
          canvas.drawPath(
            crack,
            Paint()
              ..color = const Color(0xFFBCA77F)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
          rect(
            Rect.fromLTWH(dx + 23, y + 60, 11, 3),
            cream.withValues(alpha: .25),
            2,
          );
        }
        for (final lane in [.33, .67]) {
          rect(
            Rect.fromLTWH(w * lane, y + 35, 3, 20),
            cream.withValues(alpha: .6),
            1,
          );
        }
      }
      canvas.restore();
      // Beveled parapets, drainage slots, mooring posts and leafy planters.
      for (var i = -1; i < (h / 144).ceil() + 1; i++) {
        final y = i * 144.0 + scroll % 144;
        for (final side in [.09, .91]) {
          final dx = w * side;
          rect(Rect.fromLTWH(dx - 6, y, 13, 120), const Color(0xFFB09E7C), 3);
          rect(Rect.fromLTWH(dx - 6, y, 9, 116), const Color(0xFFF2DFB2), 3);
          for (var slot = 0; slot < 3; slot++) {
            rect(
              Rect.fromLTWH(dx - 3, y + 35 + slot * 9, 5, 3),
              ink.withValues(alpha: .4),
              1,
            );
          }
          rect(
            Rect.fromLTWH(dx - 8, y + 115, 20, 14),
            ink.withValues(alpha: .18),
            5,
          );
          rect(
            Rect.fromLTWH(dx - 8, y + 111, 16, 14),
            const Color(0xFF728C87),
            4,
          );
          rect(Rect.fromLTWH(dx - 5, y + 111, 10, 3), cream, 2);
          final plantX = dx + (side < .5 ? -12 : 12);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(plantX + 3, y + 81),
              width: 28,
              height: 18,
            ),
            p..color = ink.withValues(alpha: .18),
          );
          for (var leaf = 0; leaf < 5; leaf++) {
            canvas.save();
            canvas.translate(plantX, y + 75);
            canvas.rotate(leaf * pi * 2 / 5);
            canvas.drawOval(
              const Rect.fromLTWH(-4, -19, 8, 22),
              p
                ..color = leaf.isEven
                    ? const Color(0xFF488B67)
                    : const Color(0xFF78AF73),
            );
            canvas.restore();
          }
          canvas.drawCircle(Offset(plantX, y + 75), 3, p..color = gold);
        }
      }
    }
    if (run == null) {
      _gate(
        canvas,
        Rect.fromLTWH(w * .15, h * .16, w * .33, h * .25),
        '+8',
        'RECRUITS',
        false,
      );
      _gate(
        canvas,
        Rect.fromLTWH(w * .53, h * .16, w * .32, h * .25),
        '×2',
        'SQUAD',
        false,
      );
      for (var i = 0; i < 7; i++) {
        paintUnit(
          canvas,
          Offset(w * .5 + ((i % 3) - 1) * 35, h * .63 + (i ~/ 3) * 27),
          43,
          Role.values[i % 5],
          1 + i % 3,
        );
      }
      return;
    }
    final r = run!;
    for (final warning in r.warnings) {
      final area = Rect.fromLTWH(
        (warning.x - warning.width) * w,
        0,
        warning.width * 2 * w,
        h,
      );
      rect(area, coral.withValues(alpha: .24));
      canvas.save();
      canvas.clipRect(area);
      for (var i = -15; i < 30; i++) {
        canvas.drawLine(
          Offset(i * 28, 0),
          Offset(i * 28 + h, h),
          p
            ..color = coral.withValues(alpha: .4)
            ..strokeWidth = 6,
        );
      }
      canvas.restore();
      _text(canvas, '!', Offset(warning.x * w, h * .70), 30, ink);
    }
    final g = r.approaching;
    if (g != null) {
      final y = (.79 - (g.at - r.time) * .12) * h;
      _gate(
        canvas,
        Rect.fromLTWH(w * .10, y - 36, w * .38, 70),
        g.left.headline,
        g.left.caption,
        g.left.risky,
      );
      _gate(
        canvas,
        Rect.fromLTWH(w * .52, y - 36, w * .38, 70),
        g.right.headline,
        g.right.caption,
        g.right.risky,
      );
    }
    for (final e in r.enemies) {
      if (!e.active) continue;
      final c = Offset(e.x * w, e.y * h);
      if (e.kind == EnemyKind.boss) {
        _boss(canvas, c, r.level.index.isEven);
      } else if (e.kind.index >= EnemyKind.barricade.index) {
        rect(
          Rect.fromCenter(
            center: c + const Offset(2, 5),
            width: 37,
            height: 35,
          ),
          ink.withValues(alpha: .2),
          6,
        );
        rect(
          Rect.fromCenter(
            center: c,
            width: e.kind == EnemyKind.barricade ? 50 : 32,
            height: 32,
          ),
          e.kind == EnemyKind.crate ? gold : const Color(0xFF8F7D97),
          6,
        );
        _text(
          canvas,
          switch (e.kind) {
            EnemyKind.crate => '+',
            EnemyKind.barrel => '!',
            EnemyKind.pylon => 'ϟ',
            _ => '≡',
          },
          c - const Offset(0, 15),
          23,
          cream,
        );
      } else {
        paintUnit(
          canvas,
          c,
          e.kind == EnemyKind.heavy
              ? 52
              : e.kind == EnemyKind.swarm
              ? 28
              : 40,
          switch (e.kind) {
            EnemyKind.heavy => Role.heavy,
            EnemyKind.ranged => Role.drone,
            EnemyKind.shield => Role.support,
            EnemyKind.swarm => Role.scatter,
            _ => Role.rifle,
          },
          1,
          enemy: true,
        );
        if (e.kind == EnemyKind.shield) {
          rect(
            Rect.fromCenter(
              center: c + const Offset(0, 19),
              width: 32,
              height: 8,
            ),
            const Color(0xFFB5B8DC),
            4,
          );
        }
      }
      if (e.hp < e.maxHp) {
        rect(
          Rect.fromLTWH(
            c.dx - 18,
            c.dy - (e.kind == EnemyKind.boss ? 53 : 32),
            36,
            4,
          ),
          ink,
          2,
        );
        rect(
          Rect.fromLTWH(
            c.dx - 18,
            c.dy - (e.kind == EnemyKind.boss ? 53 : 32),
            36 * e.hp / e.maxHp,
            4,
          ),
          coral,
          2,
        );
      }
    }
    for (final shot in r.shots) {
      if (!shot.active) continue;
      final a = Offset(shot.x * w, shot.y * h),
          b = Offset(shot.tx * w, shot.ty * h);
      final progress = 1 - shot.life / .16;
      canvas.drawLine(
        Offset.lerp(a, b, max(0, progress - .20))!,
        Offset.lerp(a, b, progress)!,
        p
          ..color = shot.role == Role.heavy ? gold : cream
          ..strokeWidth = shot.role == Role.heavy ? 5 : 3
          ..strokeCap = StrokeCap.round,
      );
    }
    final count = r.squad.length;
    final columns = min(5, max(1, count));
    const unitSize = 40.0;
    for (var i = 0; i < count; i++) {
      final s = r.squad[i];
      final dx =
          (reduced
              ? r.x + ((i % columns) - (columns - 1) / 2) * .075
              : s.formationX) *
          w;
      final dy = (reduced ? .80 + (i ~/ columns) * .035 : s.formationY) * h;
      if (r.shield > 0 || r.armor) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(dx, dy), width: 39, height: 43),
          p..color = cyan.withValues(alpha: .20),
        );
      }
      paintUnit(
        canvas,
        Offset(dx, dy),
        unitSize,
        s.role,
        s.tier,
        bounce: reduced ? 0 : sin(t * 9 + i) * 1.6 + s.recoil * 2,
      );
      if (s.hp < s.maxHp) {
        rect(Rect.fromLTWH(dx - 13, dy + 18, 26, 4), ink, 2);
        rect(Rect.fromLTWH(dx - 13, dy + 18, 26 * s.hp / s.maxHp, 4), gold, 2);
      }
      if (s.recoil > .65 && !reduced) {
        canvas.drawCircle(
          Offset(dx + 13, dy - 12),
          s.recoil * 4,
          p..color = gold,
        );
      }
    }
    if (!reduced) {
      for (final spark in r.sparks) {
        if (!spark.active) continue;
        for (var i = 0; i < 6; i++) {
          final radius = (1 - spark.life / .35) * 22;
          canvas.drawCircle(
            Offset(
              spark.x * w + cos(i * pi / 3) * radius,
              spark.y * h + sin(i * pi / 3) * radius,
            ),
            spark.life * 8,
            p..color = spark.gold ? gold : cream,
          );
        }
      }
    }
  }

  void _gate(
    Canvas canvas,
    Rect rect,
    String symbol,
    String label,
    bool risky,
  ) {
    final color = risky ? gold : cyan;
    final p = Paint()..color = ink.withValues(alpha: .15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 5)),
        const Radius.circular(10),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(risky ? 3 : 12)),
      p..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(8)),
      p..color = cream.withValues(alpha: .25),
    );
    _text(
      canvas,
      symbol,
      Offset(rect.center.dx, rect.top + 2),
      min(27, rect.height * .4),
      ink,
    );
    _text(
      canvas,
      label,
      Offset(rect.center.dx, rect.top + rect.height * .53),
      13,
      ink,
      maxWidth: rect.width - 6,
    );
  }

  void _boss(Canvas canvas, Offset c, bool crab) {
    final p = Paint()..color = ink.withValues(alpha: .2);
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(0, 28), width: 112, height: 25),
      p,
    );
    for (final dx in [-44.0, 44.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c + Offset(dx, 8),
            width: crab ? 28 : 17,
            height: crab ? 45 : 67,
          ),
          const Radius.circular(9),
        ),
        p..color = const Color(0xFF66577A),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 80, height: 69),
        const Radius.circular(22),
      ),
      p..color = coral,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c - const Offset(0, 9), width: 53, height: 22),
        const Radius.circular(9),
      ),
      p..color = ink,
    );
    for (final dx in [-14.0, 14.0]) {
      canvas.drawCircle(c + Offset(dx, -9), 6, p..color = gold);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c + const Offset(0, 29), width: 22, height: 25),
        const Radius.circular(6),
      ),
      p..color = ink,
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset top,
    double font,
    Color color, {
    double maxWidth = 200,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: font,
          fontFamily: 'Roboto',
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, Offset(top.dx - tp.width / 2, top.dy));
  }

  @override
  bool shouldRepaint(BattlefieldPainter old) => true;
}
