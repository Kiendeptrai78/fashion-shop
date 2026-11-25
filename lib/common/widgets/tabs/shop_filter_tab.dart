import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/localization/shop_locale.dart';
import '../product/badges/shop_count_badge.dart';

class ShopFilterTab extends StatelessWidget {
  const ShopFilterTab({super.key, required this.label, required this.count,
    required this.selected, required this.onTap});
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(selected: selected, button: true,
    child: Material(color: Colors.transparent, child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF2ED) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFFD0E1D7) : Colors.transparent)),
        child: ShopCountBadge(count: count, inline: true, child: ShopText(label,
          style: TextStyle(fontSize: 14, height: 1.3,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? TColors.primaryColor : const Color(0xFF475569)))),
      ),
    )),
  );
}
