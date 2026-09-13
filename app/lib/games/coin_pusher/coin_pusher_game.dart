import 'dart:async';
import 'dart:convert';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shell/registry.dart';
import '../../shell/settings.dart';
import '../../shell/settings_screen.dart';
import 'pusher_game.dart';
import 'pusher_model.dart';

class CoinPusherDefinition implements GameDefinition {
  @override
  String get id => 'coin_pusher';
  @override
  String get title => 'Pocket Pusher';
  @override
  String get iconName => 'coins';
  @override
  int get levelCount => 1;
}

GameEntry coinPusherEntry({required AppSettings settings}) => GameEntry(
  definition: CoinPusherDefinition(),
  category: 'Arcade',
  subtitle: 'A cosy little arcade. A shelf full of friends.',
  accentColor: teal,
  buildHomeScreen: (_) => PusherScreen(settings: settings),
  buildPlayScreen: (_, _) => PusherScreen(settings: settings),
  buildLevelSelect: (_) => PusherScreen(settings: settings),
  buildPreview: (_) => const _Preview(),
);

class _Preview extends StatelessWidget {
  const _Preview();
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/pusher/cosy-preview.webp',
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    semanticLabel: 'A cosy wooden coin pusher filled with plush toy prizes',
  );
}

class PusherScreen extends StatefulWidget {
  final AppSettings settings;
  const PusherScreen({super.key, required this.settings});
  @override
  State<PusherScreen> createState() => _PusherScreenState();
}

class _PusherScreenState extends State<PusherScreen>
    with WidgetsBindingObserver {
  final _prefs = SharedPreferencesAsync();
  PusherGame? _game;
  Timer? _timer;
  Future<void> _writes = Future.value();
  String? _error;
  bool _paused = false, _leaving = false;
  int _backgroundPauses = 0;
  double _aim = 5;
  String _message = 'Choose a spot, then drop a coin.';
  static const _key = 'coin_pusher.session.v1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _prefs.getString(_key);
      final model = PusherModel(
        saved: raw == null ? null : jsonDecode(raw) as Map<String, dynamic>,
      );
      model.introducePrizes();
      if (!mounted) return;
      setState(() {
        _error = null;
        _game = PusherGame(
          model,
          _tick,
          () =>
              widget.settings.reducedMotion.value ||
              (mounted && MediaQuery.disableAnimationsOf(context)),
        );
      });
      if (_paused) _game!.pauseEngine();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!_paused) _save();
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not load your machine. Retry to keep your saved game.',
        );
      }
    }
  }

  void _tick(int earned) {
    if (earned > 0 && mounted) {
      widget.settings.hapticTap();
      unawaited(widget.settings.playSound('pusher/coin.wav'));
      setState(
        () => _message = _game!.model.justRewards.isNotEmpty
            ? _game!.model.justRewards.join(' · ')
            : _game!.model.justUnlocked.isNotEmpty
            ? '${_game!.model.justUnlocked.join(' & ')} unlocked! New toys can now appear.'
            : _game!.model.justCollected.isEmpty
            ? '+$earned coins in the tray!'
            : '${_game!.model.justCollected.join(' & ')} collected!',
      );
      _save();
    }
  }

  Future<void> _save() {
    if (_game == null) return Future.value();
    final snapshot = jsonEncode(_game!.model.toJson());
    _writes = _writes.then((_) async {
      try {
        await _prefs.setString(_key, snapshot);
        if (mounted && _error != null) setState(() => _error = null);
      } catch (_) {
        if (mounted) {
          setState(
            () => _error = 'Save failed. Keep this screen open and retry.',
          );
        }
      }
    });
    return _writes;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _backgroundPauses++;
      _game?.pauseEngine();
      if (mounted) setState(() => _paused = true);
      _save();
    }
  }

  Future<void> _exit() async {
    _game?.pauseEngine();
    setState(() => _paused = true);
    await _save();
    if (!mounted || (_game != null && _error != null)) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _resetBoard() async {
    final game = _game;
    if (game == null) return;
    final wasPaused = _paused;
    game.pauseEngine();
    setState(() => _paused = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset this machine?'),
        content: const Text(
          'Replace the current board with fresh coins, new toys and 40 coins to spend. Your collected toys and lifetime total are kept. The current bonus meter will reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmPusherReset'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset board'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      game.model.resetBoard();
      setState(() => _message = 'Fresh coins, new friends. Ready to play!');
      await _save();
      if (!mounted) return;
    }
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!wasPaused &&
        _error == null &&
        (lifecycle == null || lifecycle == AppLifecycleState.resumed)) {
      setState(() => _paused = false);
      game.resumeEngine();
    }
  }

  void _drop() {
    if (_paused || _game == null) return;
    final ok = _game!.model.drop(_aim);
    setState(
      () => _message = ok
          ? 'Watch the next push…'
          : (_game!.model.dropBlockedReason ?? 'Try another spot.'),
    );
    if (ok) {
      widget.settings.hapticTap();
      unawaited(widget.settings.playSound('pusher/coin.wav'));
      _save();
    }
  }

  Future<void> _openCollection() async {
    final game = _game;
    if (game == null) return;
    final wasPaused = _paused;
    final backgroundPauses = _backgroundPauses;
    game.pauseEngine();
    setState(() => _paused = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFF6DF),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        minChildSize: .4,
        maxChildSize: .92,
        builder: (context, scroll) => Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Close collection',
                onPressed: () => Navigator.pop(sheetContext),
                icon: const Icon(Icons.close),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [_collectionShelf(game.model)],
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (!wasPaused && _backgroundPauses == backgroundPauses && _error == null) {
      setState(() => _paused = false);
      game.resumeEngine();
    }
  }

  Widget _collectionShelf(PusherModel model) => Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFECD5),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE8C5A1)),
    ),
    child: Column(
      children: [
        const Text(
          'Your cuddly collection',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF684A38),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          model.nextPrizeIndex == null
              ? 'All 8 milestones reached · All 11 toys unlocked!'
              : '${model.collected} / ${prizeUnlockCoins[model.nextPrizeIndex!]} coins'
                    ' · Next: ${prizeNames[model.nextPrizeIndex!]}',
          key: const Key('pusherUnlockProgress'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: model.nextPrizeIndex == null
              ? 1
              : (model.collected % 250) / 250,
          color: teal,
          backgroundColor: const Color(0xFFE6D8B4),
          semanticsLabel: 'Progress to the next toy unlock',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 330 ? 2 : 3;
            final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < prizeIds.length; i++)
                  SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Opacity(
                            opacity: model.collected >= prizeUnlockCoins[i]
                                ? 1
                                : .4,
                            child: Image.asset(
                              'assets/pusher/${prizeIds[i]}.webp',
                              height: 64,
                              semanticLabel: prizeNames[i],
                            ),
                          ),
                          Text(
                            prizeNames[i],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (model.collected < prizeUnlockCoins[i]) ...[
                            const Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: teal,
                            ),
                            Text(
                              '${prizeUnlockCoins[i]} coins',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ] else
                            Text(
                              '×${model.collection[prizeIds[i]] ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Unlock a new friend every 250 lifetime coins, up to 2,000. Unlocked toys can appear in the machine; push them into the front tray to keep them.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF6DF),
        appBar: AppBar(
          title: const Text('Pocket Pusher'),
          actions: [
            IconButton(
              tooltip: 'Reset board',
              icon: const Icon(Icons.restart_alt),
              onPressed: game == null ? null : _resetBoard,
            ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings),
              onPressed: () async {
                game?.pauseEngine();
                setState(() => _paused = true);
                await _save();
                if (!context.mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsScreen(settings: widget.settings),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: game == null
              ? Center(
                  child: _error == null
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${game.model.balance} coins',
                                      style: const TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w800,
                                        color: teal,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: _paused ? 'Resume' : 'Pause',
                                    onPressed: () {
                                      setState(() => _paused = !_paused);
                                      if (_paused) {
                                        game.pauseEngine();
                                        _save();
                                      } else {
                                        game.resumeEngine();
                                      }
                                    },
                                    icon: Icon(
                                      _paused ? Icons.play_arrow : Icons.pause,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${game.model.collected} collected · ${game.model.bonusRemaining} to +10 bonus',
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: game.model.bonus / 20,
                                color: teal,
                                backgroundColor: const Color(0xFFE6D8B4),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: (constraints.maxHeight * .57).clamp(
                                  310.0,
                                  510.0,
                                ),
                                child: AspectRatio(
                                  aspectRatio: .8,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: LayoutBuilder(
                                      builder: (context, boardConstraints) =>
                                          GestureDetector(
                                            onTapDown: _paused
                                                ? null
                                                : (details) {
                                                    final width =
                                                        boardConstraints
                                                            .maxWidth;
                                                    _aim = aimFromBoard(
                                                      details.localPosition.dx,
                                                      width,
                                                      game.model.pusherY + 1,
                                                    );
                                                    _drop();
                                                  },
                                            child: GameWidget(game: game),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _paused ? 'Machine paused' : _message,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  key: const Key('pusherDrop'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: teal,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                  onPressed: _paused
                                      ? null
                                      : game.model.balance == 0
                                      ? () {
                                          setState(() {
                                            game.model.refill();
                                            _message =
                                                '40 free coins. Keep pushing!';
                                          });
                                          _save();
                                        }
                                      : _drop,
                                  icon: const Icon(Icons.monetization_on),
                                  label: Text(
                                    game.model.balance == 0
                                        ? 'Refill 40 coins · Free'
                                        : 'Drop coin · 1',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap the machine to choose where to drop. The button repeats your last position.\nStack up to 3 coins. Front pays; sides lose. Blue coins pay 5.\nCollect 5 coins within 1 second for a large coin (10); collect 10 for a gold bar (25). Push rewards into the tray to cash in.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  key: const Key('pusherCollection'),
                                  onPressed: _openCollection,
                                  icon: const Icon(Icons.toys_outlined),
                                  label: const Text('Cuddly collection'),
                                ),
                              ),
                              if (_error != null) ...[
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                TextButton(
                                  onPressed: _save,
                                  child: const Text('Retry save'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
