import 'dart:isolate';

import 'package:bird_sort/bird_sort.dart' as engine;
import 'package:flutter/material.dart';

import 'board.dart';
import 'play_controller.dart';

/// Bird Sort play screen for one level index.
///
/// Levels are generated deterministically off the UI thread. Tests can
/// inject [debugLevel] to skip generation.
class BirdSortPlayScreen extends StatefulWidget {
  final int levelIndex;
  final engine.Level? debugLevel;

  /// Called once when the level is won, with the move count used.
  final void Function(int moves)? onWon;

  const BirdSortPlayScreen({
    super.key,
    required this.levelIndex,
    this.debugLevel,
    this.onWon,
  });

  @override
  State<BirdSortPlayScreen> createState() => _BirdSortPlayScreenState();
}

class _BirdSortPlayScreenState extends State<BirdSortPlayScreen> {
  late final Future<engine.Level> _levelFuture;
  PlayController? _controller;
  bool _winHandled = false;

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
    if (c.state.isWon && !_winHandled) {
      _winHandled = true;
      widget.onWon?.call(c.moveCount);
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

  Widget _controls(PlayController controller) {
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
          Text('Moves: ${controller.moveCount}',
              style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

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
