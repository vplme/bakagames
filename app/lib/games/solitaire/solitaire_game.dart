import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import '../../shell/registry.dart';
import '../../shell/settings.dart';
import '../shared/table_game.dart';
import '../shared/cozy_art.dart';
import 'model.dart';

const _night = Color(0xFF5A4B78);
const _gold = Color(0xFF806337);
const _definition = TableDefinition(
  'solitaire',
  'Moonlit Solitaire',
  'solitaire',
);
const _rules =
    'Draw one card from the stock. Build the seven columns downward in alternating red and dark suits. Move a face-up stack by tapping its top card, then another column. Only a King can fill an empty column.\n\nBuild each foundation from Ace to King in the same suit. Tap a card, then a foundation to send it home.\n\nYour twist: the moon pocket holds one exposed card. Park a card there to uncover a possibility, then play it back to a column or foundation. Tap a selected card again to cancel. Recycle the stock as often as you like. Some deals need a restart or another approach.';

GameEntry solitaireEntry({
  required ProgressStore store,
  required AppSettings settings,
}) {
  Widget play(int deal) =>
      SolitaireScreen(store: store, settings: settings, initialDeal: deal);
  Widget home(BuildContext context) => TableHome(
    definition: _definition,
    subtitle:
        'Sleepy bunnies. Lucky little stars.\nMake yourself a pocket of moonlight.',
    rules: _rules,
    footer: 'DRAW • DISCOVER • STARGAZE',
    accent: _night,
    preview: const SolitairePreview(),
    store: store,
    settings: settings,
    play: play,
  );
  return GameEntry(
    definition: _definition,
    category: 'Cards',
    subtitle: 'Classic Klondike with a magical moon pocket.',
    accentColor: _night,
    buildHomeScreen: home,
    buildLevelSelect: home,
    buildPlayScreen: (_, i) => play(i),
    buildPreview: (_) => const SolitairePreview(),
  );
}

class SolitairePreview extends StatelessWidget {
  const SolitairePreview({super.key});
  @override
  Widget build(BuildContext context) => CozyBackdrop(
    garden: false,
    child: Center(
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.rotate(
                  angle: (i - 1) * .16,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: SizedBox(
                      width: 65,
                      height: 94,
                      child: MoonCardFace(
                        card: i == 1 ? null : MoonCard(i, 1),
                        back: i == 1,
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

class MoonCardFace extends StatelessWidget {
  final MoonCard? card;
  final bool back, selected;
  final String? placeholder;
  const MoonCardFace({
    super.key,
    this.card,
    this.back = false,
    this.selected = false,
    this.placeholder,
  });
  @override
  Widget build(BuildContext context) {
    final color = card?.red == true ? const Color(0xFFB34E62) : _night;
    return Container(
      decoration: BoxDecoration(
        color: back
            ? const Color(0xFFCAB9E6)
            : card != null
            ? tableCream
            : Colors.white.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? _gold
              : card != null
              ? const Color(0xFFD5CFBD)
              : const Color(0xFFAC9CBD),
          width: selected ? 3 : 1,
        ),
        boxShadow: card != null || back
            ? const [
                BoxShadow(
                  color: Color(0x335A4B78),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: back
          ? Padding(
              padding: const EdgeInsets.all(3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: FittedBox(child: CozyFriend(bunny: true, size: 54)),
                  ),
                ),
              ),
            )
          : card == null
          ? Center(
              child: placeholder == '☾'
                  ? const Padding(
                      padding: EdgeInsets.all(3),
                      child: FittedBox(child: CozyFriend(size: 44)),
                    )
                  : ['♠', '♥', '♦', '♣'].contains(placeholder)
                  ? CozySuit(
                      suit: ['♠', '♥', '♦', '♣'].indexOf(placeholder!),
                      color: _gold,
                      size: 20,
                    )
                  : Text(
                      placeholder ?? '',
                      style: const TextStyle(color: _gold, fontSize: 22),
                    ),
            )
          : LayoutBuilder(
              builder: (context, bounds) => Stack(
                children: [
                  Positioned(
                    top: 3,
                    left: 4,
                    right: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card!.label.replaceAll(card!.symbol, ''),
                          maxLines: 1,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: bounds.maxWidth < 46 ? 12 : 16,
                          ),
                        ),
                        CozySuit(
                          suit: card!.suit,
                          color: color,
                          size: bounds.maxWidth < 46 ? 9 : 12,
                        ),
                      ],
                    ),
                  ),
                  if (card!.rank >= 11)
                    Positioned.fill(
                      top: 19,
                      bottom: 3,
                      child: Opacity(
                        opacity: .6,
                        child: FittedBox(child: CozyFriend(bunny: true)),
                      ),
                    ),
                  Align(
                    alignment: card!.rank >= 11
                        ? Alignment.bottomRight
                        : Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 15,
                        right: 3,
                        bottom: 2,
                      ),
                      child: CozySuit(
                        suit: card!.suit,
                        color: color,
                        size: bounds.maxWidth * (card!.rank >= 11 ? .28 : .48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class SolitaireScreen extends StatefulWidget {
  final ProgressStore store;
  final AppSettings settings;
  final int initialDeal;
  const SolitaireScreen({
    super.key,
    required this.store,
    required this.settings,
    this.initialDeal = 0,
  });
  @override
  State<SolitaireScreen> createState() => _SolitaireScreenState();
}

class _SolitaireScreenState extends State<SolitaireScreen> {
  late int deal = widget.initialDeal;
  late SolitaireBoard board = SolitaireBoard.deal(deal);
  CardSource? selected;
  int? hintedDestination;
  String notice =
      'Tap a card, then its destination. The moon keeps one card safe.';
  void reset({bool next = false}) => setState(() {
    if (next) deal = (deal + 1) % 30;
    board = SolitaireBoard.deal(deal);
    selected = null;
    hintedDestination = null;
    notice = 'A fresh sky of possibilities.';
  });
  void tap(int pile, [int? index]) {
    final cards = board.pile(pile);
    if (selected != null && board.move(selected!, pile)) {
      widget.settings.hapticTap();
      setState(() {
        selected = null;
        hintedDestination = null;
        notice = 'A little space for your next move.';
      });
      return;
    }
    final source = CardSource(pile, index ?? cards.length - 1);
    setState(() {
      hintedDestination = null;
      if (selected?.pile == source.pile && selected?.index == source.index) {
        selected = null;
        notice = 'Selection cleared.';
      } else if (board.cards(source).isNotEmpty) {
        selected = source;
        notice =
            '${board.cards(source).first.label} selected. Tap a column, foundation, or empty moon pocket.';
      } else {
        notice =
            'Build down in alternating colors; only Kings fill empty columns.';
      }
    });
  }

  void hint() => setState(() {
    final move = board.hint;
    if (move == null) {
      selected = null;
      hintedDestination = null;
      notice = board.stock.isNotEmpty
          ? 'Tap the bunny-backed stock to draw a card.'
          : board.waste.isNotEmpty
          ? 'Recycle the stock, or undo to explore another path.'
          : 'No moves found. Undo or try another deal.';
    } else {
      selected = move.$1;
      hintedDestination = move.$2;
      final destination = move.$2 == 8
          ? 'moon pocket'
          : move.$2 >= 9
          ? 'matching foundation'
          : 'highlighted column';
      notice = 'Move ${board.cards(move.$1).first.label} to the $destination.';
    }
  });
  Widget target(int pile, double width, double height, {String? placeholder}) {
    final cards = board.pile(pile);
    return Semantics(
      button: true,
      label:
          '${pile == 8
              ? 'Moon pocket'
              : pile >= 9
              ? 'Foundation ${['spades', 'hearts', 'diamonds', 'clubs'][pile - 9]}'
              : 'Waste'}: ${cards.isEmpty ? 'empty' : cards.last.label}',
      child: GestureDetector(
        key: Key('solitairePile$pile'),
        onTap: () => tap(pile),
        child: SizedBox(
          width: width,
          height: height,
          child: MoonCardFace(
            card: cards.isEmpty ? null : cards.last,
            placeholder: placeholder,
            selected: selected?.pile == pile || hintedDestination == pile,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => TablePlay(
    id: _definition.id,
    title: _definition.title,
    rules: _rules,
    status: '${board.gathered}/52 stars',
    deal: deal,
    moves: board.moves,
    won: board.won,
    canUndo: board.canUndo,
    accent: _night,
    settings: widget.settings,
    store: widget.store,
    restart: reset,
    next: () => reset(next: true),
    hint: hint,
    undo: () => setState(() {
      board.undo();
      selected = null;
      hintedDestination = null;
      notice = 'One move back. A new possibility.';
    }),
    child: TableBoardLayout(
      header: TableMessage(
        title: 'Bunnies under the moon',
        detail: notice,
        icon: Icons.nightlight_round,
      ),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Text(
          '${board.moves} moves · one cosy moon pocket',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _night, fontSize: 12),
        ),
      ),
      boardBuilder: (context, bounds) {
        final width = math.min(
              bounds.maxWidth,
              math.min(1000.0, math.max(304.0, bounds.maxHeight * 1.4)),
            ),
            cardWidth = (width - 6 * 5) / 7,
            cardHeight = (bounds.maxHeight * .17).clamp(
              cardWidth * 1.45,
              cardWidth * 2.0,
            );
        final maxCards = board.columns.fold<int>(
          1,
          (n, c) => math.max(n, c.length),
        );
        final labelHeight = MediaQuery.textScalerOf(context).scale(10) * 2 + 20;
        final minStep = math.max(
          27.0,
          MediaQuery.textScalerOf(context).scale(16) + 8,
        );
        final step =
            ((bounds.maxHeight - cardHeight * 2 - labelHeight) /
                    math.max(6, maxCards - 1))
                .clamp(minStep, math.max(minStep, cardHeight * .9))
                .toDouble();
        return Center(
          child: SizedBox(
            key: const Key('solitaireBoard'),
            width: width,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      button: true,
                      label:
                          'Stock: ${board.stock.length} cards. Tap to ${board.stock.isEmpty ? 'recycle' : 'draw'}',
                      child: GestureDetector(
                        key: const Key('solitaireStock'),
                        onTap: () {
                          if (board.draw()) {
                            widget.settings.hapticTap();
                            setState(() {
                              selected = null;
                              hintedDestination = null;
                              notice = board.waste.isEmpty
                                  ? 'Stock recycled.'
                                  : 'Drawn ${board.waste.last.label}.';
                            });
                          }
                        },
                        child: SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: MoonCardFace(
                            back: board.stock.isNotEmpty,
                            placeholder: '↻',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    target(7, cardWidth, cardHeight),
                    const SizedBox(width: 5),
                    target(8, cardWidth, cardHeight, placeholder: '☾'),
                    for (var i = 0; i < 4; i++) ...[
                      const SizedBox(width: 5),
                      target(
                        9 + i,
                        cardWidth,
                        cardHeight,
                        placeholder: ['♠', '♥', '♦', '♣'][i],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'STOCK  ·  WASTE  ·  MOON       A → K FOUNDATIONS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _gold,
                    fontSize: 10,
                    letterSpacing: .4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: cardHeight + (maxCards - 1) * step,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < 7; col++) ...[
                        if (col > 0) const SizedBox(width: 5),
                        SizedBox(
                          width: cardWidth,
                          child: Stack(
                            children: [
                              GestureDetector(
                                key: Key('solitaireColumn$col'),
                                onTap: () => tap(col),
                                child: SizedBox(
                                  width: cardWidth,
                                  height: cardHeight,
                                  child: MoonCardFace(
                                    placeholder: 'K',
                                    selected: hintedDestination == col,
                                  ),
                                ),
                              ),
                              for (
                                var row = 0;
                                row < board.columns[col].length;
                                row++
                              )
                                Positioned(
                                  top: row * step,
                                  width: cardWidth,
                                  height: cardHeight,
                                  child: Semantics(
                                    button: row >= board.hidden[col],
                                    selected:
                                        selected?.pile == col &&
                                        selected!.index == row,
                                    label: row < board.hidden[col]
                                        ? 'Face-down card'
                                        : '${board.columns[col][row].label}, column ${col + 1}',
                                    child: GestureDetector(
                                      key: Key('solitaireCard${col}_$row'),
                                      onTap: row < board.hidden[col]
                                          ? null
                                          : () => tap(col, row),
                                      child: MoonCardFace(
                                        card: row < board.hidden[col]
                                            ? null
                                            : board.columns[col][row],
                                        back: row < board.hidden[col],
                                        selected:
                                            selected?.pile == col &&
                                                row >= selected!.index ||
                                            hintedDestination == col,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
