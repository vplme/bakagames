import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:match_three/match_three.dart';
import 'package:match_three/levels.dart';
import '../../shell/registry.dart';
import '../../shell/settings.dart';
import '../../shell/settings_screen.dart';
import 'sweet_piece.dart';
import 'sweets_preview.dart';
import 'sweets_style.dart';

class SweetsHomeScreen extends StatefulWidget {
  final GameEntry entry;
  final ProgressStore store;
  final AppSettings settings;
  const SweetsHomeScreen({
    super.key,
    required this.entry,
    required this.store,
    required this.settings,
  });
  @override
  State<SweetsHomeScreen> createState() => _SweetsHomeScreenState();
}

class _SweetsHomeScreenState extends State<SweetsHomeScreen> {
  GameProgress? _progress;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final progress = await widget.store.load(widget.entry.definition.id);
      if (mounted) {
        setState(() {
          _progress = progress;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
        });
      }
    }
  }

  Future<void> _open(WidgetBuilder builder) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
    if (mounted) await _reload();
  }

  void _guide() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFFFFF3F9),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sweet guide',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: sweetsInk,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Swap two neighboring sweets to match three. Collect the sweets shown above the board, with as many moves as you like.',
              style: TextStyle(height: 1.5, color: sweetsInk),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var type = 0; type < 5; type++)
                  Semantics(
                    label: sweetNames[type],
                    child: SweetPiece(piece: Sweet(type, type), size: 44),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _guideRow(
              const Sweet(0, 1, Special.row),
              'Striped sweets',
              'From level 6: match four in a line. Match the striped sweet to sweep its row or column.',
            ),
            const SizedBox(height: 16),
            _guideRow(
              const Sweet(0, 2, Special.color),
              'Rainbow sweets',
              'From level 11: match five in a line. Swap a rainbow with a neighbor to collect that color.',
            ),
            const SizedBox(height: 20),
            const Text(
              'Hints, undo, and fresh starts are always free. No timers. No lives. Just one lovely match at a time.',
              style: TextStyle(height: 1.5, color: sweetsInk),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _guideRow(Sweet piece, String title, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SweetPiece(piece: piece, size: 58),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: sweetsInk,
              ),
            ),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(height: 1.5, color: sweetsInk)),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final count = _progress?.completedCount ?? 0;
    final total = sweetLevels.length;
    final next = (_progress?.highestUnlocked ?? 0).clamp(0, total - 1);
    return Scaffold(
      body: SweetsBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 10, 28, 28),
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: sweetsInk),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('All games'),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Settings',
                        icon: const Icon(Icons.settings, color: sweetsInk),
                        onPressed: () => _open(
                          (_) => SettingsScreen(settings: widget.settings),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'Pocket Sweets',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 45,
                      height: 1.04,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      color: sweetsInk,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Little sweets. Lovely cascades.\nA candy-colored world to brighten your day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sweetsInk,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 175, child: SweetsHero()),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: sweetsPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(19),
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    onPressed: _progress == null
                        ? null
                        : () => _open(
                            (context) =>
                                widget.entry.buildPlayScreen(context, next),
                          ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('Play level ${next + 1}'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _progress == null
                        ? 'Loading your picnics…'
                        : '$count levels completed · no rush, just sweets',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: sweetsInk),
                  ),
                  if (_failed)
                    TextButton(
                      onPressed: _reload,
                      child: const Text('Retry loading progress'),
                    ),
                  const SizedBox(height: 22),
                  SugarCard(
                    padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                    child: Row(
                      children: [
                        const SweetPiece(
                          piece: Sweet(0, 2, Special.color),
                          size: 48,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                count >= total
                                    ? 'Every picnic, a little sweeter.'
                                    : 'Your sweet little journey',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: sweetsInk,
                                ),
                              ),
                              const SizedBox(height: 7),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: (count / total).clamp(0, 1),
                                  minHeight: 5,
                                  color: sweetsPink,
                                  backgroundColor: const Color(0xFFF1DCEB),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _progress == null
                                    ? 'Thirty picnics to explore'
                                    : '$count of $total picnics complete',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: sweetsInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _tile(
                          Icons.explore_outlined,
                          'Level path',
                          () => _open(widget.entry.buildLevelSelect),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _tile(
                          Icons.auto_awesome_rounded,
                          'Sweet guide',
                          _guide,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'SWAP • SPARKLE • UNWIND',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sweetsInk,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) => Material(
    color: Colors.white.withValues(alpha: .85),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: sweetsInk),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: sweetsInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
