import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/navigation_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('switching to Chat releases focus and keeps the outer body size stable', (tester) async {
    final homeFocus = FocusNode();
    final controller = Get.put(NavigationController());
    controller.screens[0] = Scaffold(body: TextField(focusNode: homeFocus));
    controller.screens[2] = const Scaffold(body: TextField());
    controller.screens[1] = const Scaffold(body: Center(child: Text('Video')));
    await tester.pumpWidget(LiquidGlassWidgets.wrap(
      brightnessResolver: ShopGlass.resolveBrightness,
      theme: ShopGlass.themeData,
      child: const MaterialApp(home: ShopGlassBackground(child: NavigationMenu())),
    ));
    await tester.pumpAndSettle();
    Finder body(int index) => find.byWidgetPredicate(
      (widget) => widget is RepaintBoundary && widget.key == ValueKey(index));
    final homeSize = tester.getSize(body(0));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(homeFocus.hasFocus, isTrue);

    await tester.tap(find.text('Chat').hitTestable().first);
    await tester.pumpAndSettle();
    expect(controller.selectedIndex.value, 2);
    expect(homeFocus.hasFocus, isFalse);
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isFalse);
    expect(tester.getSize(body(2)), homeSize);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Featured').hitTestable().first);
    await tester.pumpAndSettle();
    expect(controller.selectedIndex.value, 1);
    expect(find.byIcon(CupertinoIcons.play_circle_fill).hitTestable(), findsWidgets);
    expect(tester.getSize(find.byIcon(CupertinoIcons.play_circle_fill).first).shortestSide,
      greaterThanOrEqualTo(20));

    await tester.pumpWidget(const SizedBox.shrink());
    homeFocus.dispose();
    Get.reset();
  });
}
