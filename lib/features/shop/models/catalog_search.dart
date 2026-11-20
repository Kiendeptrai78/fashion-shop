import 'dart:convert';

const sneakerCatalogId = 'sneakers-v1';
const catalogPageSize = 10;

class CatalogFilter {
  const CatalogFilter({this.search = '', this.brandId, this.categoryId});

  final String search;
  final String? brandId;
  final String? categoryId;

  String get key => jsonEncode([
    sneakerCatalogId, brandId ?? '', categoryId ?? '', normalizeCatalogSearch(search),
  ]);
}

String normalizeCatalogSearch(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// One indexed array supports server-side brand/category and word-prefix search.
/// It avoids downloading other pages to filter them on the device.
List<String> catalogBrowseKeys({required String title, required String brandName,
    required String categoryName, required String brandId, required String categoryId}) {
  final phrases = [title, brandName, categoryName, '$brandName $title'];
  final prefixes = <String>{''};
  for (final phrase in phrases) {
    final normalized = normalizeCatalogSearch(phrase);
    for (final term in [normalized, ...normalized.split(' ')]) {
      for (var length = 1; length <= term.length; length++) {
        prefixes.add(term.substring(0, length));
      }
    }
  }
  return [
    for (final brand in {'', brandId})
      for (final category in {'', categoryId})
        for (final prefix in prefixes)
          CatalogFilter(search: prefix, brandId: brand, categoryId: category).key,
  ];
}

