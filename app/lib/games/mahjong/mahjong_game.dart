import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import '../../shell/registry.dart';
import '../../shell/settings.dart';
import '../shared/table_game.dart';
import '../shared/cozy_art.dart';
import 'model.dart';

const _jade = Color(0xFF356859);
const _definition = TableDefinition('mahjong', 'Lantern Mahjong', 'mahjong');
const _rules =
    'Match two identical free tiles. A tile is free when nothing sits on top of it and its left or right side is open. Clear every layer to light the garden.\n\nTap a tile, then its partner. Bright tiles are free; shaded tiles are blocked. Hint lights a matching pair. If you run out of pairs, undo to try another path or restart the same solvable deal.';
const _faces = [
  Icons.local_florist,
  Icons.emoji_nature,
  Icons.wb_sunny_rounded,
  Icons.nightlight_round,
  Icons.spa,
  Icons.water_drop,
  Icons.filter_vintage,
  Icons.air,
  Icons.park,
  Icons.local_fire_department,
  Icons.star_rounded,
];
const _names = [
  'blossom',
  'butterfly',
  'sun',
  'moon',
  'leaf',
  'raindrop',
  'rosette',
  'breeze',
  'pine',
  'flame',
  'star',
];
const _colors = [
  Color(0xFFD98AA0),
  Color(0xFFC7A174),
  Color(0xFFE8BB60),
  Color(0xFFA296C9),
  Color(0xFF83B59B),
  Color(0xFF83B5CF),
];

GameEntry mahjongEntry({
  required ProgressStore store,
  required AppSettings settings,
}) {
  Widget play(int deal) =>
      MahjongScreen(store: store, settings: settings, initialDeal: deal);
  Widget home(BuildContext context) => TableHome(
    definition: _definition,
    subtitle:
        'Little blossoms. Blushing faces.\nA cosy garden full of matching friends.',
    rules: _rules,
    footer: 'PAIR • UNWIND • ILLUMINATE',
    accent: _jade,
    preview: const MahjongPreview(),
    store: store,
    settings: settings,
    play: play,
  );
  return GameEntry(
    definition: _definition,
    category: 'Tile puzzle',
    subtitle: 'Find matching friends in a tiny lantern garden.',
    accentColor: _jade,
    buildHomeScreen: home,
    buildLevelSelect: home,
    buildPlayScreen: (_, i) => play(i),
    buildPreview: (_) => const MahjongPreview(),
  );
}

class MahjongPreview extends StatelessWidget {
  const MahjongPreview({super.key});
  @override
  Widget build(BuildContext context) => CozyBackdrop(
    garden: true,
    child: Center(
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.rotate(
                  angle: (i - 1) * .12,
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: SizedBox(
                      width: 70,
                      height: 96,
                      child: GardenTileFace(
                        face: [4, 0, 4][i],
                        free: true,
                        selected: i == 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class GardenTileFace extends StatelessWidget {
  final int face;
  final bool free, selected;
  const GardenTileFace({
    super.key,
    required this.face,
    required this.free,
    this.selected = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: selected
          ? const Color(0xFFFFE5A1)
          : free
          ? tableCream
          : const Color(0xFFB8CDBF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: selected ? const Color(0xFFEDBB4F) : const Color(0xFFA4BDA6),
        width: selected ? 3 : 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0xFF8EAE9A),
          offset: Offset(0, 4),
          blurRadius: 0,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: FittedBox(
              child: SizedBox.square(
                dimension: 40,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Icon(
                      _faces[face],
                      color: _colors[face % _colors.length],
                      size: 38,
                    ),
                    const TinySmile(),
                  ],
                ),
              ),
            ),
          ),
          Text(
            '${face + 1}',
            style: const TextStyle(
              fontSize: 10,
              color: _jade,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class MahjongScreen extends StatefulWidget {
  final ProgressStore store;
  final AppSettings settings;
  final int initialDeal;
  const MahjongScreen({
    super.key,
    required this.store,
    required this.settings,
    this.initialDeal = 0,
  });
  @override
  State<MahjongScreen> createState() => _MahjongScreenState();
}

class _MahjongScreenState extends State<MahjongScreen> {
  late int deal = widget.initialDeal;
  late MahjongBoard board = MahjongBoard.deal(deal);
  int? selected;
  List<int> hint = [];
  String notice = 'Open sides. Matching faces. A moment of calm.';
  void reset({bool next = false}) => setState(() {
    if (next) deal = (deal + 1) % 30;
    board = MahjongBoard.deal(deal);
    selected = null;
    hint = [];
    notice = 'Open sides. Matching faces. A moment of calm.';
  });
  void tap(int id) {
    if (!board.isFree(id)) {
      setState(
        () => notice = 'Uncover this tile and open its left or right side.',
      );
      return;
    }
    widget.settings.hapticTap();
    setState(() {
      hint = [];
      if (selected == id) {
        selected = null;
        return;
      }
      if (selected != null && board.match(selected!, id)) {
        selected = null;
        notice = board.hint == null && !board.won
            ? 'No free pairs. Undo a match to find another path.'
            : 'A little more light reaches the garden.';
      } else {
        notice = selected == null
            ? 'Find another free ${_names[board.tiles[id].face]}.'
            : 'Different faces. Find this tile’s matching partner.';
        selected = id;
      }
    });
  }

  @override
  Widget build(BuildContext context) => TablePlay(
    id: _definition.id,
    title: _definition.title,
    rules: _rules,
    status: '${board.remaining ~/ 2} pairs left',
    deal: deal,
    moves: board.history.length,
    won: board.won,
    canUndo: board.history.isNotEmpty,
    accent: _jade,
    settings: widget.settings,
    store: widget.store,
    restart: reset,
    next: () => reset(next: true),
    undo: () => setState(() {
      board.undo();
      selected = null;
      hint = [];
      notice = 'One pair returned. Try a different path.';
    }),
    hint: () => setState(() {
      hint = board.hint ?? [];
      selected = null;
      notice = hint.isEmpty
          ? 'No free pairs. Undo a match or restart this deal.'
          : 'The golden tiles are a free matching pair.';
    }),
    child: TableBoardLayout(
      header: TableMessage(
        title: 'A little lantern garden',
        detail: notice,
        icon: Icons.local_florist_outlined,
      ),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 1 - board.remaining / board.tiles.length,
                  minHeight: 6,
                  color: const Color(0xFFE9C983),
                  backgroundColor: Colors.white54,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${board.history.length} / 22 pairs',
              style: const TextStyle(color: _jade, fontSize: 12),
            ),
          ],
        ),
      ),
      boardBuilder: (context, bounds) {
        final width = math.min(
          bounds.maxWidth,
          math.max(300.0, (bounds.maxHeight - 28) / 5 / 1.24 * 6 + 24),
        );
        final tileWidth = (width - 24) / 6,
            tileHeight = ((bounds.maxHeight - 28) / 5).clamp(
              tileWidth * 1.24,
              tileWidth * 2.3,
            );
        return Center(
          child: SizedBox(
            key: const Key('mahjongBoard'),
            width: width,
            height: tileHeight * 5 + 28,
            child: Stack(
              children: [
                for (final tile in board.tiles)
                  if (!board.removed.contains(tile.id))
                    Positioned(
                      left: tile.x * tileWidth + tile.layer * 5,
                      top: tile.y * tileHeight - tile.layer * 5 + 12,
                      width: tileWidth - 3,
                      height: tileHeight - 4,
                      child: Semantics(
                        button: true,
                        selected: selected == tile.id,
                        label:
                            '${_names[tile.face]}, ${board.isFree(tile.id) ? 'free' : 'blocked'} tile',
                        child: Tooltip(
                          message:
                              '${_names[tile.face]} · ${board.isFree(tile.id) ? 'free' : 'blocked'}',
                          child: GestureDetector(
                            key: Key('mahjongTile${tile.id}'),
                            onTap: () => tap(tile.id),
                            child: GardenTileFace(
                              face: tile.face,
                              free: board.isFree(tile.id),
                              selected:
                                  selected == tile.id || hint.contains(tile.id),
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
