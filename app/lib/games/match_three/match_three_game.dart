import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:match_three/match_three.dart';
import 'package:match_three/levels.dart';

import 'sweet_piece.dart';
import 'sweets_preview.dart';
import 'sweets_home_screen.dart';
import 'sweets_style.dart';

import '../../shell/level_select_screen.dart';
import '../../shell/registry.dart';
import '../../shell/settings.dart';
import '../../shell/settings_screen.dart';
import '../../shell/play_controls.dart';

const _colors = sweetColors;
const _names = sweetNames;

MatchThree _createGame(int index) => sweetLevels[index].create();
(int, int)? _findHint(MatchThree game) => game.hint();
(MatchThree, List<ResolutionStep>) _resolve((MatchThree, int, int) input) =>
    (input.$1, input.$1.swap(input.$2, input.$3));

class MatchThreeDefinition implements GameDefinition {
  @override
  String get id => 'match_three';
  @override
  String get title => 'Pocket Sweets';
  @override
  String get iconName => 'sweets';
  @override
  int get levelCount => sweetLevels.length;
}

GameEntry matchThreeEntry({
  required ProgressStore store,
  required AppSettings settings,
}) {
  final definition = MatchThreeDefinition();
  Widget play(BuildContext context, int index) =>
      MatchThreePlayScreen(store: store, settings: settings, levelIndex: index);
  late final GameEntry entry;
  entry = GameEntry(
    definition: definition,
    subtitle: 'Juicy matches. Rainbow magic. A little sugar-coated escape.',
    category: 'Match three',
    accentColor: _colors.first,
    buildPreview: (_) => const SweetsPreview(),
    buildHomeScreen: (_) =>
        SweetsHomeScreen(entry: entry, store: store, settings: settings),
    buildPlayScreen: play,
    buildLevelSelect: (context) => SweetsBackdrop(
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          colorScheme: ColorScheme.fromSeed(seedColor: sweetsPink),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFFF2F8),
            foregroundColor: sweetsInk,
          ),
        ),
        child: LevelSelectScreen(
          definition: definition,
          store: store,
          buildPlayScreen: play,
        ),
      ),
    ),
  );
  return entry;
}

class MatchThreePlayScreen extends StatefulWidget {
  final ProgressStore store;
  final AppSettings settings;
  final int levelIndex;
  const MatchThreePlayScreen({
    super.key,
    required this.store,
    required this.settings,
    this.levelIndex = 0,
  });
  @override
  State<MatchThreePlayScreen> createState() => _MatchThreePlayScreenState();
}

class _MatchThreePlayScreenState extends State<MatchThreePlayScreen> {
  final _boardScroll = ScrollController();
  MatchThree? _game;
  Snapshot? _shown;
  int? _selected;
  Offset _drag = Offset.zero;
  Set<int> _hint = {};
  Map<int, Color> _bursts = {};
  int _burstSerial = 0;
  bool _busy = false;
  bool _saving = false;
  bool _saved = false;
  bool _completionDismissed = false;
  String? _saveError;
  String? _loadError;
  String _message = 'Tap two neighboring sweets or swipe to match three.';

  @override
  void initState() {
    super.initState();
    widget.settings.reducedMotion.addListener(_settingsChanged);
    _load();
  }

  void _settingsChanged() {
    if (mounted) {
      setState(() {
        _bursts = {};
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _completionDismissed = false;
      _busy = true;
      _loadError = null;
      _game = null;
      _shown = null;
      _selected = null;
      _hint = {};
      _bursts = {};
      _saved = false;
      _saveError = null;
    });
    try {
      final game = await compute(_createGame, widget.levelIndex);
      if (!mounted) return;
      setState(() {
        _game = game;
        _shown = game.state;
        _busy = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = 'Could not open this picnic.';
          _busy = false;
        });
      }
    }
  }

  Future<void> _hintMove() async {
    if (_busy || _game == null || _game!.won) return;
    setState(() {
      _completionDismissed = false;
      _busy = true;
    });
    try {
      final hint = await compute(_findHint, _game!);
      if (!mounted) return;
      setState(() {
        _hint = hint == null ? {} : {hint.$1, hint.$2};
        _selected = null;
        _message = 'Swap the two highlighted sweets.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Could not find a hint. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.settings.reducedMotion.removeListener(_settingsChanged);
    _boardScroll.dispose();
    super.dispose();
  }

  bool get _reduced =>
      widget.settings.reducedMotion.value ||
      MediaQuery.of(context).disableAnimations;

  Future<void> _swap(int a, int b) async {
    if (_busy || _game == null || _game!.won) return;
    setState(() {
      _completionDismissed = false;
      _busy = true;
      _selected = null;
      _hint = {};
      _bursts = {};
    });
    try {
      final result = await compute(_resolve, (_game!, a, b));
      if (!mounted) return;
      _game = result.$1;
      if (result.$2.isEmpty) {
        widget.settings.hapticError();
        if (!_reduced && MatchThree.adjacent(a, b)) {
          final prior = _game!.state;
          final board = prior.board.toList();
          final piece = board[a];
          board[a] = board[b];
          board[b] = piece;
          setState(() {
            _shown = Snapshot(
              board,
              prior.collected,
              prior.moves,
              prior.randomState,
              prior.nextId,
            );
          });
          await Future<void>.delayed(const Duration(milliseconds: 160));
          if (!mounted) return;
        }
        setState(() {
          _message = 'Try a swap that makes three in a row.';
        });
      } else {
        widget.settings.hapticTap();
        var wave = 0;
        if (_reduced && !_game!.won) {
          final waves = result.$2.where((step) => step.kind == 'clear').length;
          unawaited(widget.settings.playSound(_clearSound(waves)));
        }
        _message = result.$2.any((step) => step.kind == 'reshuffle')
            ? 'A fresh mix — keep collecting!'
            : result.$2.any((step) => step.kind == 'special')
            ? 'Sweet sweep!'
            : result.$2.any((step) => step.kind == 'create')
            ? 'A special sweet! Match stripes; swap rainbows.'
            : 'Sweet match!';
        for (final step in result.$2) {
          if (!mounted) return;
          if (_reduced) break;
          final cleared = <int, Color>{};
          setState(() {
            for (var i = 0; i < 49; i++) {
              if (_shown!.board[i] != null && step.state.board[i] == null) {
                cleared[i] = sweetColors[_shown!.board[i]!.type];
              }
            }
            if (cleared.isNotEmpty) {
              _bursts = cleared;
              _burstSerial++;
            }
            _shown = step.state;
            _message = switch (step.kind) {
              'reshuffle' => 'A fresh mix — keep collecting!',
              'special' => 'Sweet sweep!',
              'create' => 'A special sweet! Match stripes; swap rainbows.',
              _ => 'Sweet match!',
            };
          });
          // Special/create/clear may share a snapshot. Only the first
          // transition that actually removes sweets is a new audible wave.
          if (cleared.isNotEmpty &&
              const {'clear', 'special', 'create'}.contains(step.kind)) {
            wave++;
            unawaited(widget.settings.playSound(_clearSound(wave)));
          }
          await Future<void>.delayed(const Duration(milliseconds: 160));
        }
      }
      if (!mounted) return;
      setState(() {
        _shown = _game!.state;
        _bursts = {};
        _busy = false;
      });
      if (_game!.won) {
        unawaited(widget.settings.playSound('sweets/complete.wav'));
        await _save();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = 'Could not resolve that move. Please try again.';
        });
      }
    }
  }

  // Cap the pitch so long chains stay warm instead of becoming shrill.
  String _clearSound(int wave) => wave <= 1
      ? 'sweets/match.wav'
      : 'sweets/cascade_${(wave - 1).clamp(1, 5)}.wav';

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final prior = await widget.store.load('match_three');
      await widget.store.save(
        'match_three',
        prior.withCompleted(widget.levelIndex, _game!.state.moves),
      );
      if (mounted) {
        setState(() {
          _saved = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveError = 'Progress could not be saved.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _slideBoard(double offset) {
    if (_reduced) {
      _boardScroll.jumpTo(offset);
    } else {
      _boardScroll.animateTo(
        offset,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  void _tap(int index) {
    if (_busy || _game!.won) return;
    if (_selected != null && MatchThree.adjacent(_selected!, index)) {
      _swap(_selected!, index);
    } else {
      setState(() {
        _selected = _selected == index ? null : index;
        _hint = {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final game = _game;
    final showCompletion =
        game != null && game.won && !_busy && !_completionDismissed;
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4F1),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            excluding: showCompletion,
            child: ExcludeFocus(
              excluding: showCompletion,
              child: IgnorePointer(
                ignoring: showCompletion,
                child: SweetsBackdrop(
                  child: SafeArea(
                    child: _loadError != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_loadError!),
                                TextButton(
                                  onPressed: _load,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : shown == null || game == null
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    IconButton.filledTonal(
                                      tooltip: 'Back',
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFF1CEE3,
                                        ),
                                        foregroundColor: sweetsInk,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                      ),
                                    ),
                                    const Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            'POCKET SWEETS',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: sweetsInk,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2.6,
                                            ),
                                          ),
                                          Text(
                                            'a little moment of happy',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Color(0xFF926E87),
                                              fontSize: 10,
                                              letterSpacing: .6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      tooltip: 'Settings',
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFF1CEE3,
                                        ),
                                        foregroundColor: sweetsInk,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => SettingsScreen(
                                                settings: widget.settings,
                                              ),
                                            ),
                                          ),
                                      icon: const Icon(Icons.tune_rounded),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sweetLevels[widget.levelIndex].title
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Color(0xFF926080),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                          Text(
                                            'Level ${widget.levelIndex + 1}',
                                            style: const TextStyle(
                                              fontSize: 34,
                                              height: 1.2,
                                              fontWeight: FontWeight.w800,
                                              color: sweetsInk,
                                              letterSpacing: -1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: .8,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        'Moves: ${shown.moves}',
                                        style: const TextStyle(
                                          color: sweetsInk,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  sweetLevels[widget.levelIndex].tip,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    for (var t = 0; t < game.typeCount; t++)
                                      if (game.targets[t] > 0)
                                        Semantics(
                                          label:
                                              '${_names[t]}: ${shown.collected[t]} of ${game.targets[t]} collected',
                                          child: SugarCard(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SweetPiece(
                                                  piece: Sweet(t, t),
                                                  size: 32,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${shown.collected[t].clamp(0, game.targets[t])}/${game.targets[t]}',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final width = constraints.maxWidth.clamp(
                                      336.0,
                                      448.0,
                                    );
                                    final cell = width / 7;
                                    return Column(
                                      children: [
                                        Scrollbar(
                                          controller: _boardScroll,
                                          thumbVisibility:
                                              width > constraints.maxWidth,
                                          interactive: true,
                                          child: SingleChildScrollView(
                                            controller: _boardScroll,
                                            scrollDirection: Axis.horizontal,
                                            child: SizedBox(
                                              width: width,
                                              height: width,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors: [
                                                          Color(0xFF753D88),
                                                          Color(0xFF492754),
                                                        ],
                                                      ),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFFFD3EC,
                                                    ),
                                                    width: 2,
                                                  ),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color(0x405A2153),
                                                      offset: Offset(0, 8),
                                                      blurRadius: 20,
                                                    ),
                                                  ],
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    for (var i = 0; i < 49; i++)
                                                      Positioned(
                                                        left: i % 7 * cell,
                                                        top: i ~/ 7 * cell,
                                                        width: cell,
                                                        height: cell,
                                                        child: Semantics(
                                                          label:
                                                              'Row ${i ~/ 7 + 1}, column ${i % 7 + 1}, ${shown.board[i] == null ? 'empty' : sweetLabel(shown.board[i]!)}',
                                                          selected:
                                                              _selected == i,
                                                          button: true,
                                                          child: GestureDetector(
                                                            key: ValueKey(
                                                              'sweet-cell-$i',
                                                            ),
                                                            behavior:
                                                                HitTestBehavior
                                                                    .opaque,
                                                            onTap: () =>
                                                                _tap(i),
                                                            dragStartBehavior:
                                                                DragStartBehavior
                                                                    .down,
                                                            onHorizontalDragStart:
                                                                (_) {
                                                                  _drag = Offset
                                                                      .zero;
                                                                },
                                                            onHorizontalDragUpdate:
                                                                (details) {
                                                                  _drag +=
                                                                      details
                                                                          .delta;
                                                                },
                                                            onHorizontalDragEnd: (_) {
                                                              if (_drag.dx
                                                                      .abs() >=
                                                                  18) {
                                                                _swap(
                                                                  i,
                                                                  i +
                                                                      (_drag.dx >
                                                                              0
                                                                          ? 1
                                                                          : -1),
                                                                );
                                                              }
                                                            },
                                                            onVerticalDragStart:
                                                                (_) {
                                                                  _drag = Offset
                                                                      .zero;
                                                                },
                                                            onVerticalDragUpdate:
                                                                (details) {
                                                                  _drag +=
                                                                      details
                                                                          .delta;
                                                                },
                                                            onVerticalDragEnd: (_) {
                                                              if (_drag.dy
                                                                      .abs() >=
                                                                  18) {
                                                                _swap(
                                                                  i,
                                                                  i +
                                                                      (_drag.dy >
                                                                              0
                                                                          ? 7
                                                                          : -7),
                                                                );
                                                              }
                                                            },
                                                            child: Container(
                                                              margin:
                                                                  const EdgeInsets.all(
                                                                    2,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    _selected ==
                                                                            i ||
                                                                        _hint
                                                                            .contains(
                                                                              i,
                                                                            )
                                                                    ? const Color(
                                                                        0xFFFFD879,
                                                                      )
                                                                    : Colors.white.withValues(
                                                                        alpha:
                                                                            (i ~/ 7 +
                                                                                    i % 7)
                                                                                .isEven
                                                                            ? .15
                                                                            : .09,
                                                                      ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              child:
                                                                  const SizedBox.expand(),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    for (var i = 0; i < 49; i++)
                                                      if (shown.board[i] !=
                                                          null)
                                                        AnimatedPositioned(
                                                          key: ValueKey(
                                                            'sweet-piece-${shown.board[i]!.id}',
                                                          ),
                                                          duration: _reduced
                                                              ? Duration.zero
                                                              : const Duration(
                                                                  milliseconds:
                                                                      140,
                                                                ),
                                                          left: i % 7 * cell,
                                                          top: i ~/ 7 * cell,
                                                          width: cell,
                                                          height: cell,
                                                          child: IgnorePointer(
                                                            child: ExcludeSemantics(
                                                              child: AnimatedScale(
                                                                scale:
                                                                    _selected ==
                                                                            i ||
                                                                        _hint
                                                                            .contains(
                                                                              i,
                                                                            )
                                                                    ? 1.1
                                                                    : 1,
                                                                duration:
                                                                    _reduced
                                                                    ? Duration
                                                                          .zero
                                                                    : const Duration(
                                                                        milliseconds:
                                                                            130,
                                                                      ),
                                                                child: SweetPiece(
                                                                  piece: shown
                                                                      .board[i]!,
                                                                  size:
                                                                      cell *
                                                                      .91,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    if (!_reduced)
                                                      for (final burst
                                                          in _bursts.entries)
                                                        Positioned(
                                                          left:
                                                              burst.key %
                                                              7 *
                                                              cell,
                                                          top:
                                                              burst.key ~/
                                                              7 *
                                                              cell,
                                                          width: cell,
                                                          height: cell,
                                                          child: SugarBurst(
                                                            key: ValueKey(
                                                              'burst-$_burstSerial-${burst.key}',
                                                            ),
                                                            color: burst.value,
                                                          ),
                                                        ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (width > constraints.maxWidth)
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                tooltip:
                                                    'Show left side of board',
                                                onPressed: () => _slideBoard(0),
                                                icon: const Icon(
                                                  Icons.chevron_left,
                                                ),
                                              ),
                                              const Flexible(
                                                child: Text(
                                                  'Slide board',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip:
                                                    'Show right side of board',
                                                onPressed: () => _slideBoard(
                                                  _boardScroll
                                                      .position
                                                      .maxScrollExtent,
                                                ),
                                                icon: const Icon(
                                                  Icons.chevron_right,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _busy ? 'Collecting…' : _message,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    4,
                                    0,
                                    8,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: PlayControlButton(
                                          icon: Icons.undo,
                                          label: 'Undo',
                                          backgroundColor: const Color(
                                            0xFFF1CEE3,
                                          ),
                                          foregroundColor: sweetsInk,
                                          onPressed:
                                              _busy || _saving || !game.canUndo
                                              ? null
                                              : () {
                                                  setState(() {
                                                    game.undo();
                                                    _shown = game.state;
                                                    _selected = null;
                                                    _hint = {};
                                                    _saved = false;
                                                    _saveError = null;
                                                    _message =
                                                        'Last move undone.';
                                                  });
                                                },
                                        ),
                                      ),
                                      Expanded(
                                        child: PlayControlButton(
                                          icon: Icons.refresh,
                                          label: 'Restart',
                                          backgroundColor: const Color(
                                            0xFFF1CEE3,
                                          ),
                                          foregroundColor: sweetsInk,
                                          onPressed: _busy || _saving
                                              ? null
                                              : () {
                                                  _message = 'A fresh start!';
                                                  _load();
                                                },
                                        ),
                                      ),
                                      Expanded(
                                        child: PlayControlButton(
                                          icon: Icons.lightbulb_outline,
                                          label: 'Hint',
                                          backgroundColor: const Color(
                                            0xFFF1CEE3,
                                          ),
                                          foregroundColor: sweetsInk,
                                          onPressed: _busy || game.won
                                              ? null
                                              : _hintMove,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (game.won && !_busy && _completionDismissed)
                                  TextButton(
                                    onPressed: () => setState(
                                      () => _completionDismissed = false,
                                    ),
                                    child: const Text('Show completion'),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (showCompletion) ...[
            const ModalBarrier(dismissible: false, color: Color(0x80532149)),
            Semantics(
              scopesRoute: true,
              namesRoute: true,
              label: 'Level complete',
              explicitChildNodes: true,
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(child: _completionCard()),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _completionCard() => SugarCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Back to board',
            onPressed: () => setState(() => _completionDismissed = true),
            icon: const Icon(Icons.close_rounded, color: sweetsInk),
          ),
        ),
        const SweetPiece(piece: Sweet(0, 0, Special.color), size: 64),
        const SizedBox(height: 8),
        const Text(
          'Picnic complete!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (_saving) const Text('Saving progress…'),
        if (_saveError != null) ...[
          Text(_saveError!),
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Retry save'),
          ),
        ],
        if (_saved) ...[
          if (widget.levelIndex + 1 < sweetLevels.length)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: sweetsPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
              ),
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => MatchThreePlayScreen(
                    store: widget.store,
                    settings: widget.settings,
                    levelIndex: widget.levelIndex + 1,
                  ),
                ),
              ),
              child: const Text('Next level'),
            )
          else
            Text(
              'All ${sweetLevels.length} picnics complete. Come back for a favorite anytime!',
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to levels'),
          ),
        ],
      ],
    ),
  );
}
