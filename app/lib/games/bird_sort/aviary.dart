import 'package:flutter/material.dart';

const aviaryInk = Color(0xFF244C42);
const aviaryCream = Color(0xFFFFF9E9);
const birdNames = [
  'Cardinal',
  'Blue jay',
  'Canary',
  'Parakeet',
  'Owl',
  'Finch',
  'Kingfisher',
  'Cockatoo',
];
const birdFiles = [
  'cardinal',
  'blue-jay',
  'canary',
  'parakeet',
  'owl',
  'finch',
  'kingfisher',
  'cockatoo',
];
const birdNicknames = [
  'Pip',
  'Skye',
  'Sunny',
  'Kiwi',
  'Luna',
  'Mango',
  'River',
  'Peaches',
];
const unlockAt = [0, 0, 0, 3, 8, 15, 24, 35];
int collectedCount(int completed) =>
    unlockAt.where((n) => completed >= n).length;
String habitatName(int level) =>
    ['Sunny garden', 'Cherry grove', 'Moonlit forest'][(level ~/ 10) % 3];
String habitatAsset(int level) =>
    'assets/aviary/${['garden', 'cherry', 'moon'][(level ~/ 10) % 3]}.webp';

class BirdArt extends StatelessWidget {
  final int species;
  final double? size;
  const BirdArt({super.key, required this.species, this.size});
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/aviary/${birdFiles[species % 8]}.webp',
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    semanticLabel: birdNames[species % 8],
  );
}

class CollectionSheet extends StatelessWidget {
  final int completed;
  const CollectionSheet({super.key, required this.completed});
  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .72,
    minChildSize: .4,
    maxChildSize: .92,
    builder: (context, scroll) => ListView(
      controller: scroll,
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Your pocket aviary',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: aviaryInk,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${collectedCount(completed)} of 8 friends discovered · $completed levels completed',
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < 8; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                leading: Opacity(
                  opacity: completed >= unlockAt[i] ? 1 : .35,
                  child: BirdArt(species: i, size: 62),
                ),
                title: Text(
                  '${birdNicknames[i]} · ${birdNames[i]}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  completed >= unlockAt[i]
                      ? 'At home in your aviary'
                      : '${unlockAt[i] - completed} more levels to discover',
                ),
                trailing: Icon(
                  completed >= unlockAt[i]
                      ? Icons.favorite_rounded
                      : Icons.lock_outline,
                  color: const Color(0xFFDA8A65),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
