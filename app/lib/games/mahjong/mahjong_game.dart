import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import '../../shell/registry.dart';
import '../../shell/settings.dart';
import '../shared/table_game.dart';
import 'lantern_art.dart';
import 'model.dart';
import 'levels.dart';

const _jade = lanternJade;
const _definition = TableDefinition('mahjong', 'Lantern Mahjong', 'mahjong');
const _rules =
    'Match two identical free tiles. A tile is free when nothing sits on top of it and its left or right side is open. Clear every layer to light the garden.\n\nTap a tile, then its partner. Bright tiles are free; shaded tiles are blocked. The small gold marks show each tile’s layer, from one at the bottom to four at the top. Later deals add more tiles, deeper stacks and trickier choices between identical symbols. From deal 19, free the numbered lantern tiles in order: uncover the marked stack and open a side. A move that frees a later lantern too early is blocked. Gold marks the next lantern. From deal 25, clear the board before the countdown ends. The clock starts with your first free tile or hint and pauses in the menu or when the app is in the background. Undo restores lanterns but does not refund time; restart gives a fresh clock. Hint lights a matching pair. If you run out of pairs, undo to try another path or restart the same solvable deal.';
GameEntry mahjongEntry({
  required ProgressStore store,
  required AppSettings settings,
}) {
  Widget play(int deal) =>
      MahjongScreen(store: store, settings: settings, initialDeal: deal);
  Widget home(BuildContext context) => TableHome(
    definition: _definition,
    subtitle:
        'Glowing lanterns. Jade gardens.\nFind a little magic in every matching pair.',
    rules: _rules,
    footer: 'PAIR • UNWIND • ILLUMINATE',
    accent: _jade,
    preview: const MahjongPreview(),
    store: store,
    settings: settings,
    play: play,
    summary: '30 deals · lantern objectives · timed expert levels',
    dealDescription: mahjongDealDescription,
  );
  return GameEntry(
    definition: _definition,
    category: 'Tile puzzle',
    subtitle: 'Match festival tiles beneath a sky of glowing lanterns.',
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
  Widget build(BuildContext context) => LanternBackdrop(
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
                        face: [2, 0, 1][i],
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
  final int face, layer;
  final bool free, selected, reducedMotion;
  const GardenTileFace({
    super.key,
    required this.face,
    required this.free,
    this.layer = 0,
    this.selected = false,
    this.reducedMotion = false,
  });
  @override
  Widget build(BuildContext context) {
    final duration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return AnimatedScale(
      scale: selected ? 1.06 : 1,
      duration: duration,
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: duration,
        transform: Matrix4.translationValues(0, selected ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .24),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
            if (selected)
              BoxShadow(
                color: lanternGold.withValues(alpha: .65),
                blurRadius: 15,
              ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The bottom and right edges are a solid tile body, not a shadow.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF72AC91),
                    Color(0xFF15534C),
                    Color(0xFF103D3A),
                  ],
                ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFF8CB398)),
              ),
            ),
            Positioned.fill(
              right: 3,
              bottom: 7,
              child: AnimatedContainer(
                duration: duration,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: selected
                        ? [const Color(0xFFFFF5C8), lanternGold]
                        : free
                        ? [const Color(0xFFFFFEF3), const Color(0xFFF3DFC2)]
                        : [const Color(0xFFD1DCC8), const Color(0xFFA6BBA6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFFFE09A)
                        : const Color(0xFFCCAD6F),
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i <= layer; i++)
                            Container(
                              width: 4,
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: selected
                                    ? _jade
                                    : const Color(0xFFB28C48),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: SizedBox.expand(
                            child: FestivalMotif(face: face),
                          ),
                        ),
                      ),
                      Text(
                        '${face + 1}',
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 10,
                          color: _jade,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _boardGutter = 12.0;
const _tileGap = 3.0;

// Match the exposed solid body so each upper tile rests on its support.
const _layerRise = 7.0;

Offset _tileOrigin(
  GardenTile tile,
  double tileWidth,
  double tileHeight,
  int layers,
) {
  final stackRise = (layers - 1) * _layerRise;
  return Offset(
    _boardGutter + _tileGap / 2 + tile.x * tileWidth,
    12 +
        stackRise +
        tile.y * (tileHeight + stackRise) -
        tile.layer * _layerRise,
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

class _MahjongScreenState extends State<MahjongScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late int deal = widget.initialDeal;
  late MahjongBoard board = MahjongBoard.deal(deal);
  late final AnimationController clock;
  bool clockStarted = false, menuOpen = false, foreground = true;
  int displayedSeconds = 0;
  Duration? get timeLimit => mahjongTimeLimit(deal);
  bool get timedOut => timeLimit != null && clock.value >= 1 && !board.won;
  Duration get timeLeft => Duration(
    milliseconds: ((timeLimit?.inMilliseconds ?? 0) * (1 - clock.value))
        .round(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    clock = AnimationController(
      vsync: this,
      duration: timeLimit ?? const Duration(minutes: 1),
      animationBehavior: AnimationBehavior.preserve,
    )..addListener(_clockTick);
    displayedSeconds = (timeLeft.inMilliseconds / 1000).ceil();
  }

  void _clockTick() {
    final seconds = (timeLeft.inMilliseconds / 1000).ceil();
    if (seconds == displayedSeconds || !mounted) return;
    setState(() {
      displayedSeconds = seconds;
      if (timedOut) {
        selected = null;
        hint = [];
        collections.clear();
      }
    });
  }

  void _syncClock() {
    if (timeLimit != null &&
        clockStarted &&
        foreground &&
        !menuOpen &&
        !timedOut &&
        !board.won) {
      if (!clock.isAnimating) clock.forward();
    } else {
      clock.stop();
    }
  }

  void _startClock() {
    if (timeLimit == null || clockStarted) return;
    clockStarted = true;
    _syncClock();
  }

  void _menuChanged(bool open) {
    setState(() => menuOpen = open);
    _syncClock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    _syncClock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    clock.dispose();
    super.dispose();
  }

  int? selected;
  int collectionSerial = 0;
  final collections = <int, List<int>>{};
  bool get reducedMotion =>
      widget.settings.reducedMotion.value ||
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
  List<int> hint = [];
  late String notice = mahjongDifficulty(deal).advice;
  void reset({bool next = false}) => setState(() {
    if (next) deal = (deal + 1) % 30;
    clock.stop();
    clockStarted = false;
    clock.duration = timeLimit ?? const Duration(minutes: 1);
    // Keep the listener from issuing a nested rebuild during reset.
    clock.removeListener(_clockTick);
    clock.reset();
    displayedSeconds = (timeLeft.inMilliseconds / 1000).ceil();
    clock.addListener(_clockTick);
    collections.clear();
    board = MahjongBoard.deal(deal);
    selected = null;
    hint = [];
    notice = mahjongDifficulty(deal).advice;
  });
  void tap(int id) {
    if (timedOut || menuOpen || !foreground) return;
    if (!board.isFree(id)) {
      setState(
        () => notice = 'Uncover this tile and open its left or right side.',
      );
      return;
    }
    _startClock();
    widget.settings.hapticTap();
    setState(() {
      hint = [];
      if (selected == id) {
        selected = null;
        return;
      }
      if (selected != null &&
          board.tiles[selected!].face == board.tiles[id].face) {
        final priorLanterns = board.lanternProgress;
        if (!board.match(selected!, id)) {
          notice =
              'Free lantern ${board.lanternProgress + 1} before later lanterns.';
          selected = null;
          return;
        }
        if (board.won) clock.stop();
        if (!reducedMotion) collections[collectionSerial++] = [selected!, id];
        selected = null;
        notice = board.hint == null && !board.won
            ? 'No free pairs. Undo a match to find another path.'
            : board.lanternProgress > priorLanterns
            ? 'Lantern ${board.lanternProgress} lit! ${board.lanternProgress == board.lanternTargets.length ? 'Now clear the garden.' : 'Free lantern ${board.lanternProgress + 1} next.'}'
            : 'A little more light reaches the garden.';
      } else {
        notice = selected == null
            ? 'Find another free ${festivalNames[board.tiles[id].face]}.'
            : 'Different faces. Find this tile’s matching partner.';
        selected = id;
      }
    });
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: widget.settings.reducedMotion,
    builder: (context, _, _) => TablePlay(
      id: _definition.id,
      title: _definition.title,
      rules: _rules,
      status: '${board.remaining ~/ 2} pairs left',
      deal: deal,
      moves: board.history.length,
      won: board.won,
      completionReady: collections.isEmpty,
      backgroundBuilder: (child) => LanternBackdrop(shaded: true, child: child),
      canUndo: board.history.isNotEmpty && !timedOut,
      canHint: !timedOut,
      onMenuChanged: _menuChanged,
      accent: _jade,
      settings: widget.settings,
      store: widget.store,
      restart: reset,
      next: () => reset(next: true),
      undo: () => setState(() {
        if (timedOut) return;
        collections.clear();
        board.undo();
        selected = null;
        hint = [];
        notice = 'One pair returned. Try a different path.';
      }),
      hint: () => setState(() {
        if (timedOut) return;
        _startClock();
        hint = board.hint ?? [];
        selected = null;
        notice = hint.isEmpty
            ? 'No free pairs. Undo a match or restart this deal.'
            : 'The golden tiles are a free matching pair.';
      }),
      child: timedOut
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.hourglass_bottom_rounded,
                          size: 44,
                          color: _jade,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Time’s up',
                          key: Key('mahjongTimedOut'),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'The garden is waiting. Try the same deal again with a fresh clock.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: reset,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : TableBoardLayout(
              header: Container(
                margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xEEFFF7E7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 32,
                      height: 36,
                      child: FestivalMotif(face: 0),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${mahjongDifficulty(deal).name} · ${board.layers} ${board.layers == 1 ? 'layer' : 'layers'}',
                            style: const TextStyle(
                              color: _jade,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            notice,
                            style: const TextStyle(
                              color: _jade,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                          if (board.lanternTargets.isNotEmpty ||
                              timeLimit != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  if (board.lanternTargets.isNotEmpty)
                                    Text(
                                      'Lanterns ${board.lanternProgress}/${board.lanternTargets.length}',
                                      key: const Key('mahjongLanternProgress'),
                                      style: const TextStyle(
                                        color: _jade,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  if (timeLimit != null)
                                    Text(
                                      '${mahjongClockLabel(timeLeft)}${!clockStarted
                                          ? ' · tap to start'
                                          : menuOpen
                                          ? ' · paused'
                                          : ' left'}',
                                      key: const Key('mahjongClock'),
                                      style: TextStyle(
                                        color: displayedSeconds <= 30
                                            ? const Color(0xFFAA2635)
                                            : _jade,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                      '${board.history.length} / ${board.pairCount} pairs',
                      style: const TextStyle(color: tableCream, fontSize: 12),
                    ),
                  ],
                ),
              ),
              boardBuilder: (context, bounds) {
                final width = math.min(
                  bounds.maxWidth,
                  math.max(
                    300.0,
                    (bounds.maxHeight - 28) /
                            board.rows /
                            1.24 *
                            board.columns +
                        24,
                  ),
                );
                final stackRise = (board.layers - 1) * _layerRise;
                final tileWidth = (width - 2 * _boardGutter) / board.columns,
                    tileHeight =
                        ((bounds.maxHeight - 28) / board.rows - stackRise)
                            .clamp(
                              math.max(72.0, tileWidth * 1.24),
                              math.max(72.0, tileWidth * 2.3),
                            )
                            .toDouble();
                return Center(
                  child: SizedBox(
                    key: const Key('mahjongBoard'),
                    width: width,
                    height: (tileHeight + stackRise) * board.rows + 28,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final tile in board.tiles)
                          if (!board.removed.contains(tile.id))
                            Positioned(
                              key: ValueKey('tile${tile.id}'),
                              left: _tileOrigin(
                                tile,
                                tileWidth,
                                tileHeight,
                                board.layers,
                              ).dx,
                              top: _tileOrigin(
                                tile,
                                tileWidth,
                                tileHeight,
                                board.layers,
                              ).dy,
                              width: tileWidth - 3,
                              height: tileHeight - 4,
                              child: Semantics(
                                button: true,
                                selected: selected == tile.id,
                                label:
                                    '${festivalNames[tile.face]}, layer ${tile.layer + 1}, ${board.isFree(tile.id) ? 'free' : 'blocked'} tile',
                                child: Tooltip(
                                  message:
                                      '${festivalNames[tile.face]} · layer ${tile.layer + 1} · ${board.isFree(tile.id) ? 'free' : 'blocked'}',
                                  child: GestureDetector(
                                    key: Key('mahjongTile${tile.id}'),
                                    onTap: () => tap(tile.id),
                                    child: GardenTileFace(
                                      reducedMotion: reducedMotion,
                                      face: tile.face,
                                      layer: tile.layer,
                                      free: board.isFree(tile.id),
                                      selected:
                                          selected == tile.id ||
                                          hint.contains(tile.id),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        for (
                          var index = 0;
                          index < board.lanternTargets.length;
                          index++
                        )
                          if (!board.removed.contains(
                            board.lanternTargets[index],
                          ))
                            Builder(
                              builder: (context) {
                                final target =
                                    board.tiles[board.lanternTargets[index]];
                                final top = board.tiles
                                    .where(
                                      (t) =>
                                          t.x == target.x &&
                                          t.y == target.y &&
                                          !board.removed.contains(t.id),
                                    )
                                    .reduce(
                                      (a, b) => a.layer > b.layer ? a : b,
                                    );
                                final position = _tileOrigin(
                                  top,
                                  tileWidth,
                                  tileHeight,
                                  board.layers,
                                );
                                final lit = index < board.lanternProgress;
                                final active = index == board.lanternProgress;
                                return Positioned(
                                  left: position.dx + tileWidth - 35,
                                  top: position.dy - 9,
                                  child: IgnorePointer(
                                    child: Semantics(
                                      label:
                                          'Lantern ${index + 1}, ${lit
                                              ? 'lit'
                                              : active
                                              ? 'free this tile next'
                                              : 'free after earlier lanterns'}',
                                      child: Container(
                                        key: ValueKey(
                                          'lanternMarker${index + 1}',
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: lit
                                              ? _jade
                                              : active
                                              ? lanternGold
                                              : tableCream,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(color: _jade),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              lit
                                                  ? Icons.check
                                                  : Icons.lightbulb_outline,
                                              size: 12,
                                              color: lit ? tableCream : _jade,
                                            ),
                                            Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: lit ? tableCream : _jade,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        for (final entry in collections.entries)
                          Positioned.fill(
                            key: ValueKey('collection${entry.key}'),
                            child: IgnorePointer(
                              child: PairCollection(
                                ids: entry.value,
                                board: board,
                                tileWidth: tileWidth,
                                tileHeight: tileHeight,
                                reducedMotion: reducedMotion,
                                onComplete: () {
                                  if (mounted) {
                                    setState(
                                      () => collections.remove(entry.key),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    ),
  );
}

/// Matched tiles linger together, then rise toward the lanterns. The engine
/// removes them immediately so the next free pair can be played during flight.
class PairCollection extends StatelessWidget {
  final List<int> ids;
  final MahjongBoard board;
  final double tileWidth, tileHeight;
  final bool reducedMotion;
  final VoidCallback onComplete;
  const PairCollection({
    super.key,
    required this.ids,
    required this.board,
    required this.tileWidth,
    required this.tileHeight,
    required this.reducedMotion,
    required this.onComplete,
  });
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 720),
    onEnd: onComplete,
    builder: (context, value, _) {
      final flight = ((value - .24) / .76).clamp(0.0, 1.0);
      final travel = Curves.easeInOutCubic.transform(flight);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < ids.length; i++)
            Builder(
              builder: (context) {
                final tile = board.tiles[ids[i]];
                final start = _tileOrigin(
                  tile,
                  tileWidth,
                  tileHeight,
                  board.layers,
                );
                final destination = Offset(
                  _boardGutter +
                      _tileGap / 2 +
                      tileWidth * (board.columns / 2 - 1 + i),
                  0,
                );
                final position = Offset.lerp(start, destination, travel)!;
                return Positioned(
                  left: position.dx,
                  top: position.dy - math.sin(flight * math.pi) * 28,
                  width: tileWidth - 3,
                  height: tileHeight - 4,
                  child: Opacity(
                    opacity: 1 - Curves.easeInCubic.transform(flight),
                    child: Transform.rotate(
                      angle: (i == 0 ? -1 : 1) * flight * .18,
                      child: Transform.scale(
                        scale: 1.06 - travel * .45,
                        child: Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.expand,
                          children: [
                            GardenTileFace(
                              face: tile.face,
                              layer: tile.layer,
                              free: true,
                              selected: true,
                              reducedMotion: true,
                            ),
                            for (var j = 0; j < 6; j++)
                              Positioned(
                                left:
                                    (tileWidth - 3) / 2 +
                                    math.cos(j * math.pi / 3) *
                                        (14 + flight * 40) -
                                    5,
                                top:
                                    (tileHeight - 4) / 2 +
                                    math.sin(j * math.pi / 3) *
                                        (14 + flight * 40) -
                                    5,
                                child: Opacity(
                                  opacity: math.sin(flight * math.pi),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: lanternGold,
                                    size: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      );
    },
  );
}
