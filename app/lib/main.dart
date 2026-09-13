import 'package:flutter/material.dart';

import 'games/bird_sort/bird_sort_game.dart';
import 'games/coin_pusher/coin_pusher_game.dart';
import 'games/match_three/match_three_game.dart';
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
    coinPusherEntry(settings: settings),
    birdSortEntry(store: store, settings: settings),
    matchThreeEntry(store: store, settings: settings),
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF386B55)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF9E9),
      ),
      home: HomeScreen(registry: registry, store: store, settings: settings),
    );
  }
}
