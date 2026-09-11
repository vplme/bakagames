import 'package:flutter/material.dart';

/// Shared gameplay action shape; each game supplies its own colors and actions.
class PlayControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  const PlayControlButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.filledTonal(
        tooltip: label,
        iconSize: 28,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor?.withValues(alpha: .3),
          disabledForegroundColor: foregroundColor?.withValues(alpha: .3),
        ),
        icon: Icon(icon),
      ),
      GestureDetector(
        onTap: onPressed,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: onPressed == null
                ? (foregroundColor ?? Theme.of(context).colorScheme.onSurface)
                      .withValues(alpha: .38)
                : foregroundColor,
          ),
        ),
      ),
    ],
  );
}
