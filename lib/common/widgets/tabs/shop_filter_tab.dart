import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../utils/localization/shop_translations.dart';
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
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: ShopCountBadge(count: count, inline: true, child: ShopText(label,
          style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 13, height: 1.3,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? (selected ? Colors.white : Colors.white70)
                : (selected ? const Color(0xFF173E32) : const Color(0xFF38453D))))),
      ),
  ));
}

/// Native package scrollable control: swipe the strip, tap to select.
class ShopFilterTabs extends StatelessWidget {
  const ShopFilterTabs({super.key, required this.tabs});
  final List<ShopFilterTab> tabs;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return const SizedBox(height: 42);
    final selected = tabs.indexWhere((tab) => tab.selected);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final language = Localizations.localeOf(context).languageCode;
    return ClipRRect(
      borderRadius: BorderRadius.circular(21),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: GlassSegmentedControl.scrollable(
          segments: [for (var index = 0; index < tabs.length; index++) GlassSegment(
            id: index,
            icon: tabs[index],
            semanticLabel: shopTranslate(tabs[index].label, language: language),
          )],
          selectedIndex: selected < 0 ? 0 : selected,
          onSegmentSelected: (index) => tabs[index].onTap(),
          dragBehavior: SegmentDragBehavior.scroll,
          selectionAlignment: SegmentSelectionAlignment.center,
          height: 42,
          backgroundColor: Colors.transparent,
          indicatorColor: dark ? const Color(0x30FFFFFF) : const Color(0x0F000000),
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          indicatorExpansion: EdgeInsets.zero,
          useOwnLayer: true,
          // Keep live blur on the fixed track, never on the moving indicator.
          quality: GlassQuality.minimal,
          indicatorSettings: LiquidGlassSettings.classicIndicator,
          settings: LiquidGlassSettings(
            glassColor: dark ? const Color(0x30FFFFFF) : const Color(0x38FFFFFF),
            blur: 0, thickness: 12, frost: 0,
          ),
        ),
      ),
    );
  }
}
