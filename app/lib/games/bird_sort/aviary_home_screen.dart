import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'aviary.dart';
import '../../shell/registry.dart';
import '../../shell/settings.dart';
import '../../shell/settings_screen.dart';

class AviaryHomeScreen extends StatefulWidget {
  final GameEntry entry;
  final ProgressStore store;
  final AppSettings settings;
  const AviaryHomeScreen({
    super.key,
    required this.entry,
    required this.store,
    required this.settings,
  });
  @override
  State<AviaryHomeScreen> createState() => _AviaryHomeScreenState();
}

class _AviaryHomeScreenState extends State<AviaryHomeScreen> {
  final Map<String, GameProgress> _progress = {};
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    for (final entry in [widget.entry]) {
      final p = await widget.store.load(entry.definition.id);
      if (!mounted) return;
      setState(() => _progress[entry.definition.id] = p);
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Positioned.fill(child: Image.asset(habitatAsset(0), fit: BoxFit.cover)),
        Positioned.fill(
          child: ColoredBox(color: aviaryCream.withValues(alpha: .48)),
        ),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 10, 28, 28),
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('All games'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Settings',
                    icon: const Icon(Icons.settings),
                    onPressed: () =>
                        _open(SettingsScreen(settings: widget.settings)),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              for (final entry in [widget.entry]) ...[
                Text(
                  entry.definition.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 45,
                    height: 1.04,
                    color: aviaryInk,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tiny birds. Big personalities.\nA whole little world to bring together.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: aviaryInk, fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 175,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        height: 22,
                        margin: const EdgeInsets.only(bottom: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA97545),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        bottom: 20,
                        child: BirdArt(species: 0, size: 127),
                      ),
                      const Positioned(
                        right: 0,
                        bottom: 20,
                        child: BirdArt(species: 1, size: 127),
                      ),
                      const Positioned(
                        bottom: 20,
                        child: BirdArt(species: 2, size: 145),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: aviaryInk,
                    padding: const EdgeInsets.all(19),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: _progress[entry.definition.id] == null
                      ? null
                      : () => _open(
                          entry.buildPlayScreen(
                            context,
                            _progress[entry.definition.id]!.highestUnlocked,
                          ),
                        ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    'Play level ${(_progress[entry.definition.id]?.highestUnlocked ?? 0) + 1}',
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    '${_progress[entry.definition.id]?.completedCount ?? 0} levels completed · no rush, just birds',
                    style: const TextStyle(fontSize: 11, color: aviaryInk),
                  ),
                ),
                const SizedBox(height: 22),
                _collectionProgress(
                  _progress[entry.definition.id]?.completedCount ?? 0,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _tile(
                        Icons.explore_outlined,
                        'Level path',
                        () => _open(entry.buildLevelSelect(context)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tile(
                        Icons.favorite_border_rounded,
                        'My birds',
                        () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          backgroundColor: aviaryCream,
                          builder: (_) => CollectionSheet(
                            completed:
                                _progress[entry.definition.id]
                                    ?.completedCount ??
                                0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              const Text(
                'SORT • DISCOVER • UNWIND',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: aviaryInk,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _tile(IconData icon, String label, VoidCallback onTap) => Material(
    color: Colors.white.withValues(alpha: .82),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: aviaryInk),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: aviaryInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _collectionProgress(int completed) {
    final count = collectedCount(completed);
    final next = count < 8 ? unlockAt[count] : completed;
    final previous = count > 3 ? unlockAt[count - 1] : 0;
    final progress = count == 8
        ? 1.0
        : ((completed - previous) / (next - previous)).clamp(0.0, 1.0);
    return InkWell(
      key: const ValueKey('aviary-collection-progress'),
      borderRadius: BorderRadius.circular(20),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: aviaryCream,
        builder: (_) => CollectionSheet(completed: completed),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E7D6)),
        ),
        child: Row(
          children: [
            BirdArt(species: count < 8 ? count : 7, size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 8
                        ? 'Every friend, together.'
                        : '${birdNicknames[count]} is getting closer!',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: aviaryInk,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      color: const Color(0xFFE8B257),
                      backgroundColor: const Color(0xFFEEEEDD),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count == 8
                        ? 'Your collection is complete'
                        : '${next - completed} levels to discover · $count/8 birds',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7D8B7A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: Color(0xFFB28C48),
            ),
          ],
        ),
      ),
    );
  }
}
