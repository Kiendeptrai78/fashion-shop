import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_business_app/common/widgets/product/badges/shop_count_badge.dart';

void main() {
  testWidgets('red count badge hides zero and caps large counts', (tester) async {
    for (final count in [0, 3, 105]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ShopCountBadge(
        count: count, child: const Icon(Icons.shopping_bag_outlined)))));
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, count > 0);
      expect(badge.backgroundColor, const Color(0xFFD92D3E));
      expect(badge.textColor, Colors.white);
      if (count > 0) expect(find.text(count > 99 ? '99+' : '$count'), findsOneWidget);
    }
  });
}
