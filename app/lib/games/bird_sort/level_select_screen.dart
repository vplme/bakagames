import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'aviary.dart';

/// Reusable level-select grid: locked / unlocked / completed tiles.
/// Any registered game can build one of these from its entry.
class AviaryLevelSelectScreen extends StatefulWidget {
  final GameDefinition definition;
  final ProgressStore store;
  final Widget Function(BuildContext context, int levelIndex) buildPlayScreen;

  const AviaryLevelSelectScreen({
    super.key,
    required this.definition,
    required this.store,
    required this.buildPlayScreen,
  });

  @override
  State<AviaryLevelSelectScreen> createState() =>
      _AviaryLevelSelectScreenState();
}

class _AviaryLevelSelectScreenState extends State<AviaryLevelSelectScreen> {
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => widget.buildPlayScreen(context, index),
      ),
    );
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
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: (widget.definition.levelCount / 10).ceil(),
              itemBuilder: (context, chapter) => Container(
                margin: const EdgeInsets.only(bottom: 20),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE3E5D6)),
                ),
                child: Column(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minHeight: 110),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(habitatAsset(chapter * 10)),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        color: aviaryCream.withValues(alpha: .45),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HABITAT ${chapter + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w800,
                                color: aviaryInk,
                              ),
                            ),
                            Text(
                              habitatName(chapter * 10),
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: aviaryInk,
                              ),
                            ),
                            Text(
                              'Levels ${chapter * 10 + 1}–${chapter * 10 + 10}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: aviaryInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 5,
                      padding: const EdgeInsets.all(14),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        for (var n = 0; n < 10; n++)
                          _levelTile(chapter * 10 + n, progress),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _levelTile(int i, GameProgress progress) {
    final completed = progress.results[i]?.completed ?? false;
    final unlocked = i <= progress.highestUnlocked;
    return Semantics(
      label:
          'Level ${i + 1}${completed
              ? ', complete'
              : unlocked
              ? ''
              : ', locked'}',
      button: true,
      child: Material(
        color: completed
            ? const Color(0xFFDCEBD6)
            : unlocked
            ? const Color(0xFFF4D38B)
            : const Color(0xFFF2F3EA),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: unlocked ? () => _open(i) : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (unlocked)
                Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: aviaryInk,
                  ),
                )
              else
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 17,
                  color: Color(0xFFA6AD9C),
                ),
              if (completed)
                const Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: Color(0xFF8CA56E),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
