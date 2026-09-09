import 'dart:isolate';
import 'dart:async';
import 'package:game_core/game_core.dart';
import 'aviary.dart';
import 'aviary_levels.dart';
import '../../shell/settings_screen.dart';

import 'package:bird_sort/bird_sort.dart' as engine;
import 'package:flutter/material.dart';

import '../../shell/settings.dart';
import 'board.dart';
import 'play_controller.dart';

/// Bird Sort play screen for one level index.
///
/// Levels are generated deterministically off the UI thread. Tests can
/// inject [debugLevel] to skip generation.
class BirdSortPlayScreen extends StatefulWidget {
  final int levelIndex;
  final engine.Level? debugLevel;

  /// Haptics/sound; optional so tests can omit it.
  final AppSettings? settings;

  /// Called once per win with the level index and move count used.
  final FutureOr<void> Function(int levelIndex, int moves)? onWon;
  final ProgressStore? store;

  const BirdSortPlayScreen({
    super.key,
    required this.levelIndex,
    this.debugLevel,
    this.settings,
    this.onWon,
    this.store,
  });

  @override
  State<BirdSortPlayScreen> createState() => _BirdSortPlayScreenState();
}

class _BirdSortPlayScreenState extends State<BirdSortPlayScreen> {
  late final Future<engine.Level> _levelFuture;
  PlayController? _controller;
  bool _winHandled = false;
  bool _hintRunning = false;
  int _lastShakeTick = 0;
  int _lastTransitionTick = 0;
  int _departedCount = 0;
  bool _saveFailed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final debug = widget.debugLevel;
    final index = widget.levelIndex;
    _levelFuture = debug != null ? Future.value(debug) : _generateLevel(index);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  PlayController _controllerFor(engine.Level level) {
    if (_controller == null) {
      _controller = PlayController(level);
      _controller!.addListener(_onGameChanged);
    }
    return _controller!;
  }

  void _onGameChanged() {
    final c = _controller!;
    if (c.shakeTick != _lastShakeTick) {
      _lastShakeTick = c.shakeTick;
      widget.settings?.hapticError();
    }
    if (c.transitionTick != _lastTransitionTick) {
      _lastTransitionTick = c.transitionTick;
      widget.settings?.hapticTap();
    }
    if (c.departed.length > _departedCount) {
      widget.settings?.chirp(celebration: c.state.isWon);
    }
    _departedCount = c.departed.length;
    if (c.state.isWon && !_winHandled) {
      _winHandled = true;
      _saving = true;
      _saveWin(c);
    }
  }

  Future<void> _saveWin(PlayController c) async {
    try {
      await widget.onWon?.call(widget.levelIndex, c.moveCount);
      if (!mounted) return;
      setState(() {
        _saveFailed = false;
        _saving = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveFailed = true;
          _saving = false;
        });
      }
    }
  }

  bool get _reduced =>
      MediaQuery.disableAnimationsOf(context) ||
      (widget.settings?.reducedMotion.value ?? false);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: aviaryCream,
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            habitatAsset(widget.levelIndex),
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  aviaryCream.withValues(alpha: .94),
                  aviaryCream.withValues(alpha: .72),
                  aviaryCream.withValues(alpha: .45),
                  aviaryCream.withValues(alpha: .92),
                ],
                stops: const [0, .24, .74, 1],
              ),
            ),
          ),
        ),
        SafeArea(
          child: FutureBuilder<engine.Level>(
            future: _levelFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('This garden needs another moment.'),
                      TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        child: const Text('Back to levels'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final c = _controllerFor(snapshot.data!);
              return ListenableBuilder(
                listenable: Listenable.merge([
                  c,
                  if (widget.settings != null) widget.settings!.reducedMotion,
                ]),
                builder: (context, _) {
                  final compact =
                      MediaQuery.sizeOf(context).height < 700 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.2;
                  final board = Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: BirdSortBoard(
                      controller: c,
                      reducedMotion: _reduced,
                    ),
                  );
                  final content = Column(
                    mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                        child: Row(
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'Back to levels',
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'POCKET AVIARY',
                                    style: TextStyle(
                                      color: aviaryInk,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.6,
                                    ),
                                  ),
                                  Text(
                                    'a little moment of happy',
                                    style: TextStyle(
                                      color: Color(0xFF819181),
                                      fontSize: 10,
                                      letterSpacing: .6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Settings',
                              onPressed: widget.settings == null
                                  ? null
                                  : () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => SettingsScreen(
                                          settings: widget.settings!,
                                        ),
                                      ),
                                    ),
                              icon: const Icon(Icons.tune_rounded),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    habitatName(
                                      widget.levelIndex,
                                    ).toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF6B8D68),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  Text(
                                    'Level ${widget.levelIndex + 1}',
                                    style: const TextStyle(
                                      fontSize: 34,
                                      height: 1.2,
                                      fontWeight: FontWeight.w800,
                                      color: aviaryInk,
                                      letterSpacing: -1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Moves: ${c.moveCount}',
                                style: const TextStyle(
                                  color: aviaryInk,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 6),
                        child: Row(
                          children: [
                            for (var i = 0; i < c.level.colourCount; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: Icon(
                                  Icons.local_florist_rounded,
                                  size: 17,
                                  color:
                                      i < c.departed.length ~/ c.level.capacity
                                      ? const Color(0xFFE9AF4E)
                                      : const Color(0xFFCAD7BF),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${c.departed.length ~/ c.level.capacity} / ${c.level.colourCount} flocks home',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  color: aviaryInk,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (c.state.isStuck) _stuckBanner(c),
                      if (compact)
                        SizedBox(
                          height: c.state.branches.length * 66.0,
                          child: board,
                        )
                      else
                        Expanded(child: board),
                      if (c.state.isWon)
                        _winPanel(c)
                      else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            c.selected == null
                                ? 'Tap a flock. Find its feathered friends.'
                                : 'Choose a glowing perch to land.',
                            style: const TextStyle(
                              color: aviaryInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        _controls(c),
                      ],
                    ],
                  );
                  return compact
                      ? SingleChildScrollView(child: content)
                      : content;
                },
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _winPanel(PlayController c) => Container(
    margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: aviaryCream,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE9CB84)),
    ),
    child: Column(
      children: [
        const Text(
          'Happy birds, happy place!',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: aviaryInk,
          ),
        ),
        Text('Level ${widget.levelIndex + 1} complete!'),
        const SizedBox(height: 12),
        if (_saveFailed)
          TextButton(
            onPressed: () => _saveWin(c),
            child: const Text('Save failed · Tap to retry'),
          ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: aviaryInk,
              padding: const EdgeInsets.all(15),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next level'),
            onPressed: _saveFailed || _saving
                ? null
                : () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => BirdSortPlayScreen(
                        levelIndex: widget.levelIndex + 1,
                        settings: widget.settings,
                        onWon: widget.onWon,
                        store: widget.store,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    ),
  );

  Widget _stuckBanner(PlayController controller) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade400),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
          const SizedBox(width: 8),
          const Expanded(child: Text('No moves left!')),
          TextButton(
            onPressed: controller.canUndo ? controller.undoMove : null,
            child: const Text('Undo'),
          ),
          TextButton(
            onPressed: controller.restartLevel,
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  /// The hint booster: solver runs in an isolate, spinner while it thinks,
  /// then the suggested move is played.
  Future<void> _hint(PlayController controller) async {
    if (_hintRunning || controller.state.isWon) return;
    setState(() => _hintRunning = true);
    final snapshot = engine.stripHistory(controller.state);
    final result = await _solveInIsolate(snapshot);
    if (!mounted) return;
    setState(() => _hintRunning = false);
    // Ignore a stale result if the position changed while solving
    // (GameState equality compares positions, not histories).
    if (controller.state != snapshot) return;
    if (!result.solvable || result.moves.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No solution from here — try undoing.')),
      );
      return;
    }
    controller.applyExternalMove(result.moves.first);
  }

  Widget _controls(PlayController controller) {
    final won = controller.state.isWon;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: Icons.undo,
            label: 'Undo',
            onPressed: controller.canUndo ? controller.undoMove : null,
          ),
          _ControlButton(
            icon: Icons.refresh,
            label: 'Restart',
            onPressed: controller.canUndo ? controller.restartLevel : null,
          ),
          _ControlButton(
            icon: Icons.park_outlined,
            label: '+ Branch',
            onPressed: controller.extraBranchUsed || won
                ? null
                : controller.useExtraBranch,
          ),
          _hintRunning
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : _ControlButton(
                  icon: Icons.lightbulb_outline,
                  label: 'Hint',
                  onPressed: won ? null : () => _hint(controller),
                ),
        ].map((child) => Expanded(child: child)).toList(),
      ),
    );
  }
}

/// Top-level so the isolate closure captures only [snapshot] — a closure
/// created inside the State would drag the whole surrounding context
/// (including unsendable futures) into the isolate message.
Future<engine.SolveResult> _solveInIsolate(engine.GameState snapshot) =>
    Isolate.run(() => engine.solve(snapshot));

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: label,
          iconSize: 28,
          onPressed: onPressed,
          icon: Icon(icon),
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

Future<engine.Level> _generateLevel(int index) =>
    Isolate.run(() => aviaryLevelFor(index));
