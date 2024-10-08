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
        this.description});

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
      'ProductAttributes': productAttributes != null ? productAttributes!.map((e) => e.toJson()).toList() : [],
      'ProductVariations': productVariations != null ? productVariations!.map((e) => e.toJson()).toList() : [],
    };
  }

  // map json oriented document snapshot from firebase to model
  factory ProductModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    if(document.data() == null) return ProductModel.empty();
    final data = document.data()!;
    return ProductModel(
        id: document.id,
        title: data['Title'],
        stock: data['Stock'] ?? 0,
        isFeatured: data['IsFeatured'] ?? false,
        price: double.parse((data['Price'] ?? 0.0).toString()),
        salePrice: double.parse((data['SalePrice'] ?? 0.0).toString()),
        thumbnail: data['Thumbnail'] ?? '',
        description: data['Description'] ?? '',
        productType: data['ProductType'] ?? '',
        images: data['Images'] != null ? List<String>.from(data['Images']) : [],
        productAttributes: (data['ProductAttributes'] as List<dynamic>).map((e) => ProductAttributeModel.fromJson(e)).toList(),
        productVariations: (data['ProductVariations'] as List<dynamic>).map((e) => ProductVariationModel.fromJson(e)).toList());
  }

  factory ProductModel.fromQuerySnapshot(DocumentSnapshot<Object?> document) {
    final data = document.data() as Map<String, dynamic>;
    return ProductModel(
        id: document.id,
        title: data['Title'] ?? '',
        stock: data['Stock'] ?? 0,
        isFeatured: data['IsFeatured'] ?? false,
        price: double.parse((data['Price'] ?? 0.0).toString()),
        salePrice: double.parse((data['SalePrice'] ?? 0.0).toString()),
        thumbnail: data['Thumbnail'] ?? '',
        description: data['Description'] ?? '',
        productType: data['ProductType'] ?? '',
        images: data['Images'] != null ? List<String>.from(data['Images']) : [],
        productAttributes: (data['ProductAttributes'] as List<dynamic>)
            .map((e) => ProductAttributeModel.fromJson(e))
            .toList(),
        productVariations: (data['ProductVariations'] as List<dynamic>)
            .map((e) => ProductVariationModel.fromJson(e))
            .toList());
  }
}
