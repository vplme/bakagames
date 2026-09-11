import 'match_three.dart';

/// Stable authored campaign: indices and seeds must not be reordered.
class SweetLevel {
  final String title;
  final int seed;
  final List<int> targets;
  final SpecialRules specials;
  const SweetLevel(
    this.title,
    this.seed,
    this.targets, [
    this.specials = SpecialRules.none,
  ]);

  MatchThree create() =>
      MatchThree(seed: seed, targets: targets, specials: specials);

  String get tip => switch (specials) {
    SpecialRules.none =>
      'Match three to collect sweets. Take as many moves as you like.',
    SpecialRules.lines =>
      'Match four for a striped sweet. Match it again to clear its row or column.',
    SpecialRules.all =>
      'Match five for a rainbow sweet. Swap it with a neighbor to clear that color.',
  };
}

const sweetLevels = [
  SweetLevel('A little berry picnic', 731, [12, 12, 12, 0, 0]),
  SweetLevel('Mint meadow', 1429, [0, 15, 0, 12, 0]),
  SweetLevel('Starry basket', 2063, [12, 0, 18, 0, 0]),
  SweetLevel('Honey afternoon', 3911, [0, 12, 0, 18, 12]),
  SweetLevel('A tiny treat', 4591, [9, 0, 0, 0, 9]),
  SweetLevel('Lovely lines', 5801, [18, 18, 0, 0, 0], SpecialRules.lines),
  SweetLevel('Ribbon garden', 6271, [0, 18, 18, 0, 0], SpecialRules.lines),
  SweetLevel('Honey ribbons', 7907, [0, 0, 18, 21, 0], SpecialRules.lines),
  SweetLevel('Blueberry lane', 8089, [18, 0, 0, 18, 18], SpecialRules.lines),
  SweetLevel('A quiet cup', 9431, [0, 12, 0, 0, 12], SpecialRules.lines),
  SweetLevel('Rainbow welcome', 10037, [18, 18, 18, 0, 0], SpecialRules.all),
  SweetLevel('Colorful clouds', 11213, [0, 21, 0, 21, 18], SpecialRules.all),
  SweetLevel('Berry bonbons', 12503, [24, 0, 21, 0, 18], SpecialRules.all),
  SweetLevel('Golden gathering', 13829, [0, 21, 18, 24, 0], SpecialRules.all),
  SweetLevel('Little lemonade', 14591, [12, 0, 0, 12, 0], SpecialRules.all),
  SweetLevel('The sweet orchard', 15619, [24, 24, 0, 0, 21], SpecialRules.all),
  SweetLevel('Minty moonlight', 16831, [0, 27, 24, 0, 21], SpecialRules.all),
  SweetLevel('Starlight supper', 17923, [21, 0, 27, 24, 0], SpecialRules.all),
  SweetLevel('A basket for everyone', 18041, [
    18,
    18,
    18,
    18,
    18,
  ], SpecialRules.all),
  SweetLevel('Soft summer rain', 19463, [0, 0, 12, 0, 15], SpecialRules.all),
  SweetLevel('Rainbow river', 20507, [27, 24, 0, 0, 24], SpecialRules.all),
  SweetLevel('Honey hillside', 21649, [0, 24, 24, 30, 0], SpecialRules.all),
  SweetLevel('The berry bakery', 22817, [30, 0, 24, 0, 27], SpecialRules.all),
  SweetLevel('Garden party', 23957, [21, 21, 21, 21, 21], SpecialRules.all),
  SweetLevel('One more biscuit', 24049, [15, 15, 0, 0, 0], SpecialRules.all),
  SweetLevel('Twilight treats', 25219, [27, 0, 30, 0, 27], SpecialRules.all),
  SweetLevel('A golden evening', 26317, [0, 27, 0, 33, 27], SpecialRules.all),
  SweetLevel('A sky full of sweets', 27457, [
    24,
    24,
    24,
    24,
    24,
  ], SpecialRules.all),
  SweetLevel('The grand picnic', 28603, [27, 27, 27, 27, 27], SpecialRules.all),
  SweetLevel('A sweet goodbye', 29741, [18, 18, 18, 18, 18], SpecialRules.all),
];
