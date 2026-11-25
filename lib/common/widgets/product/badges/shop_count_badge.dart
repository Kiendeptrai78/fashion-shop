import 'package:flutter/material.dart';

class ShopCountBadge extends StatelessWidget {
  const ShopCountBadge({super.key, required this.count, required this.child, this.inline = false});
  final int count;
  final Widget child;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final badge = Badge(
    isLabelVisible: count > 0,
    backgroundColor: const Color(0xFFD92D3E), textColor: Colors.white,
    label: Text(count > 99 ? '99+' : '$count', style: const TextStyle(
        fontSize: 10, height: 1.1, fontWeight: FontWeight.w700)),
      child: inline ? null : child,
    );
    if (!inline) return badge;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      child,
      if (count > 0) ...[const SizedBox(width: 7), badge],
    ]);
  }
}
