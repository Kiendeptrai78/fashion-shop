import 'package:flutter/material.dart';
import 'package:fashion_business_app/features/shop/models/catalog_query.dart';
import 'package:fashion_business_app/features/shop/screens/home/home_screen.dart';

class AllProductScreen extends StatelessWidget {
  const AllProductScreen({super.key, required this.title, this.categoryId, this.brandId});

  final String title;
  final String? categoryId;
  final String? brandId;

  @override
  Widget build(BuildContext context) => HomeScreen(
    title: title,
    showBackArrow: true,
    initialFilter: CatalogFilter(brandId: brandId, categoryId: categoryId),
  );
}
