import 'dart:math' as math;

import 'package:bird_sort/bird_sort.dart' as engine;
import 'package:flutter/material.dart';

import 'bird_painter.dart';
import 'play_controller.dart';

const _flightDuration = Duration(milliseconds: 520);

/// The tree: central trunk, branches alternating left/right, birds perched
/// trunk→tip. One big Stack in one coordinate system — every bird is an
/// [AnimatedPositioned] keyed by its stable uid, so moves, flock departures
/// and undo all animate for free (staggered via per-bird Interval curves).
class BirdSortBoard extends StatefulWidget {
  final PlayController controller;

  const BirdSortBoard({super.key, required this.controller});

  @override
  State<BirdSortBoard> createState() => _BirdSortBoardState();
}

class _BirdSortBoardState extends State<BirdSortBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  int _seenShakeTick = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    final c = widget.controller;
    if (c.shakeTick != _seenShakeTick) {
      _seenShakeTick = c.shakeTick;
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, _shake]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) =>
            _buildTree(context, constraints.biggest),
      ),
    );
  }

  Widget _buildTree(BuildContext context, Size size) {
    final c = widget.controller;
    final state = c.state;
    final branches = state.branches;
    final capacity = state.level.capacity;

    final rows = branches.length;
    final rowH = ((size.height - 24) / rows).clamp(48.0, 110.0);
    final treeH = rowH * rows;
    final top = (size.height - treeH) / 2;
    final centerX = size.width / 2;
    const trunkW = 20.0;
    final halfSpan = size.width / 2 - trunkW / 2 - 10;
    final birdSize =
        math.min(halfSpan / capacity, rowH * 0.66).floorToDouble();
    final barH = math.max(10.0, birdSize * 0.16);

    double rowTop(int i) => top + i * rowH;
    double barY(int i) => rowTop(i) + rowH * 0.80;

    // Bird slot origin (top-left) for branch i, slot s (0 = trunk-most).
    Offset slotOrigin(int i, int s) {
      final y = barY(i) - birdSize;
      final side = branches[i].side;
      return side == engine.Side.left
          ? Offset(centerX - trunkW / 2 - (s + 1) * birdSize, y)
          : Offset(centerX + trunkW / 2 + s * birdSize, y);
    }

    final shakeOffset = math.sin(_shake.value * math.pi * 4) *
        7 *
        (1 - _shake.value) *
        (_shake.isAnimating ? 1 : 0);

    final children = <Widget>[
      // Trunk.
      Positioned(
        left: centerX - trunkW / 2,
        top: top - 8,
        width: trunkW,
        height: treeH + 16,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF6D4C41),
            borderRadius: BorderRadius.circular(trunkW / 2),
          ),
        ),
      ),
    ];

    // Branch bars (under the birds).
    for (var i = 0; i < rows; i++) {
      final branch = branches[i];
      final side = branch.side;
      final barLen = birdSize * capacity + birdSize * 0.35;
      final left = side == engine.Side.left
          ? centerX - trunkW / 2 - barLen
          : centerX + trunkW / 2;
      children.add(AnimatedPositioned.fromRect(
        key: ValueKey('bar$i'),
        duration: _flightDuration,
        rect: Rect.fromLTWH(
            left + (c.shakeBranch == i ? shakeOffset : 0), barY(i),
            barLen, barH),
        child: AnimatedOpacity(
          duration: _flightDuration,
          opacity: branch.removed ? 0.0 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF795548),
              borderRadius: BorderRadius.circular(barH / 2),
            ),
            child: Align(
              alignment: side == engine.Side.left
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                width: barH * 1.15,
                height: barH * 1.15,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                    color: Color(0xFF66BB6A), shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ));
    }

    // Birds. Iterate the id mirror; stable keys keep flight continuous.
    final lifted = <int>{};
    if (c.selected != null) {
      final ids = c.birdIds[c.selected!];
      final group = c.linkedGroup(c.selected!);
      lifted.addAll(ids.sublist(ids.length - group));
    }

    for (var i = 0; i < rows; i++) {
      final side = branches[i].side;
      for (var s = 0; s < c.birdIds[i].length; s++) {
        final uid = c.birdIds[i][s];
        final o = slotOrigin(i, s);
        children.add(_bird(
          c,
          uid,
          left: o.dx + (c.shakeBranch == i ? shakeOffset : 0),
          top: o.dy - (lifted.contains(uid) ? birdSize * 0.30 : 0),
          size: birdSize,
          facingLeft: side == engine.Side.left,
        ));
      }
    }

    // Departed birds: fly off toward their branch's side, high and away.
    for (final entry in c.departed.entries) {
      final uid = entry.key;
      final side = entry.value.side;
      final y = rowTop(entry.value.branchIndex) - size.height * 0.55;
      children.add(_bird(
        c,
        uid,
        left: side == engine.Side.left
            ? -birdSize * 3 - (c.staggerOf[uid] ?? 0) * birdSize
            : size.width + birdSize * 2 + (c.staggerOf[uid] ?? 0) * birdSize,
        top: y,
        size: birdSize,
        facingLeft: side == engine.Side.left,
        opacity: 0.0,
      ));
    }

    // Tap areas: whole half-row per branch (bar + birds + empty space).
    for (var i = 0; i < rows; i++) {
      if (branches[i].removed) continue;
      final side = branches[i].side;
      children.add(Positioned(
        left: side == engine.Side.left ? 0 : centerX,
        top: rowTop(i),
        width: size.width / 2,
        height: rowH,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => c.tapBranch(i),
        ),
      ));
    }

    return ClipRect(
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  Widget _bird(
    PlayController c,
    int uid, {
    required double left,
    required double top,
    required double size,
    required bool facingLeft,
    double opacity = 1.0,
  }) {
    final stagger = c.staggerOf[uid];
    final curve = stagger == null
        ? Curves.easeInOutCubic
        : Interval(math.min(0.45, stagger * 0.12), 1.0,
            curve: Curves.easeInOutCubic);
    return AnimatedPositioned(
      key: ValueKey('bird$uid'),
      duration: _flightDuration,
      curve: curve,
      left: left,
      top: top,
      width: size,
      height: size,
      child: AnimatedOpacity(
        duration: _flightDuration,
        curve: curve,
        opacity: opacity,
        child: IgnorePointer(
          child: CustomPaint(
            painter: BirdPainter(
                colourId: c.colourOf[uid]!, facingLeft: facingLeft),
          ),
        ),
      ),
    );
  }
}
