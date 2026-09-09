import 'dart:math' as math;
import 'package:bird_sort/bird_sort.dart' as engine;
import 'package:flutter/material.dart';
import 'aviary.dart';
import 'palette.dart';
import 'play_controller.dart';

/// Stable bird identities interpolate across perches. Input stays live in flight.
class BirdSortBoard extends StatefulWidget {
  final PlayController controller;
  final bool reducedMotion;
  const BirdSortBoard({
    super.key,
    required this.controller,
    this.reducedMotion = false,
  });
  @override
  State<BirdSortBoard> createState() => _BirdSortBoardState();
}

class _BirdSortBoardState extends State<BirdSortBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant BirdSortBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (widget.reducedMotion ||
        MediaQuery.disableAnimationsOf(context) ||
        widget.controller.state.isWon) {
      _clock.stop();
    } else {
      if (!_clock.isAnimating) _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, viewport) => SingleChildScrollView(
      child: SizedBox(
        width: viewport.maxWidth,
        height: math.max(
          viewport.maxHeight,
          widget.controller.state.branches.length * 66.0,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final c = widget.controller;
            final reduced =
                widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
            final rows = c.state.branches.length;
            final rowHeight = box.maxHeight / rows;
            final birdSize = math.min(
              67.0,
              math.min((box.maxWidth - 86) / c.level.capacity, rowHeight * .82),
            );
            final span = birdSize * c.level.capacity;
            Offset origin(int branch, int slot) {
              final left =
                  (box.maxWidth - span) / 2 + (branch.isEven ? -10 : 10);
              return Offset(
                left + slot * birdSize,
                rowHeight * branch + rowHeight - birdSize - 13,
              );
            }

            final lifted = <int>{};
            if (c.selected != null) {
              final ids = c.birdIds[c.selected!];
              lifted.addAll(ids.skip(ids.length - c.linkedGroup(c.selected!)));
            }
            return RepaintBoundary(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < rows; i++)
                    if (!c.state.branches[i].removed)
                      Positioned(
                        left: origin(i, 0).dx - 14,
                        top: i * rowHeight + 2,
                        width: span + 28,
                        height: rowHeight - 3,
                        child: _Shake(
                          tick: c.shakeTick,
                          active: c.shakeBranch == i && !reduced,
                          child: Semantics(
                            button: true,
                            label:
                                'Branch ${i + 1}, ${c.state.branches[i].birds.map((id) => birdNames[id % 8]).join(', ')}${c.state.branches[i].isEmpty ? 'empty' : ''}',
                            child: GestureDetector(
                              key: ValueKey('branch$i'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () => c.tapBranch(i),
                              child: AnimatedContainer(
                                duration: Duration(
                                  milliseconds: reduced ? 0 : 180,
                                ),
                                decoration: BoxDecoration(
                                  color: c.selected == i
                                      ? const Color(
                                          0xFFFFE5A0,
                                        ).withValues(alpha: .55)
                                      : Colors.white.withValues(alpha: .28),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        c.selected != null &&
                                            engine.moveSize(
                                                  c.level,
                                                  c.state.branches,
                                                  c.selected!,
                                                  i,
                                                ) !=
                                                null
                                        ? const Color(0xFF69BDA1)
                                        : Colors.white.withValues(alpha: .4),
                                    width: 2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 3,
                                      top: 7,
                                      child: Text(
                                        '${i + 1}'.padLeft(2, '0'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: aviaryInk.withValues(
                                            alpha: .45,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (c.state.branches[i].isEmpty)
                                      Center(
                                        child: Text(
                                          c.selected == null
                                              ? 'A little room to land'
                                              : 'Land here',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: aviaryInk.withValues(
                                              alpha: .55,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      left: 6,
                                      right: 6,
                                      bottom: 7,
                                      height: 12,
                                      child: TweenAnimationBuilder<double>(
                                        key: ValueKey(
                                          'bounce$i-${c.transitionTick}',
                                        ),
                                        tween: Tween(
                                          begin: reduced ? 0 : 1,
                                          end: 0,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 450,
                                        ),
                                        builder: (context, t, child) =>
                                            Transform.translate(
                                              offset: Offset(
                                                0,
                                                math.sin(t * math.pi * 3) *
                                                    t *
                                                    3,
                                              ),
                                              child: child,
                                            ),
                                        child: CustomPaint(
                                          painter: _PerchPainter(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  for (var i = 0; i < rows; i++)
                    for (var s = 0; s < c.birdIds[i].length; s++)
                      _bird(
                        c.birdIds[i][s],
                        origin(i, s) -
                            Offset(
                              0,
                              lifted.contains(c.birdIds[i][s]) ? 12 : 0,
                            ),
                        birdSize,
                        reduced,
                        lifted.contains(c.birdIds[i][s]),
                      ),
                  for (final e in c.departed.entries)
                    _bird(
                      e.key,
                      Offset(
                        e.value.side == engine.Side.left
                            ? -100
                            : box.maxWidth + 30,
                        -100 - e.value.slot * 20,
                      ),
                      birdSize,
                      reduced,
                      false,
                      landingTarget: origin(e.value.branchIndex, e.value.slot),
                    ),
                  if (c.departed.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('sparkles${c.departed.length}'),
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: reduced ? 0 : 950),
                          builder: (context, value, _) => CustomPaint(
                            painter: _Sparkles(
                              value: value,
                              count: c.state.isWon ? 40 : 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  Widget _bird(
    int uid,
    Offset target,
    double size,
    bool reduced,
    bool selected, {
    Offset? landingTarget,
  }) => _FlyingBird(
    key: ValueKey('bird$uid'),
    target: target,
    size: size,
    species: widget.controller.colourOf[uid]!,
    uid: uid,
    clock: _clock,
    reduced: reduced,
    selected: selected,
    landingTarget: landingTarget,
  );
}

class _FlyingBird extends StatefulWidget {
  final Offset target;
  final Offset? landingTarget;
  final double size;
  final int species, uid;
  final Animation<double> clock;
  final bool reduced, selected;
  const _FlyingBird({
    super.key,
    required this.target,
    required this.size,
    required this.species,
    required this.uid,
    required this.clock,
    required this.reduced,
    required this.selected,
    this.landingTarget,
  });
  @override
  State<_FlyingBird> createState() => _FlyingBirdState();
}

class _FlyingBirdState extends State<_FlyingBird>
    with SingleTickerProviderStateMixin {
  late Offset _from = widget.target;
  late Offset _to = widget.target;
  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  Offset get _position {
    final t = _flight.value;
    final perch = widget.landingTarget;
    if (widget.reduced) return _to;
    if (perch != null && t < 1) {
      if (t < .42) {
        final p = t / .42;
        return Offset.lerp(_from, perch, Curves.easeInOut.transform(p))! -
            Offset(0, math.sin(p * math.pi) * 22);
      }
      if (t < .64) {
        return perch - Offset(0, math.sin((t - .42) / .22 * math.pi) * 10);
      }
      final p = (t - .64) / .36;
      return Offset.lerp(perch, _to, Curves.easeInCubic.transform(p))! -
          Offset(0, math.sin(p * math.pi) * 30);
    }
    return Offset.lerp(_from, _to, Curves.easeInOutCubic.transform(t))! -
        Offset(0, math.sin(t * math.pi) * 28);
  }

  @override
  void didUpdateWidget(covariant _FlyingBird oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.target != _to) {
      // Layout changes may move the offscreen destination. They must not
      // replay the landing/hop sequence for an already departed flock.
      // Undo clears landingTarget, so returning birds still animate normally.
      if (oldWidget.landingTarget != null && widget.landingTarget != null) {
        _to = widget.target;
        return;
      }
      _from = _position;
      _to = widget.target;
      if (widget.reduced) {
        _flight.value = 1;
      } else {
        _flight.duration = Duration(
          milliseconds: widget.landingTarget == null ? 420 : 850,
        );
        _flight.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_flight, widget.clock]),
    child: BirdArt(species: widget.species),
    builder: (context, child) {
      final phase = widget.clock.value * math.pi * 8 + widget.uid * 1.7;
      final flying = _flight.isAnimating;
      final breath = widget.reduced ? 0.0 : math.sin(phase) * .018;
      final tilt = widget.reduced
          ? 0.0
          : math.pow(math.max(0, math.sin(phase / 3)), 18) * .065;
      final landing = flying && _flight.value > .8
          ? math.sin((_flight.value - .8) * math.pi * 5) * .10
          : 0.0;
      final pos = _position;
      return Positioned(
        left: pos.dx,
        top: pos.dy,
        width: widget.size,
        height: widget.size,
        child: IgnorePointer(
          child: Transform.rotate(
            angle: flying ? math.sin(_flight.value * math.pi * 6) * .09 : tilt,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scaleX: 1 + landing,
              scaleY: 1 + breath - landing,
              alignment: Alignment.bottomCenter,
              child: Stack(
                children: [
                  if (widget.selected)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFFD464,
                              ).withValues(alpha: .6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned.fill(child: child!),
                  if (!widget.reduced &&
                      !flying &&
                      ((widget.clock.value * 12 + widget.uid * .73) % 4) < .13)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BlinkPainter(widget.species),
                      ),
                    ),
                  if (flying && !widget.reduced)
                    Positioned(
                      left: widget.size * .17,
                      top: widget.size * .46,
                      child: Transform.rotate(
                        angle: math.sin(_flight.value * math.pi * 10) * .8,
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: widget.size * .32,
                          height: widget.size * .14,
                          decoration: BoxDecoration(
                            color: birdColour(widget.species),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _PerchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9
      ..color = const Color(0xFFA97545);
    canvas.drawLine(Offset(0, 5), Offset(size.width, 7), p);
    p
      ..strokeWidth = 2
      ..color = const Color(0xFFDFB77A);
    canvas.drawLine(const Offset(4, 2), Offset(size.width - 6, 4), p);
    p.color = const Color(0xFF72A778);
    canvas.drawOval(
      Rect.fromLTWH(size.width - 7, -5, 14, 8),
      p..style = PaintingStyle.fill,
    );
    canvas.drawOval(Rect.fromLTWH(0, 6, 12, 7), p);
  }

  @override
  bool shouldRepaint(_PerchPainter old) => false;
}

class _Sparkles extends CustomPainter {
  final double value;
  final int count;
  _Sparkles({required this.value, required this.count});
  @override
  void paint(Canvas canvas, Size size) {
    if (value >= 1) return;
    for (var i = 0; i < count; i++) {
      final angle = i * 2.399;
      final center = Offset(
        size.width * .5 + math.cos(angle) * size.width * .5 * value,
        size.height * .45 + math.sin(angle) * size.height * .5 * value,
      );
      final p = Paint()
        ..color = [
          const Color(0xFFEAB64D),
          const Color(0xFFFFFAE6),
          const Color(0xFF60BA99),
        ][i % 3].withValues(alpha: 1 - value)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      final r = (1 - value) * 5;
      canvas.drawLine(center - Offset(r, 0), center + Offset(r, 0), p);
      canvas.drawLine(center - Offset(0, r), center + Offset(0, r), p);
    }
  }

  @override
  bool shouldRepaint(_Sparkles old) => old.value != value;
}

class _BlinkPainter extends CustomPainter {
  final int species;
  _BlinkPainter(this.species);
  static const eyes = [
    [Offset(.615, .333)],
    [Offset(.612, .325)],
    [Offset(.545, .32), Offset(.713, .272)],
    [Offset(.63, .257), Offset(.78, .244)],
    [Offset(.54, .38), Offset(.739, .355)],
    [Offset(.61, .28)],
    [Offset(.58, .29)],
    [Offset(.61, .356)],
  ];
  @override
  void paint(Canvas canvas, Size size) {
    for (final eye in eyes[species % 8]) {
      final center = Offset(eye.dx * size.width, eye.dy * size.height);
      final r = size.width * (species == 4 ? .055 : .034);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: r * 2, height: r * 2.2),
        Paint()
          ..color = const [
            Color(0xFF382C29),
            Color(0xFFEAE5D6),
            Color(0xFFFFD65D),
            Color(0xFFE6D84A),
            Color(0xFFDCCABA),
            Color(0xFFF0A046),
            Color(0xFF328C99),
            Color(0xFFF2B2B9),
          ][species % 8],
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: center - Offset(0, r * .4),
          width: r * 1.6,
          height: r,
        ),
        0,
        math.pi,
        false,
        Paint()
          ..color = aviaryInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_BlinkPainter old) => old.species != species;
}

class _Shake extends StatelessWidget {
  final int tick;
  final bool active;
  final Widget child;
  const _Shake({required this.tick, required this.active, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(tick),
    tween: Tween(begin: active ? 1.0 : 0.0, end: 0.0),
    duration: const Duration(milliseconds: 280),
    child: child,
    builder: (context, value, child) => Transform.translate(
      offset: Offset(math.sin(value * math.pi * 4) * value * 6, 0),
      child: child,
    ),
  );
}
