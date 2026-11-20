import 'package:flutter/material.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:fashion_business_app/features/shop/screens/all_product/all_product.dart';

class BrandProduct extends StatelessWidget {
  const BrandProduct({super.key, required this.brand});

  final BrandModel brand;

  @override
  Widget build(BuildContext context) => AllProductScreen(title: brand.name, brandId: brand.id);
}
