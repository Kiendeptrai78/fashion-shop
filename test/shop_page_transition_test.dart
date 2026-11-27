import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_page_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('pushed transparent page owns a glass background inside its route', (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      customTransition: ShopPageTransition(),
      builder: (context, child) => ShopGlassBackground(child: child!),
      home: const Scaffold(body: Text('Previous screen')),
    ));
    await tester.pumpAndSettle();

    Get.to<void>(() => const Scaffold(
      backgroundColor: Colors.transparent,
      body: Text('Next screen'),
    ), popGesture: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final page = tester.element(find.text('Next screen'));
    final background = page.findAncestorWidgetOfExactType<ShopGlassBackground>();
    expect(background, isNotNull);
    final scope = tester.element(find.byWidget(background!));
    expect(ModalRoute.of(scope), same(ModalRoute.of(page)));
    expect(ModalRoute.of(scope), isNotNull);
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await tester.dragFrom(const Offset(1, 300), const Offset(700, 0));
    } else {
      Get.back<void>();
    }
    await tester.pumpAndSettle();
    expect(find.text('Previous screen'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
  }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
}
