import 'package:flutter/material.dart';

/// Consistent, compact game chrome with an accessible in-place menu.
class GamePlayLayout extends StatefulWidget {
  const GamePlayLayout({
    super.key,
    required this.title,
    required this.status,
    required this.child,
    required this.menu,
    this.onMenuOpened,
    this.overlay,
    this.actions = const [],
    this.completed = false,
    this.paused,
    this.pauseKey,
    this.onTogglePause,
    this.onBack,
    this.color,
    this.foregroundColor,
  });

  final List<Widget> actions;
  final bool completed;
  final bool? paused;
  final Key? pauseKey;
  final VoidCallback? onTogglePause;
  final String title, status;
  final Widget child, menu;

  /// Live information painted over play; pointer input passes through to the game.
  final Widget? overlay;
  final VoidCallback? onMenuOpened, onBack;
  final Color? color, foregroundColor;

  @override
  State<GamePlayLayout> createState() => GamePlayLayoutState();
}

class GamePlayLayoutState extends State<GamePlayLayout> {
  bool _open = false;

  /// Used by games which own route exit/save handling.
  bool closeMenu() {
    if (!_open) return false;
    setState(() => _open = false);
    return true;
  }

  @override
  void didUpdateWidget(covariant GamePlayLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completed && !oldWidget.completed) _open = false;
  }

  void _toggle() {
    if (!_open) widget.onMenuOpened?.call();
    setState(() => _open = !_open);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Material(
          color: widget.color ?? Theme.of(context).colorScheme.surface,
          child: IconTheme(
            data: IconThemeData(color: widget.foregroundColor),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () {
                    if (_open) {
                      setState(() => _open = false);
                    } else {
                      (widget.onBack ?? () => Navigator.maybePop(context))();
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Text(
                    widget.status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!_open) ...widget.actions,
                if (widget.onTogglePause != null)
                  IconButton(
                    key: widget.pauseKey,
                    tooltip: widget.paused == true ? 'Resume' : 'Pause',
                    onPressed: () {
                      setState(() => _open = false);
                      widget.onTogglePause!();
                    },
                    icon: Icon(
                      widget.paused == true ? Icons.play_arrow : Icons.pause,
                    ),
                  ),
                IconButton(
                  key: const Key('gameMenu'),
                  tooltip: _open ? 'Close menu' : 'Game menu',
                  onPressed: _toggle,
                  icon: Icon(_open ? Icons.close : Icons.menu_rounded),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeFocus(
                excluding: _open,
                child: ExcludeSemantics(
                  excluding: _open,
                  child: IgnorePointer(ignoring: _open, child: widget.child),
                ),
              ),
              if (!_open && !widget.completed && widget.overlay != null)
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: IgnorePointer(
                      child: Material(
                        key: const Key('gameOverlay'),
                        color:
                            (widget.color ??
                                    Theme.of(context).colorScheme.surface)
                                .withValues(alpha: .94),
                        elevation: 3,
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: DefaultTextStyle.merge(
                            style: TextStyle(
                              color: widget.foregroundColor,
                              fontWeight: FontWeight.w600,
                            ),
                            child: IconTheme.merge(
                              data: IconThemeData(
                                color: widget.foregroundColor,
                              ),
                              child: widget.overlay!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_open) ...[
                ModalBarrier(
                  color: Colors.black26,
                  onDismiss: closeMenu,
                  semanticsLabel: 'Close menu',
                ),
                LayoutBuilder(
                  builder: (context, constraints) => Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 400,
                          maxHeight: constraints.maxHeight * .8,
                        ),
                        child: Material(
                          key: const Key('gameMenuPanel'),
                          elevation: 8,
                          borderRadius: BorderRadius.circular(24),
                          clipBehavior: Clip.antiAlias,
                          color:
                              widget.color ??
                              Theme.of(context).colorScheme.surface,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  widget.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                widget.menu,
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: _toggle,
                                  icon: const Icon(Icons.close),
                                  label: const Text('Close menu'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
    if (widget.onBack != null) return content;
    return PopScope(
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) closeMenu();
      },
      child: content,
    );
  }
}
