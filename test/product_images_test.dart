import 'package:fashion_business_app/common/widgets/images/image_placeholder.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/features/shop/controllers/product/images_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('product images support missing variations and remove duplicates', () {
    final product = ProductModel.empty()
      ..thumbnail = 'https://example.com/image.png'
      ..images = ['https://example.com/image.png', 'https://example.com/other.png'];
    final controller = ImageController();
    expect(controller.getAllProductImages(product),
        ['https://example.com/image.png', 'https://example.com/other.png']);
    expect(controller.selectedProductImage.value, product.thumbnail);
    controller.selectedProductImage.value = 'chosen-color.png';
    controller.getAllProductImages(product, resetSelection: false);
    expect(controller.selectedProductImage.value, 'chosen-color.png');
  });

  testWidgets('missing image keeps its frame and shows a neutral placeholder', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: TRoundedImage(imageUrl: '', isNetworkImage: true, width: 160, height: 180),
    )));
    expect(find.byType(TImagePlaceholder), findsOneWidget);
    expect(tester.getSize(find.byType(TRoundedImage)), const Size(160, 180));
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed network image shows placeholder instead of an error widget', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(
        body: TRoundedImage(imageUrl: 'https://example.com/unavailable.png',
            isNetworkImage: true, width: 160, height: 180),
      )));
    });
    await tester.pumpAndSettle();
    expect(find.byType(TImagePlaceholder), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
