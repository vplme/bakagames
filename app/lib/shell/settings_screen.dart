import 'package:flutter/material.dart';

import 'settings.dart';

class SettingsScreen extends StatelessWidget {
  final AppSettings settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: settings.soundOn,
            builder: (context, on, _) => SwitchListTile(
              secondary: const Icon(Icons.volume_up),
              title: const Text('Sound'),
              subtitle: const Text('Sound effects (coming soon)'),
              value: on,
              onChanged: settings.setSound,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.hapticsOn,
            builder: (context, on, _) => SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: const Text('Haptics'),
              subtitle: const Text('Vibration on moves and errors'),
              value: on,
              onChanged: settings.setHaptics,
            ),
          ),
        ],
      ),
    );
  }
}
