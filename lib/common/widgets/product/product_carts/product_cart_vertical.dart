import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/common/widgets/product/favourite_icon/favourite_icon.dart';
import 'package:fashion_business_app/features/shop/controllers/product/product_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';

class TProductCartVertical extends StatelessWidget {
  const TProductCartVertical({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final controller = ProductController.instance;
    final colors = product.productAttributes?.where((a) => a.name == 'Color').firstOrNull?.values;
    final sale = product.salePrice > 0 && product.salePrice < product.price;
    final discountPct = sale && product.price > 0
        ? (((product.price - product.salePrice) / product.price) * 100).round()
        : 0;
    final lowStock = product.stock > 0 && product.stock <= 5;
    final lang = Localizations.localeOf(context).languageCode;

    return Semantics(
      button: true,
      label: '${product.brand?.name ?? ''} ${product.title}',
      child: Material(
        color: dark ? const Color(0xFF1A2721) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE7EAE3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Get.to(() => ProductDetail(product: product)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: dark ? const Color(0xFF22342B) : const Color(0xFFF3F4EF),
                        ),
                        TRoundedImage(
                          imageUrl: product.thumbnail,
                          isNetworkImage: true,
                          width: double.infinity,
                          height: double.infinity,
                          padding: const EdgeInsets.fromLTRB(10, 24, 10, 14),
                          borderRadius: 0,
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: (dark ? const Color(0xFF13201A) : Colors.white).withValues(alpha: 0.88),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TFavouriteIcon(productId: product.id),
                          ),
                        ),
                        if (sale)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF173E32),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ShopText(
                                discountPct > 0 ? '-$discountPct%' : 'SALE',
                                style: const TextStyle(
                                  color: Color(0xFFDDEABB),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                        if (lowStock)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: dark
                                    ? const Color(0xFF3A2A15).withValues(alpha: 0.92)
                                    : const Color(0xFFFFF4E5).withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: ShopText(
                                'Only ${product.stock} left',
                                style: TextStyle(
                                  color: dark ? const Color(0xFFFFD08A) : const Color(0xFFB45309),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShopText(
                      'VELORA',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: dark ? const Color(0xFFB6CEB4) : const Color(0xFF4F6B5D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    ShopText(
                      product.title,
                      softWrap: true,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.28,
                      ),
                    ),
                    const SizedBox(height: 3),
                    ShopText(
                      colors == null ? product.categoryName : '${colors.length} colors · ${product.categoryName}',
                      softWrap: true,
                      style: theme.textTheme.labelMedium?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ShopText(
                          formatShopPrice(controller.getProductPrice(product), language: lang),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                          ),
                        ),
                        if (sale)
                          ShopText(
                            formatShopMoney(product.price, language: lang),
                            style: theme.textTheme.labelSmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.hintColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
