import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import '../../shell/game_play_layout.dart';
import '../../shell/settings.dart';
import '../../shell/settings_screen.dart';
import 'arcade_home.dart';
import 'cozy_art.dart';

const tableCream = Color(0xFFFFF7E7);

class TableDefinition implements GameDefinition {
  @override
  final String id, title, iconName;
  const TableDefinition(this.id, this.title, this.iconName);
  @override
  int get levelCount => 30;
}

class TableHome extends StatefulWidget {
  final TableDefinition definition;
  final String subtitle, rules, footer;
  final Color accent;
  final Widget preview;
  final ProgressStore store;
  final AppSettings settings;
  final Widget Function(int) play;
  final String summary;
  final String Function(int)? dealDescription;
  const TableHome({
    super.key,
    required this.definition,
    required this.subtitle,
    required this.rules,
    required this.footer,
    required this.accent,
    required this.preview,
    required this.store,
    required this.settings,
    required this.play,
    this.summary = '30 replayable deals · no timer, your pace',
    this.dealDescription,
  });
  @override
  State<TableHome> createState() => _TableHomeState();
}

class _TableHomeState extends State<TableHome> {
  late Future<GameProgress> progress = widget.store.load(widget.definition.id);
  void reload() {
    if (mounted) {
      setState(() {
        progress = widget.store.load(widget.definition.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<GameProgress>(
    future: progress,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.definition.title)),
          body: Center(
            child: snapshot.hasError
                ? TextButton(
                    onPressed: reload,
                    child: const Text('Retry loading your collection'),
                  )
                : const CircularProgressIndicator(),
          ),
        );
      }
      var p = snapshot.data!;
      final next = List.generate(
        30,
        (i) => i,
      ).firstWhere((i) => p.results[i]?.completed != true, orElse: () => 0);
      Widget guide(BuildContext context) => Scaffold(
        backgroundColor: tableCream,
        appBar: AppBar(title: const Text('How to play')),
        body: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            SizedBox(height: 180, child: widget.preview),
            const SizedBox(height: 24),
            Text(
              widget.rules,
              style: const TextStyle(fontSize: 18, height: 1.6),
            ),
          ],
        ),
      );
      return ArcadeHome(
        title: widget.definition.title,
        subtitle: widget.subtitle,
        action: 'Play deal ${next + 1}',
        summary: widget.summary,
        progressTitle: 'Your little collection',
        progressDetail: '${p.completedCount} of 30 deals completed',
        progress: p.completedCount / 30,
        progressArt: Icon(Icons.auto_awesome, color: widget.accent, size: 32),
        firstLabel: 'Choose a deal',
        secondLabel: 'How to play',
        firstIcon: Icons.grid_view_rounded,
        secondIcon: Icons.menu_book_rounded,
        footer: widget.footer,
        accent: widget.accent,
        background: tableCream,
        preview: widget.preview,
        settings: widget.settings,
        onReturn: reload,
        play: (_) => widget.play(next),
        secondDestination: guide,
        firstDestination: (_) => StatefulBuilder(
          builder: (context, refresh) => Scaffold(
            backgroundColor: tableCream,
            appBar: AppBar(title: const Text('Choose a deal')),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (var i = 0; i < 30; i++)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: widget.accent,
                        foregroundColor: Colors.white,
                        child: Text('${i + 1}'),
                      ),
                      title: Text('Deal ${i + 1}'),
                      subtitle: Text(
                        [
                          if (widget.dealDescription != null)
                            widget.dealDescription!(i),
                          if (p.results[i]?.completed == true)
                            'Completed · best ${p.results[i]!.bestMoves} moves'
                          else if (widget.dealDescription == null)
                            'A fresh little challenge',
                        ].join('\n'),
                      ),
                      trailing: Icon(
                        p.results[i]?.completed == true
                            ? Icons.check_circle_outline
                            : Icons.play_arrow_rounded,
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => widget.play(i),
                          ),
                        );
                        if (!context.mounted) return;
                        try {
                          final updated = await widget.store.load(
                            widget.definition.id,
                          );
                          if (context.mounted) refresh(() => p = updated);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not refresh results. Reopen the deal list to retry.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Full-viewport play and the same in-place menu used by the other games.
class TablePlay extends StatefulWidget {
  final String id, title, rules, status;
  final int deal, moves;
  final bool won, canUndo;
  final bool completionReady, canHint;
  final ValueChanged<bool>? onMenuChanged;
  final bool numberedDeals;
  final Color accent;
  final AppSettings settings;
  final ProgressStore store;
  final VoidCallback undo, hint, restart, next;
  final Widget child;
  final Widget Function(Widget child)? backgroundBuilder;
  const TablePlay({
    super.key,
    required this.id,
    required this.title,
    required this.rules,
    required this.status,
    required this.deal,
    required this.moves,
    required this.won,
    required this.canUndo,
    required this.accent,
    required this.settings,
    required this.store,
    required this.undo,
    required this.hint,
    required this.restart,
    required this.next,
    required this.child,
    this.backgroundBuilder,
    this.completionReady = true,
    this.canHint = true,
    this.onMenuChanged,
    this.numberedDeals = true,
  });
  @override
  State<TablePlay> createState() => _TablePlayState();
}

class _TablePlayState extends State<TablePlay> {
  final layout = GlobalKey<GamePlayLayoutState>();
  bool saving = false, saved = false;
  String? error;
  @override
  void initState() {
    super.initState();
    widget.settings.recordPlay(widget.id);
  }

  @override
  void didUpdateWidget(covariant TablePlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.numberedDeals && widget.won && !oldWidget.won) {
      _save();
    }
    if (!widget.won) {
      saved = false;
      error = null;
    }
  }

  Future<void> _save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final p = await widget.store.load(widget.id);
      await widget.store.save(
        widget.id,
        p.withCompleted(widget.deal, widget.moves),
      );
      if (mounted) setState(() => saved = true);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Your win could not be saved. Please retry.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void action(VoidCallback callback) {
    layout.currentState?.closeMenu();
    callback();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: widget.accent,
        primary: widget.accent,
        surface: tableCream,
      ),
    ),
    child: Scaffold(
      backgroundColor: widget.accent,
      body: SafeArea(
        child: GamePlayLayout(
          key: layout,
          title: widget.title,
          status: widget.numberedDeals
              ? 'Deal ${widget.deal + 1} · ${widget.status}'
              : widget.status,
          completed: widget.won,
          onMenuChanged: widget.onMenuChanged,
          color: tableCream,
          foregroundColor: widget.accent,
          actions: [
            IconButton(
              tooltip: 'Undo',
              onPressed: widget.canUndo && !widget.won ? widget.undo : null,
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton(
              tooltip: 'Hint',
              onPressed: widget.won || !widget.canHint ? null : widget.hint,
              icon: const Icon(Icons.lightbulb_outline_rounded),
            ),
          ],
          menu: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.numberedDeals
                    ? '${widget.moves} moves · Deal ${widget.deal + 1}'
                    : '${widget.moves} moves',
              ),
              const SizedBox(height: 12),
              Text(widget.rules),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    saving || (widget.numberedDeals && widget.won && !saved)
                    ? null
                    : () => action(widget.restart),
                icon: const Icon(Icons.refresh),
                label: Text(
                  widget.numberedDeals ? 'Restart this deal' : 'New deal',
                ),
              ),
              if (widget.numberedDeals)
                OutlinedButton.icon(
                  onPressed:
                      saving || (widget.numberedDeals && widget.won && !saved)
                      ? null
                      : () => action(widget.next),
                  icon: const Icon(Icons.style),
                  label: const Text('Next deal'),
                ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsScreen(settings: widget.settings),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Settings'),
              ),
            ],
          ),
          child:
              (widget.backgroundBuilder ??
              (child) =>
                  CozyBackdrop(garden: widget.id == 'mahjong', child: child))(
                widget.won && widget.completionReady
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(28),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CozyFriend(
                                    garden: widget.id == 'mahjong',
                                    bunny: widget.id != 'mahjong',
                                    size: 88,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    widget.id == 'mahjong'
                                        ? 'Garden aglow!'
                                        : 'Written in the stars!',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.numberedDeals
                                        ? 'Deal ${widget.deal + 1} complete in ${widget.moves} moves.'
                                        : 'Completed in ${widget.moves} moves.',
                                    textAlign: TextAlign.center,
                                  ),
                                  if (saving)
                                    const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(),
                                    ),
                                  if (error != null) ...[
                                    Text(error!, textAlign: TextAlign.center),
                                    TextButton(
                                      onPressed: saving ? null : _save,
                                      child: const Text('Retry save'),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: !widget.numberedDeals || saved
                                        ? widget.next
                                        : null,
                                    child: Text(
                                      widget.numberedDeals
                                          ? 'Next deal'
                                          : 'New deal',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : widget.child,
              ),
        ),
      ),
    ),
  );
}

class TableMessage extends StatelessWidget {
  final String title, detail;
  final IconData icon;
  const TableMessage({
    super.key,
    required this.title,
    required this.detail,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CozyFriend(garden: icon == Icons.local_florist_outlined, size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: cozyInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  color: cozyInk,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Give the board the space left after its actual (text-scaled) chrome.
/// Only the board scrolls when a small viewport or a long stack needs it.
class TableBoardLayout extends StatelessWidget {
  final Widget header, footer;
  final Widget Function(BuildContext, BoxConstraints) boardBuilder;
  const TableBoardLayout({
    super.key,
    required this.header,
    required this.footer,
    required this.boardBuilder,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      header,
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: LayoutBuilder(
            builder: (context, bounds) =>
                SingleChildScrollView(child: boardBuilder(context, bounds)),
          ),
        ),
      ),
      footer,
    ],
  );
}
