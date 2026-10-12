import 'deals.dart';

/// Difficulty metadata is cheap to read on menus; deals are generated offline.
class MahjongDifficulty {
  final String name, advice;
  const MahjongDifficulty(this.name, this.advice);
}

const mahjongDifficulties = [
  MahjongDifficulty('Gentle', 'Find pairs across the whole garden.'),
  MahjongDifficulty('Growing', 'Clear upper tiles to open more choices.'),
  MahjongDifficulty('Thoughtful', 'Compare matching pairs before choosing.'),
  MahjongDifficulty('Tricky', 'Open blocked sides before clearing easy pairs.'),
  MahjongDifficulty(
    'Expert',
    'Plan several pairs ahead through the tall stacks.',
  ),
];

MahjongDifficulty mahjongDifficulty(int deal) =>
    mahjongDifficulties[(deal % 30) ~/ 6];

String mahjongDealDescription(int deal) {
  final data = mahjongDeals[deal % mahjongDeals.length];
  final layers =
      data.tiles.map((t) => t[2]).reduce((a, b) => a > b ? a : b) + 1;
  final limit = mahjongTimeLimit(deal);
  return [
    '${mahjongDifficulty(deal).name} · ${data.tiles.length ~/ 2} pairs · $layers ${layers == 1 ? 'layer' : 'layers'}',
    if (mahjongLanternCount(deal) > 0)
      '${mahjongLanternCount(deal)} lanterns in order',
    if (limit != null) '${mahjongClockLabel(limit)} time limit',
  ].join(' · ');
}

int mahjongLanternCount(int deal) {
  final level = deal % 30;
  return level < 18
      ? 0
      : level < 21
      ? 2
      : level < 27
      ? 3
      : 4;
}

Duration? mahjongTimeLimit(int deal) {
  final level = deal % 30;
  return level < 24
      ? null
      : Duration(seconds: [480, 420, 390, 360, 330, 300][level - 24]);
}

String mahjongClockLabel(Duration time) {
  final seconds = (time.inMilliseconds / 1000).ceil().clamp(0, 9999);
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
