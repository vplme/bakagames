import 'package:flutter/material.dart';
import '../../shell/settings.dart';
import '../../shell/settings_screen.dart';

/// Aviary-style landing layout with artwork and destinations owned by each game.
class ArcadeHome extends StatelessWidget {
  final String title, subtitle, action, summary, progressTitle, progressDetail;
  final String firstLabel, secondLabel, footer;
  final IconData firstIcon, secondIcon;
  final Color accent, background;
  final Widget preview, progressArt;
  final double progress;
  final WidgetBuilder play, firstDestination, secondDestination;
  final AppSettings settings;
  final VoidCallback? onReturn;
  const ArcadeHome({
    super.key,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.summary,
    required this.progressTitle,
    required this.progressDetail,
    required this.firstLabel,
    required this.secondLabel,
    required this.footer,
    required this.firstIcon,
    required this.secondIcon,
    required this.accent,
    required this.background,
    required this.preview,
    required this.progressArt,
    required this.progress,
    required this.play,
    required this.firstDestination,
    required this.secondDestination,
    required this.settings,
    this.onReturn,
  });

  Future<void> _open(BuildContext context, WidgetBuilder destination) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: destination),
    );
    onReturn?.call();
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    WidgetBuilder destination,
  ) => Material(
    color: Colors.white.withValues(alpha: .82),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _open(context, destination),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: accent),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: accent, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: background,
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [background, Color.lerp(background, accent, .12)!],
        ),
      ),
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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('All games'),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Settings',
                      icon: const Icon(Icons.settings),
                      onPressed: () => _open(
                        context,
                        (_) => SettingsScreen(settings: settings),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 45,
                    height: 1.04,
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: accent, fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 30),
                SizedBox(height: 175, child: preview),
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(19),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: () => _open(context, play),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(action),
                ),
                const SizedBox(height: 10),
                Text(
                  summary,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: accent),
                ),
                const SizedBox(height: 22),
                Material(
                  color: Colors.white.withValues(alpha: .85),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _open(context, secondDestination),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                      child: Row(
                        children: [
                          SizedBox(width: 44, height: 52, child: progressArt),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progressTitle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LinearProgressIndicator(
                                    value: progress.clamp(0, 1),
                                    minHeight: 5,
                                    color: const Color(0xFFE8B257),
                                    backgroundColor: const Color(0xFFEEEEDD),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  progressDetail,
                                  style: TextStyle(fontSize: 10, color: accent),
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
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _tile(
                        context,
                        firstIcon,
                        firstLabel,
                        firstDestination,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tile(
                        context,
                        secondIcon,
                        secondLabel,
                        secondDestination,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  footer,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accent,
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

/// Three game characters arranged like Aviary's birds on their perch.
class ArcadeCharacters extends StatelessWidget {
  final List<Widget> characters;
  final Color shelf;
  const ArcadeCharacters({
    super.key,
    required this.characters,
    required this.shelf,
  });
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.bottomCenter,
    children: [
      Container(
        height: 22,
        margin: const EdgeInsets.only(bottom: 13),
        decoration: BoxDecoration(
          color: shelf,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      Positioned.fill(
        bottom: 20,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < characters.length; i++)
              Expanded(
                child: SizedBox(
                  height: i == 1 ? 145 : 127,
                  child: characters[i],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
