import 'package:fashion_business_app/data/services/sneaker_catalog_importer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('photo/search migration preserves stock, price and variant edits', () {
    final current = <String, dynamic>{
      'Title': 'Air Force 1', 'CatalogId': 'sneakers-v1',
      'Stock': 12, 'Price': 199.0, 'Thumbnail': 'old.jpg',
      'Brand': {'Id': 'nike', 'Name': 'Nike', 'Image': 'brand.jpg'},
      'CategoryId': 'lifestyle', 'CategoryName': 'Lifestyle',
      'ProductVariations': [
        {'Id': 'white-40', 'Stock': 3, 'Price': 199.0, 'SalePrice': 0,
          'Image': 'old.jpg', 'AttributeValues': {'Color': 'White', 'Size': '40'}},
      ],
    };
    final update = catalogPresentationUpdate(current, {
      'Id': 'shoe', 'Thumbnail': 'transparent.png', 'Images': ['transparent.png'],
      'ProductVariations': [{'Id': 'white-40', 'Image': 'transparent.png'}],
    });
    expect(update, isNot(contains('Stock')));
    expect(update, isNot(contains('Price')));
    expect(update['BrowseKeys'], isNotEmpty);
    final variant = (update['ProductVariations'] as List).single;
    expect(variant['Stock'], 3);
    expect(variant['Price'], 199);
    expect(variant['Image'], 'transparent.png');
  });
}
