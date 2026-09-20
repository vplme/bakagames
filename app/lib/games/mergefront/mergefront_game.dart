import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:game_core/game_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shell/registry.dart';
import '../../shell/settings.dart';
import 'art.dart';
import 'audio.dart';
import 'model.dart';

class MergefrontDefinition implements GameDefinition {
  @override
  String get id => 'mergefront';
  @override
  String get title => 'Squad Rusher';
  @override
  String get iconName => 'squad';
  @override
  int get levelCount => Level.all.length;
}

GameEntry mergefrontEntry({required AppSettings settings}) => GameEntry(
  definition: MergefrontDefinition(),
  category: 'Squad arcade',
  subtitle: 'Tiny squad. Big breakthroughs. Your coast to reclaim.',
  accentColor: cyan,
  buildPreview: (_) => const SquadRusherCover(),
  buildHomeScreen: (_) => MergefrontScreen(settings: settings),
  buildLevelSelect: (_) => MergefrontScreen(settings: settings),
  buildPlayScreen: (_, level) =>
      MergefrontScreen(settings: settings, initialLevel: level),
);

class MergefrontStore {
  final SharedPreferencesAsync preferences;
  MergefrontStore([SharedPreferencesAsync? preferences])
    : preferences = preferences ?? SharedPreferencesAsync();
  Future<Profile> load() async {
    final raw = await preferences.getString('mergefront.profile.v1');
    return raw == null
        ? Profile()
        : Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(Profile profile) => preferences.setString(
    'mergefront.profile.v1',
    jsonEncode(profile.toJson()),
  );
}

class MergefrontScreen extends StatefulWidget {
  final AppSettings settings;
  final MergefrontStore? store;
  final int initialLevel;
  const MergefrontScreen({
    super.key,
    required this.settings,
    this.store,
    this.initialLevel = 0,
  });
  @override
  State<MergefrontScreen> createState() => _MergefrontScreenState();
}

class _MergefrontScreenState extends State<MergefrontScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final MergefrontStore store = widget.store ?? MergefrontStore();
  late final Ticker ticker;
  Profile? profile;
  MergefrontAudio? audio;
  Run? run;
  Duration last = Duration.zero;
  bool paused = false, saving = false, leave = false, options = false;
  String? error;
  String notice = 'Drag matching cards together to merge. Tap cards to equip.';
  int selected = 0, reward = 0, eventSerial = 0;
  int? pointer, mergeSource;
  UnitCard? mergedCard;
  double pointerX = 0, nextShotSound = 0;
  double? previewAt;
  int lastKills = 0;
  double lastShield = 0;
  bool get reduced =>
      widget.settings.reducedMotion.value ||
      MediaQuery.disableAnimationsOf(context);
  bool get locked => saving || error != null;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settings.reducedMotion.addListener(_refresh);
    widget.settings.soundOn.addListener(_refresh);
    widget.settings.hapticsOn.addListener(_refresh);
    ticker = createTicker(_tick)..start();
    _load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final loaded = await store.load();
      if (!mounted) return;
      setState(() {
        profile = loaded;
        selected = widget.initialLevel.clamp(0, loaded.unlocked);
        error = null;
      });
      audio = MergefrontAudio(widget.settings, loaded);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error = 'Could not read your squad. Retry to preserve your save.',
        );
      }
    }
  }

  Future<bool> _save() async {
    if (profile == null || saving) return false;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await store.save(profile!);
      if (!mounted) return false;
      setState(() => saving = false);
      return true;
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error =
              'Save failed. Your changes are here; retry before continuing.';
        });
      }
      return false;
    }
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - last).inMicroseconds / 1000000;
    last = elapsed;
    final r = run;
    if (r == null || paused || r.finished || locked) return;
    r.step(dt);
    if (r.approaching?.at != previewAt) {
      previewAt = r.approaching?.at;
      if (previewAt != null) unawaited(audio?.event('preview'));
    }
    if (r.eventSerial != eventSerial && !r.finished) {
      eventSerial = r.eventSerial;
      unawaited(audio?.event(r.eventKind));
    }
    if (r.time > nextShotSound && r.shots.any((s) => s.active)) {
      nextShotSound = r.time + .35;
      final role = r.shots.where((s) => s.active).first.role;
      unawaited(
        audio?.event(
          role == Role.heavy
              ? 'heavy'
              : role == Role.scatter
              ? 'scatter'
              : 'shot',
        ),
      );
    }
    if (r.kills > lastKills && !r.finished) unawaited(audio?.event('enemy'));
    if (r.shield > lastShield) unawaited(audio?.event('shield'));
    lastKills = r.kills;
    lastShield = r.shield;
    if (r.finished) {
      unawaited(audio?.finish(r.eventKind));
      reward = profile!.reward(r);
      unawaited(_save());
    }
    setState(() {});
  }

  void _start() {
    if (locked || profile == null) return;
    final p = profile!;
    setState(() {
      run = Run(
        Level.all[selected],
        p.loadout,
        damageBonus: p.damageBonus,
        healthBonus: p.healthBonus,
      );
      paused = false;
      options = false;
      pointer = null;
      eventSerial = 0;
      nextShotSound = 0;
      previewAt = null;
      lastKills = 0;
      lastShield = 0;
    });
    audio?.boss = false;
    unawaited(audio?.event('ui'));
    audio?.setActive(true);
  }

  void _pause(bool value) {
    setState(() {
      paused = value;
      pointer = null;
    });
    audio?.setActive(!value && run != null && !run!.finished);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    audio?.focused = state == AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed) {
      _pause(true);
    }
  }

  Future<void> _exit() async {
    _pause(true);
    if (saving) return;
    if (profile != null && !await _save()) return;
    if (!mounted) return;
    setState(() => leave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _merge(int a, int b) {
    if (locked) return;
    if (profile!.merge(a, b)) {
      setState(() {
        notice =
            'UPGRADED! A stronger ${profile!.cards.last.role.label} joins the squad.';
        mergeSource = null;
        mergedCard = profile!.cards.last;
      });
      unawaited(audio?.event('merge'));
      unawaited(_save());
    } else {
      setState(() => notice = 'Match the same role and rank. Maximum rank: 6.');
    }
  }

  @override
  void dispose() {
    ticker.dispose();
    audio?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.reducedMotion.removeListener(_refresh);
    widget.settings.soundOn.removeListener(_refresh);
    widget.settings.hapticsOn.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: leave,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _exit();
    },
    child: Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: ink,
          primary: ink,
          secondary: cyan,
          surface: cream,
        ),
      ),
      child: Scaffold(
        backgroundColor: cream,
        appBar: AppBar(
          backgroundColor: cream,
          title: const Text(
            'Squad Rusher',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 19,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Options',
              onPressed: () {
                _pause(true);
                setState(() => options = !options);
              },
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        body: SafeArea(
          child: profile == null
              ? Center(
                  child: error == null
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(error!),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Retry load'),
                            ),
                          ],
                        ),
                )
              : Column(
                  children: [
                    if (error != null)
                      Material(
                        color: gold,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(child: Text(error!)),
                              TextButton(
                                onPressed: () => _save(),
                                child: const Text('Retry save'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (saving) const LinearProgressIndicator(minHeight: 3),
                    Expanded(
                      child: options
                          ? _options()
                          : run == null
                          ? _loadout()
                          : run!.finished
                          ? _results()
                          : _battle(),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
  Widget _loadout() {
    final p = profile!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 185,
            child: MergefrontPreview(level: Level.all[selected]),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'SMALL SQUAD.\nBIG BREAKTHROUGHS.',
          style: TextStyle(
            color: ink,
            fontSize: 27,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${p.coins} coins  •  ${p.completed.length}/20 missions cleared',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'MISSION ${selected + 1}  /  ${Level.all[selected].name}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(Level.all[selected].style.label),
              const SizedBox(height: 4),
              Text(Level.all[selected].lesson),
              const SizedBox(height: 8),
              DropdownButton<int>(
                isExpanded: true,
                value: selected,
                items: [
                  for (var i = 0; i <= p.unlocked; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        '${i + 1}. ${Level.all[i].name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: locked
                    ? null
                    : (value) => setState(() => selected = value!),
              ),
              FilledButton.icon(
                key: const Key('mergefrontStart'),
                onPressed: locked ? null : _start,
                icon: const Icon(Icons.play_arrow),
                label: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Deploy squad • 2–3 min'),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Reward: ${Role.values[selected % 5].label} card • two on victory',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'YOUR SQUAD  ${p.equipped.length}/${p.slots}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
        ),
        Text(
          '${3 - p.completed.length % 3} new coast victories to the next slot${p.slots == 6 ? ' • maximum slots reached' : ''}.',
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: reduced ? Duration.zero : const Duration(milliseconds: 250),
          child: Text(
            notice,
            key: ValueKey(notice),
            style: const TextStyle(color: ink),
          ),
        ),
        if (mergedCard != null)
          MergeReveal(
            key: ValueKey(mergedCard!.id),
            card: mergedCard!,
            reduced: reduced,
          ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= 430 ? 4 : 3;
            final width = (c.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final card in p.cards)
                  SizedBox(width: width, child: _card(card)),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const Text(
          'WORKSHOP',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
        ),
        const Text(
          'Permanent starting boosts. Each upgrade adds a little less.',
        ),
        const SizedBox(height: 8),
        for (final damage in [true, false])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: locked || p.coins < p.upgradeCost(damage)
                  ? null
                  : () {
                      p.upgrade(damage);
                      _save();
                    },
              icon: Icon(damage ? Icons.bolt : Icons.favorite_border),
              label: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  '${damage ? 'Power' : 'Hull'} +${(((damage ? p.damageBonus : p.healthBonus) - 1) * 100).round()}% • ${p.upgradeCost(damage)} coins',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _card(UnitCard card) {
    final active = profile!.equipped.contains(card.id);
    final selectedForMerge = mergeSource == card.id;
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) =>
          !locked &&
          profile!.cards.any((c) => c.id == details.data && c.matches(card)),
      onAcceptWithDetails: (details) => _merge(details.data, card.id),
      builder: (context, candidates, rejected) => LongPressDraggable<int>(
        data: card.id,
        maxSimultaneousDrags: locked ? 0 : 1,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 86,
            height: 90,
            child: UnitPortrait(card.role, card.tier),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: .35,
          child: UnitPortrait(card.role, card.tier),
        ),
        child: Semantics(
          label:
              '${card.role.label} rank ${card.tier}, ${active ? 'equipped' : 'reserve'}',
          child: InkWell(
            key: ValueKey('unit-${card.id}'),
            onTap: locked
                ? null
                : () {
                    if (mergeSource != null && mergeSource != card.id) {
                      _merge(mergeSource!, card.id);
                      return;
                    }
                    if (!profile!.equip(card.id)) {
                      setState(
                        () => notice =
                            'Keep one unit equipped. Unequip a card to free a slot.',
                      );
                      return;
                    }
                    _save();
                  },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: candidates.isNotEmpty || selectedForMerge
                    ? gold
                    : active
                    ? const Color(0xFFD7F1E8)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active ? ink : const Color(0xFFE5D9BD),
                  width: active ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  UnitPortrait(card.role, card.tier),
                  Text(
                    card.role.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Rank ${card.tier}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Icon(
                    active ? Icons.check_circle : Icons.add_circle_outline,
                    size: 20,
                    color: ink,
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: locked
                        ? null
                        : () => setState(() {
                            mergeSource = selectedForMerge ? null : card.id;
                            notice =
                                'Tap an identical ${card.role.label} rank ${card.tier} to merge.';
                          }),
                    child: const Text('Merge', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _battle() {
    final r = run!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${r.squad.length} SQUAD • ${r.strength.ceil()} HP',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                key: const Key('mergefrontPause'),
                tooltip: paused ? 'Resume' : 'Pause',
                onPressed: () => _pause(!paused),
                icon: Icon(paused ? Icons.play_arrow : Icons.pause),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Semantics(
            label: 'Base health',
            value: '${r.baseHealth} of ${Run.maxBaseHealth}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'BASE ${r.baseHealth}/${Run.maxBaseHealth}${r.baseHealth <= 25 ? ' • CRITICAL' : ''}',
                  key: const Key('mergefrontBaseHealth'),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: r.baseHealth <= 25 ? const Color(0xFFAB3045) : ink,
                  ),
                ),
                const SizedBox(height: 3),
                LinearProgressIndicator(
                  key: const Key('mergefrontBaseBar'),
                  value: r.baseHealth / Run.maxBaseHealth,
                  minHeight: 10,
                  color: r.baseHealth <= 25 ? coral : cyan,
                  backgroundColor: const Color(0xFFE2D5B4),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(
            value: (r.time / r.level.bossAt).clamp(0, 1),
            color: cyan,
            backgroundColor: const Color(0xFFE2D5B4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            '${r.damage.toStringAsFixed(1)}× power • ${r.rate.toStringAsFixed(1)}× rate${r.spread ? ' • Spread' : ''}${r.pierce ? ' • Pierce' : ''}${r.armor ? ' • Armor' : ''}${r.shield > 0 ? ' • Shield ${r.shield.round()}' : ''}',
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        if (r.boss != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Column(
              children: [
                Text(
                  r.level.index.isEven ? 'BELLCRAB' : 'KITE ENGINE',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                LinearProgressIndicator(
                  value: r.boss!.hp / r.boss!.maxHp,
                  color: coral,
                ),
              ],
            ),
          ),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: .70,
              child: LayoutBuilder(
                builder: (context, constraints) => Listener(
                  key: const Key('mergefrontBattlefield'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    if (pointer != null ||
                        paused ||
                        event.localPosition.dy < constraints.maxHeight * .45) {
                      return;
                    }
                    pointer = event.pointer;
                    pointerX = event.localPosition.dx;
                  },
                  onPointerMove: (event) {
                    if (pointer != event.pointer || paused) return;
                    r.steer(
                      r.targetX +
                          (event.localPosition.dx - pointerX) /
                              constraints.maxWidth *
                              profile!.sensitivity,
                    );
                    pointerX = event.localPosition.dx;
                  },
                  onPointerUp: (event) {
                    if (pointer == event.pointer) pointer = null;
                  },
                  onPointerCancel: (event) {
                    if (pointer == event.pointer) pointer = null;
                  },
                  child: Semantics(
                    label:
                        'Battlefield. Drag left or right in the lower half to steer. ${r.squad.length} units. ${r.approaching == null ? '' : 'Left: ${r.approaching!.left.label}. Right: ${r.approaching!.right.label}.'}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(
                            painter: BattlefieldPainter(r, reduced: reduced),
                          ),
                          if (r.time < 6)
                            const Positioned(
                              left: 8,
                              right: 8,
                              bottom: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: cream,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    '←  DRAG HERE TO STEER  →',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (paused)
                            ColoredBox(
                              color: ink.withValues(alpha: .78),
                              child: Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'TAKE A BREATHER',
                                        style: TextStyle(
                                          color: cream,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton(
                                        onPressed: () => _pause(false),
                                        child: const Text('Resume'),
                                      ),
                                      TextButton(
                                        key: const Key('mergefrontRestart'),
                                        onPressed: locked ? null : _start,
                                        child: const Text(
                                          'Restart this seed',
                                          style: TextStyle(color: cream),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() => run = null);
                                        },
                                        child: const Text(
                                          'Return to loadout',
                                          style: TextStyle(color: cream),
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
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Semantics(
            liveRegion: true,
            child: Text(
              r.damageNoticeRemaining > 0
                  ? r.damageNotice
                  : r.approaching == null
                  ? (r.time < 6
                        ? 'Stop enemies in every lane. Escapes damage your base.'
                        : r.event)
                  : r.x > .48 && r.x < .52
                  ? '← CHOOSE A GATE →'
                  : '${r.x < .5 ? '←' : '→'} ${(r.x < .5 ? r.approaching!.left : r.approaching!.right).preview(r)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
            ),
          ),
        ),
      ],
    );
  }

  Widget _results() {
    final r = run!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(
          r.won ? Icons.wb_sunny_rounded : Icons.shield_outlined,
          size: 76,
          color: r.won ? gold : cyan,
        ),
        const SizedBox(height: 16),
        Text(
          r.won ? 'COAST CLEAR!' : 'REGROUP.\nCOME BACK STRONGER.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${r.level.name}\n${r.kills} targets • ${r.gateCount} gates • ${r.time.floor()} seconds\nBase ${r.baseHealth}/${Run.maxBaseHealth} • ${r.escaped} escaped${!r.won && r.defeatReason.isNotEmpty ? '\n${r.defeatReason}' : ''}',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _panel(
          Column(
            children: [
              Text(
                '+$reward COINS',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              UnitPortrait(Role.values[selected % 5], 1),
              Text(
                '+${r.won ? 2 : 1} ${Role.values[selected % 5].label} cards',
              ),
              const Text('Merge matching cards for an instant upgrade.'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('mergefrontLoadout'),
          onPressed: locked
              ? null
              : () => setState(() {
                  run = null;
                  selected = profile!.unlocked;
                  notice =
                      'Fresh cards are ready. Merge, equip, and head back out.';
                }),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Text('Collect & improve squad'),
          ),
        ),
        TextButton(
          onPressed: locked ? null : _start,
          child: const Text('Replay this coast'),
        ),
        if (saving)
          const Text('Saving your rewards…', textAlign: TextAlign.center),
      ],
    );
  }

  Widget _options() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'FIELD SETTINGS',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
      ),
      SwitchListTile(
        title: const Text('Master sound'),
        value: widget.settings.soundOn.value,
        onChanged: (v) => _setting(() => widget.settings.setSound(v)),
      ),
      SwitchListTile(
        title: const Text('Music'),
        value: profile!.music,
        onChanged: locked
            ? null
            : (v) {
                profile!.music = v;
                audio?.sync();
                _save();
              },
      ),
      SwitchListTile(
        title: const Text('Effects'),
        value: profile!.effects,
        onChanged: locked
            ? null
            : (v) {
                profile!.effects = v;
                _save();
              },
      ),
      SwitchListTile(
        title: const Text('Haptics'),
        value: widget.settings.hapticsOn.value,
        onChanged: (v) => _setting(() => widget.settings.setHaptics(v)),
      ),
      SwitchListTile(
        title: const Text('Reduced motion'),
        subtitle: const Text('No idle bounce, scrolling texture or particles.'),
        value: widget.settings.reducedMotion.value,
        onChanged: (v) => _setting(() => widget.settings.setReducedMotion(v)),
      ),
      const Text('Steering sensitivity'),
      Slider(
        value: profile!.sensitivity,
        min: .6,
        max: 1.6,
        divisions: 5,
        label: profile!.sensitivity.toStringAsFixed(1),
        onChanged: locked
            ? null
            : (v) => setState(() => profile!.sensitivity = v),
        onChangeEnd: (_) => _save(),
      ),
      const Text(
        'Defend the base',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Intercept enemies in every lane. Escaped swarms deal 2 base damage, regular enemies 5, and heavies 12. At zero base health you lose. Squad shields and healing do not repair the base. Crates and stationary obstacles can safely pass.',
        ),
      ),
      const Text('Role guide', style: TextStyle(fontWeight: FontWeight.w900)),
      for (final role in Role.values)
        ListTile(
          leading: SizedBox(width: 48, child: UnitPortrait(role, 1)),
          title: Text(role.label),
          subtitle: Text(role.description),
        ),
      FilledButton(
        onPressed: () => setState(() => options = false),
        child: const Text('Back'),
      ),
    ],
  );
  Future<void> _setting(Future<void> Function() change) async {
    try {
      await change();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save this setting. Toggle again to retry.',
            ),
          ),
        );
      }
    }
  }

  Widget _panel(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE6DABB)),
    ),
    child: child,
  );
}
