import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class GridCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double height;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;

  const GridCard({
    super.key,
    required this.child,
    this.onTap,
    this.height = 90,
    this.padding = const EdgeInsets.all(14),
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  State<GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<GridCard> {
  bool _hover = false;
  bool _pressed = false;

  void _setHover(bool v) {
    if (_hover == v) return;
    setState(() => _hover = v);
  }

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = Theme.of(context).cardsColor;
    final borderColor = Theme.of( context).borderColor;

    // base shadow and hover shadow (kept subtle)
    final baseShadow = BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 6,
      offset: const Offset(0, 3),
    );

    final hoverShadow = BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 8,
      offset: const Offset(0, 6),
    );

    final effectiveShadow = _hover || _pressed ? hoverShadow : baseShadow;
    final scale = _pressed ? 0.995 : (_hover ? 1.02 : 1.0);

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) {
          _setPressed(false);
          if (widget.onTap != null) widget.onTap!();
        },
        onTapCancel: () => _setPressed(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(scale),
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            border: Border.all(color: borderColor),
            boxShadow: [effectiveShadow],
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
