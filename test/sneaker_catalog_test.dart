import 'dart:convert';
import 'dart:io';

import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = jsonDecode(File('assets/catalog/sneakers.json').readAsStringSync())
      as Map<String, dynamic>;
  final products = (catalog['products'] as List).map((json) => ProductModel.fromJson(
      Map<String, dynamic>.from(json), id: json['Id'] as String)).toList();

  test('catalog contains 105 bespoke VELORA sneakers with transparent Cloudinary PNGs and promo videos across 5 sport categories', () {
    expect(products, hasLength(105));
    final thumbs = products.map((p) => p.thumbnail).toSet();
    expect(thumbs.every((url) => url.startsWith('https://res.cloudinary.com/lbbgn51d/') && url.endsWith('.png')), isTrue);
    expect(products.every((p) => p.videos != null && p.videos!.isNotEmpty), isTrue);
    final brands = products.map((p) => p.brand!.name).toSet();
    expect(brands, {'VELORA'});
    expect(products.map((p) => p.categoryName).toSet(),
        {'Hằng ngày', 'Chạy bộ', 'Tập luyện', 'Bóng rổ', 'Địa hình'});
  });

  test('stock equals size-color inventory and every variation has its matching image', () {
    for (final product in products) {
      final variants = product.productVariations!;
      final colors = product.productAttributes!.firstWhere((a) => a.name == 'Color').values!;
      expect(variants, hasLength(colors.length * 7), reason: product.id);
      expect(product.stock, variants.fold<int>(0, (total, v) => total + v.stock));
      expect(variants.every((v) => v.stock > 0 && v.price > 0), isTrue);
      expect(variants.map((v) => v.id).toSet(), hasLength(colors.length * 7));
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
    expect(restored.brand!.name, 'VELORA');
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
