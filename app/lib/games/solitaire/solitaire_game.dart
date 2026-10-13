import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import '../../shell/registry.dart';
import '../../shell/settings.dart';
import '../shared/table_game.dart';
import '../shared/cozy_art.dart';
import 'model.dart';
import 'moon_garden_art.dart';
import '../../shell/settings_screen.dart';

const _night = moonInk;
const _gold = moonGold;

class _SolitaireDefinition implements GameDefinition {
  const _SolitaireDefinition();
  @override
  String get id => 'solitaire';
  @override
  String get title => 'Moonlit Solitaire';
  @override
  String get iconName => 'solitaire';
  @override
  int get levelCount => 0;
}

const _definition = _SolitaireDefinition();
const _rules =
    'Draw one card from the stock. Build the seven columns downward in alternating red and dark suits. Move a face-up stack by tapping its top card, then another column. Only a King can fill an empty column.\n\nBuild each foundation from Ace to King in the same suit. Tap a card, then a foundation to send it home.\n\nYour twist: the moon pocket holds one exposed card. Park a card there to uncover a possibility, then play it back to a column or foundation. Tap a selected card again to cancel. Recycle the stock as often as you like. Start a new deal whenever you like; this shuffles a fresh deck.';

GameEntry solitaireEntry({
  required ProgressStore store,
  required AppSettings settings,
}) {
  Widget play() => SolitaireScreen(store: store, settings: settings);
  Widget home(BuildContext context) =>
      _MoonGardenHome(settings: settings, play: play);
  return GameEntry(
    definition: _definition,
    category: 'Cards',
    subtitle: 'An enchanted garden. A fresh deck. A pocket of moonlight.',
    accentColor: _night,
    buildHomeScreen: home,
    buildLevelSelect: home,
    buildPlayScreen: (_, _) => play(),
    showsLevelProgress: false,
    buildPreview: (_) => const SolitairePreview(),
  );
}

class SolitairePreview extends StatelessWidget {
  const SolitairePreview({super.key});
  @override
  Widget build(BuildContext context) => MoonGardenBackdrop(
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
    final color = card?.red == true ? const Color(0xFFA93258) : _night;
    return Container(
      decoration: BoxDecoration(
        color: back
            ? const Color(0xFF283D68)
            : card != null
            ? tableCream
            : const Color(0xAA172A47),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected || placeholder == '☾'
              ? _gold
              : card != null
              ? const Color(0xFFC4AC7B)
              : const Color(0xFFAD9BCE),
          width: selected ? 3 : 1,
        ),
        boxShadow: selected || placeholder == '☾'
            ? [
                BoxShadow(
                  color: moonGold.withValues(alpha: .32),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : card != null || back
            ? const [
                BoxShadow(
                  color: Color(0x335A4B78),
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: back
          ? Padding(
              padding: const EdgeInsets.all(3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: moonGold.withValues(alpha: .6)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: MoonEmblem(ornate: true),
                  ),
                ),
              ),
            )
          : card == null
          ? Center(
              child: placeholder == '☾'
                  ? const Padding(
                      padding: EdgeInsets.all(3),
                      child: MoonEmblem(),
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
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
  const SolitaireScreen({
    super.key,
    required this.store,
    required this.settings,
  });
  @override
  State<SolitaireScreen> createState() => _SolitaireScreenState();
}

class _SolitaireScreenState extends State<SolitaireScreen> {
  SolitaireBoard board = SolitaireBoard.deal();
  CardSource? selected;
  int? glowingFoundation;
  int foundationPulse = 0;
  int? hintedDestination;
  String notice =
      'Tap a card, then its destination. The moon keeps one card safe.';
  void reset() => setState(() {
    board = SolitaireBoard.deal();
    glowingFoundation = null;
    selected = null;
    hintedDestination = null;
    notice = 'A fresh sky of possibilities.';
  });
  void tap(int pile, [int? index]) {
    final cards = board.pile(pile);
    if (selected != null && board.move(selected!, pile)) {
      glowingFoundation = pile >= 9 ? pile : null;
      foundationPulse++;
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
          ? 'Tap the moon-backed stock to draw a card.'
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              MoonCardFace(
                card: cards.isEmpty ? null : cards.last,
                placeholder: placeholder,
                selected: selected?.pile == pile || hintedDestination == pile,
              ),
              if (pile == glowingFoundation &&
                  cards.isNotEmpty &&
                  !widget.settings.reducedMotion.value &&
                  !MediaQuery.disableAnimationsOf(context))
                FoundationStars(
                  key: ValueKey('foundation-$pile-$foundationPulse'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: widget.settings.reducedMotion,
    builder: (context, reducedMotion, _) => TablePlay(
      id: _definition.id,
      title: _definition.title,
      backgroundBuilder: (child) => MoonGardenBackdrop(
        shaded: true,
        reducedMotion: reducedMotion,
        child: child,
      ),
      rules: _rules,
      status: '${board.gathered}/52 stars',
      deal: 0,
      numberedDeals: false,
      moves: board.moves,
      won: board.won,
      canUndo: board.canUndo,
      accent: _night,
      settings: widget.settings,
      store: widget.store,
      restart: reset,
      next: reset,
      hint: hint,
      undo: () => setState(() {
        board.undo();
        glowingFoundation = null;
        selected = null;
        hintedDestination = null;
        notice = 'One move back. A new possibility.';
      }),
      child: TableBoardLayout(
        header: Container(
          margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          decoration: BoxDecoration(
            color: tableCream.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TableMessage(
            title: 'Under the moonflowers',
            detail: notice,
            icon: Icons.nightlight_round,
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Text(
            '${board.moves} moves · one cosy moon pocket',
            textAlign: TextAlign.center,
            style: const TextStyle(color: moonGold, fontSize: 12),
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
          final labelHeight =
              MediaQuery.textScalerOf(context).scale(10) * 2 + 20;
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
                    'STOCK  ·  WASTE  ·  MOON       A–K FOUNDATIONS',
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
    ),
  );
}

class _MoonGardenHome extends StatelessWidget {
  final AppSettings settings;
  final Widget Function() play;
  const _MoonGardenHome({required this.settings, required this.play});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: moonInk,
    body: ValueListenableBuilder<bool>(
      valueListenable: settings.reducedMotion,
      builder: (context, reducedMotion, _) => MoonGardenBackdrop(
        reducedMotion: reducedMotion,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: tableCream,
                          backgroundColor: moonInk.withValues(alpha: .8),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('All games'),
                      ),
                      const Spacer(),
                      IconButton.filledTonal(
                        tooltip: 'Settings',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => SettingsScreen(settings: settings),
                          ),
                        ),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 170),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xF21A2947),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: moonGold.withValues(alpha: .5)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 24),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'THE ENCHANTED MOON GARDEN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: moonGold,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Moonlit\nSolitaire',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: tableCream,
                            fontSize: 44,
                            height: 1.05,
                            letterSpacing: -1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'A quiet pond. A sky full of stars.\nA little moonlight just for you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: moonLilac,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: moonGold,
                              foregroundColor: moonInk,
                              padding: const EdgeInsets.symmetric(
                                vertical: 17,
                                horizontal: 12,
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(builder: (_) => play()),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Play a new deal'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Freshly shuffled. No levels. No hurry.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: moonLilac, fontSize: 11),
                        ),
                        const SizedBox(height: 16),
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: const Material(
                            color: Colors.transparent,
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              iconColor: moonGold,
                              collapsedIconColor: moonGold,
                              title: Text(
                                'How to play',
                                style: TextStyle(
                                  color: tableCream,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              leading: Icon(
                                Icons.menu_book_outlined,
                                color: moonGold,
                              ),
                              children: [
                                Text(
                                  _rules,
                                  style: TextStyle(
                                    color: tableCream,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'SHUFFLE  ·  UNWIND  ·  STARGAZE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: moonGold,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
