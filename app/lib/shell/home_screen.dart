import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'registry.dart';
import 'settings.dart';
import 'settings_screen.dart';

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
      final p = await widget.store.load(entry.definition.id);
      if (!mounted) return;
      setState(() => _progress[entry.definition.id] = p);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baka Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => SettingsScreen(settings: widget.settings),
            )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final entry in widget.registry.games)
            _GameCard(
              entry: entry,
              progress: _progress[entry.definition.id],
              onOpen: () async {
                await Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (context) => entry.buildLevelSelect(context),
                ));
                _reload();
              },
            ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameEntry entry;
  final GameProgress? progress;
  final VoidCallback onOpen;

  const _GameCard(
      {required this.entry, required this.progress, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = progress;
    final summary = p == null
        ? '…'
        : p.completedCount == 0
            ? 'Not started'
            : '${p.completedCount} levels done · next: '
                'level ${p.highestUnlocked + 1}';
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: scheme.primaryContainer,
          child: Icon(iconFor(entry.definition.iconName),
              size: 30, color: scheme.onPrimaryContainer),
        ),
        title: Text(entry.definition.title,
            style: Theme.of(context).textTheme.titleLarge),
        subtitle: Text(summary),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}
