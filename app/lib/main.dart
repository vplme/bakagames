import 'package:flutter/material.dart';

import 'games/bird_sort/play_screen.dart';

void main() {
  runApp(const BakaGamesApp());
}

class BakaGamesApp extends StatelessWidget {
  const BakaGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baka Games',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
      ),
      // Phase 3: straight into Bird Sort. Phase 4 replaces this with the
      // shell home screen.
      home: const BirdSortPlayScreen(levelIndex: 0),
    );
  }
}
