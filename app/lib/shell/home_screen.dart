import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'registry.dart';
import 'settings.dart';
import 'settings_screen.dart';

const _ink = Color(0xFF303449);

/// Shared game library. Themes and artwork are supplied by each game entry.
class HomeScreen extends StatefulWidget {
  final GameRegistry registry;
  final ProgressStore store;
  final AppSettings settings;
  const HomeScreen({
    super.key,
    required this.registry,
    required this.store,
    required this.settings,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, GameProgress> _progress = {};
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    for (final entry in widget.registry.games) {
      final progress = await widget.store.load(entry.definition.id);
      if (!mounted) return;
      setState(() => _progress[entry.definition.id] = progress);
    }
  }

  Future<void> _open(GameEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: entry.buildHomeScreen ?? entry.buildLevelSelect,
      ),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F5F0),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E5F3),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.widgets_rounded,
                      color: Color(0xFF77709D),
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'Baka Games',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    icon: const Icon(Icons.settings, color: _ink),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SettingsScreen(settings: widget.settings),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Small games.\nGood breaks.',
                style: TextStyle(
                  fontSize: 37,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pick a little world to get lost in.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777A88),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'YOUR GAMES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Color(0xFF777A88),
                      ),
                    ),
                  ),
                  Text(
                    '${widget.registry.games.length} to explore',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF777A88),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, box) {
                  final columns = box.maxWidth >= 640 ? 2 : 1;
                  final width = (box.maxWidth - (columns - 1) * 20) / columns;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      for (final entry in widget.registry.games)
                        SizedBox(
                          width: width,
                          child: _GameCard(
                            entry: entry,
                            progress: _progress[entry.definition.id],
                            onOpen: () => _open(entry),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (widget.registry.games.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Your next little adventure is on its way.',
                    style: TextStyle(color: _ink),
                  ),
                ),
              const SizedBox(height: 25),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 15,
                    color: Color(0xFF9694A0),
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Your progress stays with each game.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9694A0), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GameCard extends StatelessWidget {
  final GameEntry entry;
  final GameProgress? progress;
  final VoidCallback onOpen;
  const _GameCard({
    required this.entry,
    required this.progress,
    required this.onOpen,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(27),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('game-card-${entry.definition.id}'),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child:
                        entry.buildPreview?.call(context) ??
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                entry.accentColor.withValues(alpha: .12),
                                entry.accentColor.withValues(alpha: .3),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              iconFor(entry.definition.iconName),
                              size: 86,
                              color: entry.accentColor,
                            ),
                          ),
                        ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      entry.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w800,
                        color: entry.accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.definition.title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  entry.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF777A88),
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  progress == null
                      ? 'Loading progress…'
                      : progress!.completedCount == 0
                      ? 'Ready for your first level'
                      : '${progress!.completedCount} levels completed · Level ${progress!.highestUnlocked + 1} next',
                  style: TextStyle(
                    fontSize: 11,
                    color: entry.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: progress == null
                        ? 0
                        : math.min(
                            1,
                            progress!.completedCount /
                                math.max(1, entry.definition.levelCount),
                          ),
                    color: entry.accentColor.withValues(alpha: .65),
                    backgroundColor: entry.accentColor.withValues(alpha: .08),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      'Explore game',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: entry.accentColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: entry.accentColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
