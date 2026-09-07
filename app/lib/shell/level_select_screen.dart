import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

/// Reusable level-select grid: locked / unlocked / completed tiles.
/// Any registered game can build one of these from its entry.
class LevelSelectScreen extends StatefulWidget {
  final GameDefinition definition;
  final ProgressStore store;
  final Widget Function(BuildContext context, int levelIndex) buildPlayScreen;

  const LevelSelectScreen({
    super.key,
    required this.definition,
    required this.store,
    required this.buildPlayScreen,
  });

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  GameProgress? _progress;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final p = await widget.store.load(widget.definition.id);
    if (mounted) setState(() => _progress = p);
  }

  Future<void> _open(int index) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => widget.buildPlayScreen(context, index),
    ));
    // Progress may have advanced (including via "next level" chains).
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return Scaffold(
      appBar: AppBar(title: Text(widget.definition.title)),
      body: progress == null
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 72,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: widget.definition.levelCount,
              itemBuilder: (context, i) {
                final completed = progress.results[i]?.completed ?? false;
                final unlocked = i <= progress.highestUnlocked;
                final scheme = Theme.of(context).colorScheme;
                return Material(
                  color: completed
                      ? scheme.primaryContainer
                      : unlocked
                          ? scheme.surfaceContainerHighest
                          : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: unlocked ? () => _open(i) : null,
                    child: Center(
                      child: unlocked
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${i + 1}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                if (completed)
                                  Icon(Icons.star_rounded,
                                      size: 16, color: scheme.primary),
                              ],
                            )
                          : Icon(Icons.lock_outline,
                              size: 18, color: scheme.outline),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
