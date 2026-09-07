import 'package:flutter/material.dart';

import 'games/bird_sort/bird_sort_game.dart';
import 'shell/home_screen.dart';
import 'shell/progress_store.dart';
import 'shell/registry.dart';
import 'shell/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();
  final store = SharedPrefsProgressStore();
  final registry = GameRegistry([
    birdSortEntry(store: store, settings: settings),
    // Future games: add one entry here.
  ]);
  runApp(BakaGamesApp(registry: registry, store: store, settings: settings));
}

class BakaGamesApp extends StatelessWidget {
  final GameRegistry registry;
  final SharedPrefsProgressStore store;
  final AppSettings settings;

  const BakaGamesApp({
    super.key,
    required this.registry,
    required this.store,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baka Games',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
      ),
      home: HomeScreen(registry: registry, store: store, settings: settings),
    );
  }
}
