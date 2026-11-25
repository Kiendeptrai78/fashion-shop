import 'package:flutter/material.dart';
import '../../../../utils/constants/colors.dart';

enum ShopStatusTone { pending, progress, success, error, neutral }

class ShopStatusBadge extends StatelessWidget {
  const ShopStatusBadge({super.key, required this.label, this.tone = ShopStatusTone.neutral});
  final String label;
  final ShopStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (tone) {
      ShopStatusTone.pending => (const Color(0xFF8A5108), const Color(0xFFFFF4DF)),
      ShopStatusTone.progress => (TColors.primaryColor, const Color(0xFFEAF2ED)),
      ShopStatusTone.success => (const Color(0xFF21613D), const Color(0xFFEAF5ED)),
      ShopStatusTone.error => (const Color(0xFFAB3434), const Color(0xFFFCEEEE)),
      ShopStatusTone.neutral => (const Color(0xFF475569), const Color(0xFFF1F5F9)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
          decoration: BoxDecoration(color: foreground, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: TextStyle(color: foreground,
          fontSize: 12, height: 1.3, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
