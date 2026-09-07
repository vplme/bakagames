import 'dart:isolate';

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
  final void Function(int levelIndex, int moves)? onWon;

  const BirdSortPlayScreen({
    super.key,
    required this.levelIndex,
    this.debugLevel,
    this.settings,
    this.onWon,
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

  @override
  void initState() {
    super.initState();
    final debug = widget.debugLevel;
    final index = widget.levelIndex;
    _levelFuture = debug != null
        ? Future.value(debug)
        : Isolate.run(() => engine.levelFor(index));
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
    if (c.state.isWon && !_winHandled) {
      _winHandled = true;
      widget.onWon?.call(widget.levelIndex, c.moveCount);
      // Let the flock finish flying before celebrating.
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _showWinSheet();
      });
    }
    if (!c.state.isWon) _winHandled = false; // undo past the win
  }

  void _showWinSheet() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Level ${widget.levelIndex + 1} complete!',
                  style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Solved in ${_controller!.moveCount} moves'),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next level'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => BirdSortPlayScreen(
                      levelIndex: widget.levelIndex + 1,
                      settings: widget.settings,
                      onWon: widget.onWon,
                    ),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${widget.levelIndex + 1}'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE), Color(0xFFDCEDC8)],
          ),
        ),
        child: FutureBuilder<engine.Level>(
          future: _levelFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Failed to load level:\n'
                  '${snapshot.error}', textAlign: TextAlign.center));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final controller = _controllerFor(snapshot.data!);
            return SafeArea(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => Column(
                  children: [
                    if (controller.state.isStuck) _stuckBanner(controller),
                    Expanded(child: BirdSortBoard(controller: controller)),
                    _controls(controller),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No solution from here — try undoing.')));
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
            onPressed:
                controller.canUndo ? controller.restartLevel : null,
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
                      child: CircularProgressIndicator(strokeWidth: 2.5)),
                )
              : _ControlButton(
                  icon: Icons.lightbulb_outline,
                  label: 'Hint',
                  onPressed: won ? null : () => _hint(controller),
                ),
          Text('Moves: ${controller.moveCount}',
              style: Theme.of(context).textTheme.titleMedium),
        ],
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

  const _ControlButton(
      {required this.icon, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
            iconSize: 28, onPressed: onPressed, icon: Icon(icon)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
