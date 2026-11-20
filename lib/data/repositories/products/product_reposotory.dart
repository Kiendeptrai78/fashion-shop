import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:fashion_business_app/features/shop/models/category_model.dart';
import 'package:fashion_business_app/features/shop/models/catalog_query.dart';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/data/services/image_storage_service.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/exceptions/firebase_exception.dart';
import 'package:fashion_business_app/utils/exceptions/format_exception.dart';
import 'package:fashion_business_app/utils/exceptions/platform_exception.dart';

class ProductRepository extends GetxController {
  static ProductRepository get instance => Get.find();

  ///firebase instance of database interactions
  final _db = FirebaseFirestore.instance;

  Future<List<ProductModel>> fetchSimilarProducts(ProductModel product) async {
    if (product.categoryId.isEmpty) return [];
    final query = product.catalogId == sneakerCatalogId
        ? _db.collection('Products').where('BrowseKeys',
            arrayContains: CatalogFilter(categoryId: product.categoryId).key)
        : _db.collection('Products').where('CategoryId', isEqualTo: product.categoryId);
    final snapshot = await query.limit(7).get();
    return snapshot.docs.map(ProductModel.fromSnapshot)
        .where((item) => item.id != product.id).take(6).toList();
  }

  Future<CatalogPage> fetchCatalogPage({required CatalogFilter filter, String? cursor}) async {
    final base = _db.collection('Products').where('BrowseKeys', arrayContains: filter.key);
    Query<Map<String, dynamic>> query = base.orderBy(FieldPath.documentId);
    if (cursor != null) query = query.startAfter([cursor]);
    final snapshot = await query.limit(catalogPageSize + 1).get();
    final docs = snapshot.docs.take(catalogPageSize).toList();
    final count = cursor == null ? (await base.count().get()).count : null;
    return CatalogPage(
      products: docs.map(ProductModel.fromSnapshot).toList(),
      hasNext: snapshot.docs.length > catalogPageSize,
      nextCursor: docs.isEmpty ? null : docs.last.id,
      totalCount: count,
    );
  }

  Future<CatalogFacets> fetchCatalogFacets() async {
    final brands = await _db.collection('Brands').where('CatalogId', isEqualTo: sneakerCatalogId).get();
    final categories = await _db.collection('Categories').where('CatalogId', isEqualTo: sneakerCatalogId).get();
    return CatalogFacets(
      brands: brands.docs.map((doc) => BrandModel.fromSnapshot(doc)).toList()
        ..sort((a, b) => a.name.compareTo(b.name)),
      categories: categories.docs.map((doc) => CategoryModel.fromSnapShot(doc)).toList()
        ..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  Stream<List<ProductModel>> getProductStream() {
    return _db.collection('Products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromQuerySnapshot(doc))
          .toList();
    });
  }

  ///get limited featured products
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      final snapshot = await _db
          .collection('Products')
          .where('CatalogId', isEqualTo: 'sneakers-v1')
          .get();
      return snapshot.docs.map((e) => ProductModel.fromSnapshot(e)).toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }

  /// Thêm sản phẩm mới
  Future<void> addProduct(ProductModel product) async {
    try {
      await _db.collection('Products').add(product.toJson());
    } catch (e) {
      throw 'Failed to add product: $e';
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _db.collection('Products').doc(productId).delete();
    } catch (e) {
      print('Error deleting product: $e');
      throw 'Failed to delete product';
    }
  }

   Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _db.collection('Products').doc(productId).update(data);
    } catch (e) {
      print('Error updating product: $e');
      throw 'Failed to update product';
    }
  }

  Future<List<ProductModel>> fetchAllProducts() async {
    try {
      final snapshot = await _db.collection('Products').get();
      return snapshot.docs.map((e) => ProductModel.fromSnapshot(e)).toList();
    } catch (e) {
      print('Error fetching products: $e');
      throw 'Something went wrong while fetching products. Try again later';
    }
  }

  ///get limited featured products
  Future<List<ProductModel>> getAllFeaturedProducts() async {
    try {
      final snapshot = await _db
          .collection('Products')
          .where('CatalogId', isEqualTo: 'sneakers-v1')
          .get();
      return snapshot.docs.map((e) => ProductModel.fromSnapshot(e)).toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }

  ///get limited featured products
  Future<List<ProductModel>> getAllFeaturedProductsNotIsFeatured() async {
    try {
      final snapshot = await _db
          .collection('Products')
          .get();
      return snapshot.docs.map((e) => ProductModel.fromSnapshot(e)).toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }


  ///get product based on the brand
  Future<List<ProductModel>> fetchProductByQuery(Query query) async {
    try {
      final querySnapshot = await query.get();
      final List<ProductModel> productList = querySnapshot.docs
          .map((document) => ProductModel.fromQuerySnapshot(document))
          .toList();
      return productList;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }

  ///
  Future<List<ProductModel>> getFavouriteProducts(List<String> productIds) async {
    try {
      if (productIds.isEmpty) return [];
      final products = <ProductModel>[];
      // Firestore permits at most 30 IDs in a whereIn query.
      for (var start = 0; start < productIds.length; start += 30) {
        final ids = productIds.skip(start).take(30).toList();
        final snapshot = await _db.collection('Products')
            .where(FieldPath.documentId, whereIn: ids).get();
        products.addAll(snapshot.docs.map(ProductModel.fromSnapshot));
      }
      final byId = {for (final product in products) product.id: product};
      return [for (final id in productIds) if (byId.containsKey(id)) byId[id]!];
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }

  ///
  Future<List<ProductModel>> getProductsForBrand({required String brandId, int limit = -1}) async {
    try {
      final querySnapshot = limit == -1
          ? await _db
              .collection('Products')
              .where('Brand.Id', isEqualTo: brandId).where('IsFeatured', isEqualTo: true)
              .get()
          : await _db
              .collection('Products')
              .where('Brand.Id', isEqualTo: brandId).limit(limit).where('IsFeatured', isEqualTo: true)
              .get();
      final products = querySnapshot.docs.map((e) => ProductModel.fromSnapshot(e)).toList();
      return products;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }

  ///
  Future<List<ProductModel>> getProductsForCategory({required String categoryId, int limit = 4}) async {
    try {
      QuerySnapshot productCategoryQuery = limit == -1
          ? await _db.collection('ProductCategory').where('categoryId', isEqualTo: categoryId).get()
          : await _db.collection('ProductCategory').where('categoryId', isEqualTo: categoryId).limit(limit).get();

      List<String> productIds = productCategoryQuery.docs.map((e) => e['productId'] as String).toList();

      final productQuery = await _db.collection('Products').where(FieldPath.documentId, whereIn: productIds).get();

      List<ProductModel> products = productQuery.docs.map((e) => ProductModel.fromSnapshot(e)).toList();

      return products;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. please try again';
    }
  }

  ///upload dummy data to the cloud firebase
  Future<void> uploadDummyData(List<ProductModel> products) async {
    try {
      // upload all the products along with their images
      final storage = Get.put(ImageStorageService());

      // loop through each product
      for (var product in products) {
        //get image data link from local assets
        final thumbnail =
            await storage.getImageDataFromAssets(product.thumbnail);

        //upload image and get its url
        final url = await storage.uploadImageData(
            'Products/Images', thumbnail, product.thumbnail.toString());

        // assign url to product.thumbnail attribute
        product.thumbnail = url;

        //product list of image
        if (product.images != null && product.images!.isNotEmpty) {
          List<String> imagesUrl = [];
          for (var image in product.images!) {
            //get image and get its url
            final assetImage = await storage.getImageDataFromAssets(image);

            final url = await storage.uploadImageData(
                'Products/Images', assetImage, image);
            // assign url to product.thumbnail attribute
            imagesUrl.add(url);
          }
          product.images!.clear();
          product.images!.addAll(imagesUrl);
        }

        //upload variation image
        if (product.productType == ProductType.variable.toString()) {
          for (var variation in product.productVariations!) {
            // get image data link from local assets
            final assetImage =
                await storage.getImageDataFromAssets(variation.image);

            //upload image and get its url
            final url = await storage.uploadImageData(
                'Products/Images', assetImage, variation.image);

            // assign url to product.thumbnail attribute
            variation.image = url;
          }
        }
        await _db.collection('Products').doc(product.id).set(product.toJson());
      }
    } on FirebaseException catch (e) {
      throw e.message!;
    } on SocketException catch (e) {
      throw e.message;
    } on PlatformException catch (e) {
      throw e.message!;
    } catch (e) {
      throw e.toString();
    }
  }
}
