import 'package:fashion_business_app/features/shop/controllers/product/images_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/variation_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_attribute_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/models/product_variation_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/widgets/product_attributes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

ProductModel optionsProduct() => ProductModel.empty()
  ..id = 'shoe'
  ..productAttributes = [
    ProductAttributeModel(name: 'Color', values: ['White', 'Black']),
    ProductAttributeModel(name: 'Size', values: ['40', '41']),
  ]
  ..productVariations = [
    for (final color in ['White', 'Black'])
      for (final size in ['40', '41'])
        ProductVariationModel(id: '$color-$size',
            stock: (color == 'White' && size == '41') || (color == 'Black' && size == '40') ? 3 : 0,
            attributeValues: {'Color': color, 'Size': size}),
  ];

void main() {
  tearDown(() => Get.reset());

  test('changing color clears a size that is sold out in the new color', () {
    final controller = VariationController();
    final product = optionsProduct();
    controller.onAttributeSelected(product, 'Color', 'White');
    controller.onAttributeSelected(product, 'Size', '41');
    expect(controller.selectedVariation.value.id, 'White-41');
    controller.onAttributeSelected(product, 'Color', 'Black');
    expect(controller.selectedAttributes['Size'], isNull);
    expect(controller.selectedVariation.value.id, isEmpty);
    expect(controller.getAttributeAvailabilityInVariation(product.productVariations!, 'Size'), {'40'});
  });

  testWidgets('sizes are disabled according to the selected color', (tester) async {
    final controller = Get.put(VariationController());
    final product = optionsProduct();
    controller.onAttributeSelected(product, 'Color', 'White');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Padding(
      padding: const EdgeInsets.all(20), child: TProductAttribute(product: product),
    ))));
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '40')).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '41')).onPressed, isNotNull);
    await tester.tap(find.text('Black'));
    await tester.pump();
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '40')).onPressed, isNotNull);
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '41')).onPressed, isNull);
    await tester.tap(find.widgetWithText(OutlinedButton, '40'));
    await tester.pump();
    expect(controller.selectedVariation.value.id, 'Black-40');
    expect(find.text('3 pairs available in EU 40.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('changing color updates the gallery before a size is selected', () {
    final images = Get.put(ImageController());
    final controller = VariationController();
    final product = optionsProduct();
    for (final v in product.productVariations!) {
      v.image = '${v.attributeValues['Color']}.png';
    }
    controller.onAttributeSelected(product, 'Color', 'Black');
    expect(images.selectedProductImage.value, 'Black.png');
    expect(controller.selectedVariation.value.id, isEmpty);
  });
}
