import 'catalog_search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';

import 'product_attribute_model.dart';
import 'product_variation_model.dart';

class ProductModel {
  String id;
  int stock;
  double price;
  String title;
  DateTime? date;
  double salePrice;
  String thumbnail;
final  bool isFeatured;
  String? description;
  List<String>? images;
  String productType;
  BrandModel? brand;
  String categoryId;
  String categoryName;
  String catalogId;
  List<ProductAttributeModel>? productAttributes;
  List<ProductVariationModel>? productVariations;

  ProductModel(
      {required this.id,
        required this.title,
        required this.stock,
        required this.price,
        required this.thumbnail,
        required this.productType,
        this.date,
        this.images,
        this.salePrice = 0.0,
        required this.isFeatured,
        this.productAttributes,
        this.productVariations,
        this.description,
        this.brand,
        this.categoryId = '',
        this.categoryName = '',
        this.catalogId = ''});

  //create empty func for clean code
  static ProductModel empty() => ProductModel(id: '', title: '', stock: 0, price: 0, thumbnail: '', productType: '', isFeatured: false);

  toJson() {
    return {
      'Title': title,
      'Stock': stock,
      'Price': price,
      'Images': images ?? [],
      'Thumbnail': thumbnail,
      'SalePrice': salePrice,
      'IsFeatured': isFeatured,
      'Description': description,
      'ProductType': productType,
      if (brand != null) 'Brand': brand!.toJson(),
      if (categoryId.isNotEmpty) 'CategoryId': categoryId,
      if (categoryName.isNotEmpty) 'CategoryName': categoryName,
      if (catalogId.isNotEmpty) 'CatalogId': catalogId,
      if (catalogId == sneakerCatalogId) 'BrowseKeys': catalogBrowseKeys(
        title: title, brandName: brand?.name ?? '', categoryName: categoryName,
        brandId: brand?.id ?? '', categoryId: categoryId,
      ),
      'ProductAttributes': productAttributes != null ? productAttributes!.map((e) => e.toJson()).toList() : [],
      'ProductVariations': productVariations != null ? productVariations!.map((e) => e.toJson()).toList() : [],
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> data, {required String id}) {
    return ProductModel(
      id: id,
      title: data['Title'] ?? '',
      stock: data['Stock'] ?? 0,
      isFeatured: data['IsFeatured'] ?? false,
      price: double.parse((data['Price'] ?? 0).toString()),
      salePrice: double.parse((data['SalePrice'] ?? 0).toString()),
      thumbnail: data['Thumbnail'] ?? '',
      description: data['Description'] ?? '',
      productType: data['ProductType'] ?? '',
      brand: data['Brand'] == null ? null
          : BrandModel.fromJson(Map<String, dynamic>.from(data['Brand'])),
      categoryId: data['CategoryId'] ?? '',
      categoryName: data['CategoryName'] ?? '',
      catalogId: data['CatalogId'] ?? '',
      images: List<String>.from(data['Images'] ?? []),
      productAttributes: (data['ProductAttributes'] as List? ?? [])
          .map((e) => ProductAttributeModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      productVariations: (data['ProductVariations'] as List? ?? [])
          .map((e) => ProductVariationModel.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }

  factory ProductModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    return data == null ? ProductModel.empty() : ProductModel.fromJson(data, id: document.id);
  }

  factory ProductModel.fromQuerySnapshot(DocumentSnapshot<Object?> document) {
    final data = document.data() as Map<String, dynamic>?;
    return data == null ? ProductModel.empty() : ProductModel.fromJson(data, id: document.id);
  }
}
