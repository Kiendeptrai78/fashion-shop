import 'package:fashion_business_app/common/widgets/tabs/shop_filter_tab.dart';
import 'package:flutter/material.dart';

class TTabBar extends StatelessWidget implements PreferredSizeWidget {
  const TTabBar({
    super.key,
    required this.tabs,
  });

  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: AnimatedBuilder(animation: controller, builder: (_, __) => ShopFilterTabs(
        tabs: List.generate(tabs.length, (index) => ShopFilterTab(
          label: tabs[index], count: 0, selected: controller.index == index,
          onTap: () => controller.animateTo(index),
        )),
      )),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(54);
}
