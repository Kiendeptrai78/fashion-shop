import 'dart:convert';
import 'dart:io';

import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = jsonDecode(File('assets/catalog/sneakers.json').readAsStringSync())
      as Map<String, dynamic>;
  final products = (catalog['products'] as List).map((json) => ProductModel.fromJson(
      Map<String, dynamic>.from(json), id: json['Id'] as String)).toList();

  test('catalog contains 72 distinct Cloudinary images across six brands', () {
    expect(products, hasLength(24));
    final images = products.expand((p) => p.images!).toSet();
    expect(images, hasLength(72));
    expect(images.every((url) => url.startsWith('https://res.cloudinary.com/lbbgn51d/')), isTrue);
    final brands = products.map((p) => p.brand!.name).toSet();
    expect(brands, {'Nike', 'Adidas', 'Jordan', 'New Balance', 'Asics', 'Puma'});
    for (final brand in brands) {
      expect(products.where((p) => p.brand!.name == brand), hasLength(4));
    }
    expect(products.map((p) => p.categoryName).toSet(),
        {'Lifestyle', 'Running', 'Training', 'Basketball', 'Trail'});
  });

  test('stock equals size-color inventory and every variation has its matching image', () {
    for (final product in products) {
      final variants = product.productVariations!;
      expect(variants, hasLength(21), reason: product.id);
      expect(product.stock, variants.fold<int>(0, (total, v) => total + v.stock));
      expect(variants.every((v) => v.stock > 0 && v.price > 0), isTrue);
      expect(variants.map((v) => v.id).toSet(), hasLength(21));
      final colors = product.productAttributes!.firstWhere((a) => a.name == 'Color').values!;
      for (var index = 0; index < colors.length; index++) {
        final matching = variants.where((v) => v.attributeValues['Color'] == colors[index]);
        expect(matching.map((v) => v.attributeValues['Size']).toSet(),
            {'38', '39', '40', '41', '42', '43', '44'});
        expect(matching.every((v) => v.image == product.images![index]), isTrue);
      }
    }
  });

  test('brand and category survive model serialization', () {
    final original = products.first;
    final restored = ProductModel.fromJson(original.toJson(), id: original.id);
    expect(restored.brand!.name, original.brand!.name);
    expect(restored.categoryId, original.categoryId);
    expect(restored.categoryName, original.categoryName);
    expect(restored.catalogId, 'sneakers-v1');
    expect(restored.stock, original.stock);
  });

  test('legacy products without brand or optional collections still parse', () {
    final product = ProductModel.fromJson({'Title': 'Old product', 'Price': 50}, id: 'legacy');
    expect(product.brand, isNull);
    expect(product.images, isEmpty);
    expect(product.productVariations, isEmpty);
  });
}
