import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/tabs/shop_filter_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
  testWidgets('tabs bounce at both edges and preserve selection on ${platform.name}', (tester) async {
    var selected = 0;
    const labels = ['For you', 'Running', 'Lifestyle', 'Training', 'Basketball', 'Trail'];
    await tester.pumpWidget(LiquidGlassWidgets.wrap(
      brightnessResolver: ShopGlass.resolveBrightness,
      child: MaterialApp(theme: ThemeData(platform: platform), home: ShopGlassBackground(child: Scaffold(
        body: Center(child: SizedBox(width: 300, child: StatefulBuilder(
          builder: (context, setState) => ShopFilterTabs(tabs: [
            for (var index = 0; index < labels.length; index++) ShopFilterTab(
              label: labels[index], count: index == 5 ? 3 : 0,
              selected: selected == index,
              onTap: () => setState(() => selected = index),
            ),
          ]),
        ))),
      ))),
    ));
    await tester.pumpAndSettle();
    final fixedBlur = tester.element(find.descendant(of: find.byType(ShopFilterTabs),
      matching: find.byType(BackdropFilter)));
    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    final position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    final startDrag = await tester.startGesture(tester.getCenter(find.byType(GlassSegmentedControl)));
    await startDrag.moveBy(const Offset(24, 0));
    await tester.pump();
    await startDrag.moveBy(const Offset(90, 0));
    await tester.pump(const Duration(milliseconds: 16));
    expect(position.pixels, lessThan(position.minScrollExtent));
    expect(selected, 0);
    await startDrag.up();
    await tester.pumpAndSettle();
    expect(position.pixels, closeTo(position.minScrollExtent, 0.1));
    await tester.drag(find.byType(GlassSegmentedControl), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(selected, 0);
    expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels, greaterThan(0));
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    final endDrag = await tester.startGesture(tester.getCenter(find.byType(GlassSegmentedControl)));
    await endDrag.moveBy(const Offset(-24, 0));
    await tester.pump();
    await endDrag.moveBy(const Offset(-90, 0));
    await tester.pump(const Duration(milliseconds: 16));
    expect(position.pixels, greaterThan(position.maxScrollExtent));
    expect(selected, 0);
    await endDrag.up();
    await tester.pumpAndSettle();
    expect(position.pixels, closeTo(position.maxScrollExtent, 0.1));
    await tester.tap(find.text('Trail').hitTestable().first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final filters = find.descendant(of: find.byType(ShopFilterTabs), matching: find.byType(BackdropFilter));
    expect(filters, findsOneWidget);
    expect(tester.element(filters), same(fixedBlur));
    await tester.pumpAndSettle();
    expect(selected, 5);
    expect(find.text('3'), findsWidgets);
    await tester.ensureVisible(find.text('Training'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Training').hitTestable().first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(selected, 3);
    expect(tester.getCenter(find.text('Training')).dx,
        closeTo(tester.getCenter(find.byType(GlassSegmentedControl)).dx, 2));
    expect(tester.takeException(), isNull);
  });
  }
}
