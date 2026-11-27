import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class ProductAvailabilityResult {
  const ProductAvailabilityResult({
    required this.product,
    required this.isDiscontinued,
    required this.isDeleted,
  });

  final ProductModel? product;
  final bool isDiscontinued;
  final bool isDeleted;

  bool get isUnavailable => isDiscontinued || isDeleted;
}

class ProductAvailabilityHelper {
  ProductAvailabilityHelper._();

  static final Map<String, ProductAvailabilityResult> _cache = {};

  static void invalidateCache([String? productId]) {
    if (productId == null) {
      _cache.clear();
    } else {
      _cache.remove(productId);
    }
  }

  static ProductModel fallbackProductFromCartItem(CartItemModel item) {
    return ProductModel(
      id: item.productId,
      title: item.title,
      stock: 20,
      price: item.price,
      salePrice: 0,
      thumbnail: item.image ?? '',
      images: (item.image ?? '').isNotEmpty ? [item.image!] : const [],
      productType: 'ProductType.variable',
      isFeatured: true,
      brand: (item.brandName ?? '').isNotEmpty
          ? BrandModel(id: 'velora', name: item.brandName!, image: '')
          : null,
    );
  }

  static Future<ProductAvailabilityResult> checkCartItem(
    CartItemModel item, {
    bool forceRefresh = false,
  }) async {
    final pid = item.productId.trim();
    if (pid.isEmpty) {
      return ProductAvailabilityResult(
        product: fallbackProductFromCartItem(item),
        isDiscontinued: false,
        isDeleted: false,
      );
    }
    if (!forceRefresh && _cache.containsKey(pid)) {
      return _cache[pid]!;
    }
    if (Firebase.apps.isEmpty) {
      return ProductAvailabilityResult(
        product: fallbackProductFromCartItem(item),
        isDiscontinued: false,
        isDeleted: false,
      );
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Products')
          .doc(pid)
          .get();
      if (!doc.exists || doc.data() == null) {
        final res = ProductAvailabilityResult(
          product: null,
          isDiscontinued: true,
          isDeleted: true,
        );
        _cache[pid] = res;
        return res;
      }
      final model = ProductModel.fromSnapshot(doc);
      final res = ProductAvailabilityResult(
        product: model,
        isDiscontinued: model.isDiscontinued,
        isDeleted: false,
      );
      _cache[pid] = res;
      return res;
    } catch (_) {
      return ProductAvailabilityResult(
        product: fallbackProductFromCartItem(item),
        isDiscontinued: false,
        isDeleted: false,
      );
    }
  }

  static Future<void> openProductDetailFromCartItem(
    BuildContext context,
    CartItemModel item,
  ) async {
    final res = await checkCartItem(item, forceRefresh: true);
    if (!context.mounted) return;
    if (res.isUnavailable || res.product == null) {
      showDiscontinuedSheet(context, item.title);
      return;
    }
    await Get.to(() => ProductDetail(product: res.product!));
  }

  static Future<void> buyAgainFromCartItem(
    BuildContext context,
    CartItemModel item,
  ) async {
    final res = await checkCartItem(item, forceRefresh: true);
    if (!context.mounted) return;
    if (res.isUnavailable || res.product == null) {
      showDiscontinuedSheet(context, item.title);
      return;
    }
    if (Get.isRegistered<CartController>()) {
      final cloned = CartItemModel(
        productId: item.productId,
        title: res.product!.title,
        price: res.product!.salePrice > 0
            ? res.product!.salePrice
            : res.product!.price,
        image: res.product!.thumbnail.isNotEmpty
            ? res.product!.thumbnail
            : item.image,
        quantity: 1,
        variationId: item.variationId,
        brandName: res.product!.brand?.name ?? item.brandName,
        selectedVariation: item.selectedVariation,
      );
      CartController.instance.addOneToCart(cloned);
    }
    await Get.to(() => ProductDetail(product: res.product!));
  }

  static void showDiscontinuedSheet(BuildContext context, String productTitle) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    showShopBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE4E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block_rounded,
                  color: Color(0xFFDC2626),
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isEn
                    ? 'Product Discontinued'
                    : 'Sản phẩm đã ngừng kinh doanh',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isEn
                    ? '"$productTitle" is no longer sold at VELORA. Please explore other active collections in our store.'
                    : 'Mẫu giày "$productTitle" hiện đã ngừng bán hoặc đã được thu hồi khỏi kệ hàng VELORA. Bạn vui lòng tham khảo các mẫu giày thể thao mới đang mở bán nhé!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF173E32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isEn ? 'Got it' : 'Đã hiểu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable badge for discontinued/deleted products.
class DiscontinuedProductBadge extends StatelessWidget {
  const DiscontinuedProductBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF94A3B8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block_rounded,
            size: compact ? 11 : 13,
            color: const Color(0xFF475569),
          ),
          const SizedBox(width: 4),
          Text(
            isEn ? 'Discontinued' : 'Đã ngừng bán',
            style: TextStyle(
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
