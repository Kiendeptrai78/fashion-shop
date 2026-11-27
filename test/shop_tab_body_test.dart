import 'package:fashion_business_app/common/widgets/tabs/shop_tab_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tab content slides in both directions and removes the old page', (tester) async {
    var index = 0;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (context, setState) {
        update = setState;
        return SizedBox(width: 300, height: 400, child: ShopTabBody(
          index: index,
          child: Center(child: Text('Page $index')),
        ));
      },
    ))));
    update(() => index = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getCenter(find.text('Page 1')).dx, greaterThan(150));
    expect(tester.getCenter(find.text('Page 0')).dx, lessThan(150));
    await tester.pumpAndSettle();
    expect(find.text('Page 0'), findsNothing);
    expect(tester.getCenter(find.text('Page 1')).dx, 150);
    update(() => index = 0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getCenter(find.text('Page 0')).dx, lessThan(150));
    expect(tester.getCenter(find.text('Page 1')).dx, greaterThan(150));
    await tester.pumpAndSettle();
    expect(find.text('Page 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
