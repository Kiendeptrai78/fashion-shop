import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/data/repositories/reviews/review_repository.dart';
import 'package:fashion_business_app/features/shop/screens/product_reviews/product_review.dart';
import 'order_returns_ui_test.dart' show app;

void main() {
  tearDown(() => Get.reset());
  testWidgets('opening an eligible review shows the reward before any submission', (tester) async {
    await tester.pumpWidget(app(ProductReview(productId: 'shoe', productTitle: 'VELORA Court',
      loadReviews: () async => [],
      loadEligibility: () async => const ReviewEligibility(orderDocumentId: 'order'))));
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate((widget) => widget is ElevatedButton));
    await tester.pumpAndSettle();
    expect(find.text('Đánh giá nhận 1.000 xu'), findsOneWidget);
    expect(find.textContaining('Mỗi sản phẩm trong một đơn chỉ được đánh giá một lần'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('already reviewed products cannot open the composer', (tester) async {
    await tester.pumpWidget(app(ProductReview(productId: 'shoe', loadReviews: () async => [],
      loadEligibility: () async => const ReviewEligibility(message: 'Bạn đã đánh giá sản phẩm trong đơn này.'))));
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate((widget) => widget is ElevatedButton));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã đánh giá sản phẩm trong đơn này.'), findsOneWidget);
    expect(find.byType(ReviewRewardNotice), findsNothing);
  });

  testWidgets('reward notice fits small screens in Vietnamese and English', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final language in ['vi', 'en']) {
      await tester.pumpWidget(app(const Scaffold(body: SingleChildScrollView(child: Padding(
        padding: EdgeInsets.all(20), child: ReviewRewardNotice()))), language: language, textScale: 1.3));
      expect(tester.takeException(), isNull);
    }
  });
}
