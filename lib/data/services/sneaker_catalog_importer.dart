import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

/// Explicit development import. Existing catalog records are never deleted.
class SneakerCatalogImporter {
  Future<void> importCampaignsIfNeeded() async {
    final db = FirebaseFirestore.instance;
    final marker = db.collection('CatalogImports').doc('sneaker-campaigns-v1');
    if ((await marker.get()).exists) return;
    final data = jsonDecode(await rootBundle.loadString('assets/catalog/campaigns.json')) as Map<String, dynamic>;
    final batch = db.batch();
    for (final item in data['campaigns'] as List) {
      final record = Map<String, dynamic>.from(item as Map);
      final id = record.remove('Id') as String;
      batch.set(db.collection('Banners').doc(id), record);
    }
    batch.set(marker, {'createdAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  Future<void> importIfNeeded() async {
    final data = jsonDecode(await rootBundle.loadString('assets/catalog/sneakers.json'))
        as Map<String, dynamic>;
    final db = FirebaseFirestore.instance;
    final marker = db.collection('CatalogImports').doc(data['catalogId'] as String);
    if ((await marker.get()).exists) {
      await _upgradePresentation(data);
      return;
    }

    final batch = db.batch();
    for (final entry in <String, String>{
      'brands': 'Brands', 'categories': 'Categories', 'products': 'Products',
    }.entries) {
      for (final item in data[entry.key] as List) {
        final record = Map<String, dynamic>.from(item as Map);
        final id = record.remove('Id') as String;
        // BrandModel also stores the brand ID inside its document.
        if (entry.key == 'brands') record['Id'] = id;
        if (entry.key == 'products') {
          record['BrowseKeys'] = ProductModel.fromJson(record, id: id).toJson()['BrowseKeys'];
        }
        batch.set(db.collection(entry.value).doc(id), record);
      }
    }
    final brandCategories = <String>{};
    for (final item in data['products'] as List) {
      final id = item['Id'] as String;
      final categoryId = item['CategoryId'] as String;
      final brandId = item['Brand']['Id'] as String;
      batch.set(db.collection('ProductCategory').doc('$id-$categoryId'), {
        'productId': id, 'categoryId': categoryId,
      });
      if (brandCategories.add('$brandId-$categoryId')) {
        batch.set(db.collection('BrandCategory').doc('$brandId-$categoryId'), {
          'brandId': brandId, 'categoryId': categoryId,
        });
      }
    }
    batch.set(marker, {
      'productCount': (data['products'] as List).length,
      'importedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> _upgradePresentation(Map<String, dynamic> data) async {
    final db = FirebaseFirestore.instance;
    final marker = db.collection('CatalogImports').doc('sneakers-presentation-v2');
    if ((await marker.get()).exists) return;
    final batch = db.batch();
    for (final template in data['products'] as List) {
      final ref = db.collection('Products').doc(template['Id'] as String);
      final existing = (await ref.get()).data();
      if (existing == null) continue;
      batch.update(ref, catalogPresentationUpdate(existing,
          Map<String, dynamic>.from(template as Map)));
    }
    for (final entry in {'brands': 'Brands', 'categories': 'Categories'}.entries) {
      for (final template in data[entry.key] as List) {
        final ref = db.collection(entry.value).doc(template['Id'] as String);
        if ((await ref.get()).exists) batch.update(ref, {'Image': template['Image']});
      }
    }
    batch.set(marker, {'updatedAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }
}

/// Update photos and search keys without resetting prices, stock or other edits.
Map<String, dynamic> catalogPresentationUpdate(
    Map<String, dynamic> existing, Map<String, dynamic> template) {
  final model = ProductModel.fromJson(existing, id: template['Id'] as String);
  final images = {for (final v in template['ProductVariations'] as List) v['Id']: v['Image']};
  return {
    'Thumbnail': template['Thumbnail'],
    'Images': template['Images'],
    'BrowseKeys': model.toJson()['BrowseKeys'],
    'ProductVariations': [
      for (final v in existing['ProductVariations'] as List? ?? [])
        {...Map<String, dynamic>.from(v as Map),
          if (images.containsKey(v['Id'])) 'Image': images[v['Id']]},
    ],
  };
}
