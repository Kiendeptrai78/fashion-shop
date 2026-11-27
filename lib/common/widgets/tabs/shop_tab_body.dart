import 'package:flutter/material.dart';
import '../glass/shop_glass.dart';

/// Slides keyed tab content inside an opaque, clipped viewport.
class ShopTabBody extends StatefulWidget {
  static const transitionDuration = Duration(milliseconds: 260);
  const ShopTabBody({super.key, required this.index, required this.child, this.backgroundColor});
  final int index;
  final Widget child;
  final Color? backgroundColor;

  @override
  State<ShopTabBody> createState() => _ShopTabBodyState();
}

class _ShopTabBodyState extends State<ShopTabBody> {
  bool _forward = true;

  @override
  void didUpdateWidget(covariant ShopTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) _forward = widget.index > oldWidget.index;
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero : ShopTabBody.transitionDuration,
      layoutBuilder: (current, previous) => Stack(fit: StackFit.passthrough,
        children: [...previous, if (current != null) current]),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(widget.index);
        final direction = _forward ? 1.0 : -1.0;
        return IgnorePointer(
          ignoring: !incoming,
          child: ExcludeSemantics(
            excluding: !incoming,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(incoming ? direction : -direction, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        );
      },
      child: ColoredBox(
        key: ValueKey(widget.index),
        color: widget.backgroundColor ??
            (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0D1913) : ShopGlass.pageBackground),
        child: widget.child,
      ),
    ),
  );
}
