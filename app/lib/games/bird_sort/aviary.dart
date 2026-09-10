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
  'Puffin',
  'Woodpecker',
  'Toucan',
  'Dove',
  'Quail',
  'Hoopoe',
  'Hummingbird',
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
  'puffin',
  'woodpecker',
  'toucan',
  'dove',
  'quail',
  'hoopoe',
  'hummingbird',
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
  'Pebble',
  'Woody',
  'Rio',
  'Pearl',
  'Dot',
  'Cleo',
  'Jewel',
];
const unlockAt = [0, 0, 0, 3, 8, 15, 24, 35, 48, 63, 80, 99, 120, 143, 168];
int collectedCount(int completed) =>
    unlockAt.where((n) => completed >= n).length;

/// One scene for each ten-level chapter, in progression order.
const aviaryHabitats = <({String name, String file})>[
  (name: 'Sunny garden', file: 'garden'),
  (name: 'Cherry grove', file: 'cherry'),
  (name: 'Moonlit forest', file: 'moon'),
  (name: 'Willow pond', file: 'habitat-willow'),
  (name: 'Bamboo glade', file: 'habitat-bamboo'),
  (name: 'Lavender meadow', file: 'habitat-lavender'),
  (name: 'Mangrove lagoon', file: 'habitat-mangrove'),
  (name: 'Pine ridge', file: 'habitat-pine'),
  (name: 'Sunflower field', file: 'habitat-sunflower'),
  (name: 'Redwood sanctuary', file: 'habitat-redwood'),
  (name: 'Lotus marsh', file: 'habitat-lotus'),
  (name: 'Autumn orchard', file: 'habitat-autumn'),
  (name: 'Seaside dunes', file: 'habitat-coast'),
  (name: 'Rainforest clearing', file: 'habitat-rainforest'),
  (name: 'Birch meadow', file: 'habitat-birch'),
  (name: 'Desert oasis', file: 'habitat-desert'),
  (name: 'Wisteria arbor', file: 'habitat-wisteria'),
  (name: 'Golden wetlands', file: 'habitat-wetland'),
  (name: 'Cloud forest', file: 'habitat-cloud'),
  (name: 'Heather moor', file: 'habitat-heather'),
  (name: 'Maple hollow', file: 'habitat-maple'),
  (name: 'Coral cove', file: 'habitat-coral'),
  (name: 'Wildflower valley', file: 'habitat-meadow'),
  (name: 'Cedar creek', file: 'habitat-cedar'),
  (name: 'Snowy grove', file: 'habitat-snow'),
  (name: 'Hibiscus garden', file: 'habitat-hibiscus'),
  (name: 'Papyrus delta', file: 'habitat-papyrus'),
  (name: 'Olive terrace', file: 'habitat-olive'),
  (name: 'Waterfall hollow', file: 'habitat-waterfall'),
  (name: 'Acacia savanna', file: 'habitat-acacia'),
  (name: 'Bluebell wood', file: 'habitat-bluebell'),
  (name: 'Rain garden', file: 'habitat-monsoon'),
  (name: 'Peach blossom vale', file: 'habitat-peach'),
  (name: 'Cypress bayou', file: 'habitat-cypress'),
  (name: 'Fern grotto', file: 'habitat-fern'),
  (name: 'Poppy hillside', file: 'habitat-poppy'),
  (name: 'Juniper plateau', file: 'habitat-juniper'),
  (name: 'Iris waterway', file: 'habitat-iris'),
  (name: 'Chestnut grove', file: 'habitat-chestnut'),
  (name: 'Banana grove', file: 'habitat-banana'),
  (name: 'Arctic summer', file: 'habitat-tundra'),
  (name: 'Marigold garden', file: 'habitat-marigold'),
  (name: 'Eucalyptus woodland', file: 'habitat-eucalyptus'),
  (name: 'Moonflower garden', file: 'habitat-moonflower'),
  (name: 'Tea hills', file: 'habitat-tea'),
  (name: 'Bougainvillea courtyard', file: 'habitat-bougainvillea'),
  (name: 'Golden larch lake', file: 'habitat-larch'),
  (name: 'Firefly glen', file: 'habitat-firefly'),
  (name: 'Magnolia haven', file: 'habitat-magnolia'),
  (name: 'Rainbow valley', file: 'habitat-rainbow'),
];

String habitatName(int level) =>
    aviaryHabitats[(level ~/ 10) % aviaryHabitats.length].name;
String habitatAsset(int level) =>
    'assets/aviary/${aviaryHabitats[(level ~/ 10) % aviaryHabitats.length].file}.webp';

class BirdArt extends StatelessWidget {
  final int species;
  final double? size;
  const BirdArt({super.key, required this.species, this.size});
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/aviary/${birdFiles[species % birdNames.length]}.webp',
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    semanticLabel: birdNames[species % birdNames.length],
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
          '${collectedCount(completed)} of ${birdNames.length} friends discovered · $completed levels completed',
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < birdNames.length; i++)
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
