import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scroll content passes behind the toolbar while back stays tappable', (tester) async {
    var backs = 0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.padding = const FakeViewPadding(top: 62);
    tester.view.viewPadding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TAppbar(showBackArrow: true, leadingOnPressed: () => backs++,
        title: const Text('Glass toolbar')),
      body: Builder(builder: (bodyContext) => ListView(
        padding: shopAppbarContentPadding(bodyContext), children: [
        for (var i = 0; i < 30; i++) SizedBox(key: ValueKey('row-$i'), height: 60,
          child: Text('Row $i')),
      ])),
    ))));
    await tester.pumpAndSettle();
    final barBottom = tester.getBottomLeft(find.byType(TAppbar)).dy;
    expect(tester.getTopLeft(find.byKey(const ValueKey('row-0'))).dy, barBottom);
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('row-1'))).dy, lessThan(barBottom));
    await tester.tap(find.byTooltip('Back'));
    expect(backs, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('title stays outside glass controls and toolbar actions remain tappable', (tester) async {
    var backs = 0, actions = 0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      appBar: TAppbar(
        title: const Text('Đơn hàng của tôi'),
        showBackArrow: true,
        leadingOnPressed: () => backs++,
        actions: [IconButton(tooltip: 'Notifications',
          onPressed: () => actions++, icon: const Icon(Icons.notifications_none))],
      ),
      body: const SizedBox.expand(),
    )));
    expect(find.ancestor(of: find.text('Đơn hàng của tôi'),
      matching: find.byType(GlassIconButton)), findsNothing);
    expect(find.byType(ShopGlassBackButton), findsOneWidget);
    expect(find.byType(GlassAppBar), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.back), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(CupertinoIcons.back)).size, 26);
    expect(tester.widget<GlassAppBar>(find.byType(GlassAppBar)).surfaceStyle,
      GlassAppBarSurfaceStyle.fullBlur);
    expect(tester.widget<GlassAppBar>(find.byType(GlassAppBar)).groupBackdrop, isFalse);
    expect(DefaultTextStyle.of(tester.element(find.text('Đơn hàng của tôi'))).style.fontSize, 18);
    expect(find.descendant(of: find.byTooltip('Notifications'),
      matching: find.byType(GlassIconButton)), findsOneWidget);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.tap(find.byTooltip('Back'));
    expect(actions, 1);
    expect(backs, 1);
    expect(tester.takeException(), isNull);
  });
}
