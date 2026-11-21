import 'package:flutter/material.dart';

class ShopCountBadge extends StatelessWidget {
  const ShopCountBadge({super.key, required this.count, required this.child});
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) => Badge(
    isLabelVisible: count > 0,
    backgroundColor: const Color(0xFFD92D3E), textColor: Colors.white,
    label: Text(count > 99 ? '99+' : '$count', style: const TextStyle(
        fontSize: 10, height: 1.1, fontWeight: FontWeight.w700)),
    child: child,
  );
}
