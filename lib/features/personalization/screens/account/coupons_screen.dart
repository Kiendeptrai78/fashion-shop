import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({
    super.key,
    this.subtotal,
    this.initialCouponCode,
  });

  final double? subtotal;
  final String? initialCouponCode;

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _benefits = CustomerBenefits.instance;
  int _tab = 0;
  String? _selectedCouponId;
  Future<List<ProductModel>>? _productsFuture;

  @override
  void initState() {
    super.initState();
    _selectedCouponId = widget.initialCouponCode?.trim().isNotEmpty == true
        ? widget.initialCouponCode!.trim()
        : null;
    _benefits.initialize().then((_) {
      _benefits.markCouponsSeen();
      if (mounted && _selectedCouponId == null && _benefits.coupons.isNotEmpty) {
        setState(() => _selectedCouponId = _benefits.coupons.first.id);
      }
    });
    if (widget.subtotal == null) {
      _productsFuture = _loadEligibleProducts();
    }
  }

  Future<List<ProductModel>> _loadEligibleProducts() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Products')
          .limit(36)
          .get();
      final list = snap.docs.map(ProductModel.fromSnapshot).toList();
      list.sort((a, b) {
        final aSale = a.salePrice > 0 && a.salePrice < a.price;
        final bSale = b.salePrice > 0 && b.salePrice < b.price;
        if (aSale != bSale) return aSale ? -1 : 1;
        if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
        return a.title.compareTo(b.title);
      });
      return list;
    } catch (_) {
      return [];
    }
  }

  double _priceAfterCoupon(ProductModel p, ShopCoupon? coupon) {
    final base = (p.salePrice > 0 && p.salePrice < p.price) ? p.salePrice : p.price;
    if (coupon == null || coupon.shipping || coupon.percent <= 0) return base;
    final rawDiscount = base * (coupon.percent / 100.0);
    final capped = coupon.maxUsd > 0 && rawDiscount > coupon.maxUsd
        ? coupon.maxUsd
        : rawDiscount;
    return (base - capped).clamp(0.0, base);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final isEn = language == 'en';

    return Scaffold(
      appBar: const TAppbar(
        showBackArrow: true,
        title: ShopText(
          'My Coupons',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShopText(
                  'A little extra for your next pair.',
                  style: TextStyle(
                    fontSize: 27,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 12),
                ShopText('One coupon per order. Check the conditions before applying.'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Obx(() {
              final all = _benefits.coupons;
              final counts = [
                all
                    .where((coupon) =>
                        !_benefits.used.contains(coupon.id) &&
                        _benefits.now().isBefore(coupon.expires))
                    .length,
                all.where((coupon) => _benefits.used.contains(coupon.id)).length,
                all
                    .where((coupon) =>
                        !_benefits.used.contains(coupon.id) &&
                        !_benefits.now().isBefore(coupon.expires))
                    .length,
              ];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var index = 0; index < 3; index++)
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShopText(
                            ['Available', 'Used', 'Expired'][index],
                            style: TextStyle(
                              color: _tab == index
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${counts[index]}',
                            style: TextStyle(
                              fontSize: 11,
                              color: _tab == index
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      selectedColor: theme.colorScheme.primary,
                      selected: _tab == index,
                      onSelected: (_) => setState(() => _tab = index),
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              final coupons = _benefits.coupons.where((coupon) {
                final used = _benefits.used.contains(coupon.id);
                final expired = !_benefits.now().isBefore(coupon.expires);
                return _tab == 1
                    ? used
                    : _tab == 2
                        ? expired && !used
                        : !used && !expired;
              }).toList();

              final activeCoupon = coupons.firstWhereOrNull(
                    (c) => c.id.toUpperCase() == (_selectedCouponId ?? '').toUpperCase(),
                  ) ??
                  coupons.firstOrNull;

              return RefreshIndicator(
                onRefresh: _benefits.initialize,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: [
                    if (coupons.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Column(
                          children: [
                            Icon(Iconsax.ticket_discount, size: 52),
                            SizedBox(height: 20),
                            ShopText(
                              'No coupons in this section.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    for (final coupon in coupons)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: activeCoupon?.id == coupon.id
                                ? theme.colorScheme.primary
                                : theme.dividerColor.withValues(alpha: 0.18),
                            width: activeCoupon?.id == coupon.id ? 1.6 : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _selectedCouponId = coupon.id),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.primary.withValues(alpha: 0.06),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShopText(
                                      coupon.shipping
                                          ? 'Free shipping'
                                          : '${coupon.percent}% off',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 27,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ShopText(coupon.title),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SelectableText(
                                      coupon.id,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (!coupon.shipping)
                                      Wrap(
                                        spacing: 6,
                                        children: [
                                          const ShopText('Up to'),
                                          Text(
                                            formatShopMoney(
                                              coupon.maxUsd,
                                              language: language,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (coupon.minUsd > 0)
                                      Wrap(
                                        spacing: 6,
                                        children: [
                                          const ShopText('Minimum order'),
                                          Text(
                                            formatShopMoney(
                                              coupon.minUsd,
                                              language: language,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const ShopText('Valid until'),
                                        const SizedBox(width: 6),
                                        Text(
                                          DateFormat.yMMMd(language).format(
                                            coupon.expires
                                                .subtract(const Duration(days: 1)),
                                          ),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    if (widget.subtotal != null && _tab == 0) ...[
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: _benefits.eligible(
                                                  coupon, widget.subtotal!)
                                              ? () => Navigator.pop(context, coupon)
                                              : null,
                                          child: ShopText(
                                            _benefits.eligible(coupon, widget.subtotal!)
                                                ? 'Apply'
                                                : 'Order minimum not reached',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Eligible & Discounted Sneakers showcase right inside the Voucher screen!
                    if (widget.subtotal == null && _productsFuture != null)
                      FutureBuilder<List<ProductModel>>(
                        future: _productsFuture,
                        builder: (context, snap) {
                          final allShoes = snap.data ?? const <ProductModel>[];
                          if (allShoes.isEmpty) return const SizedBox.shrink();
                          final minUsd = activeCoupon?.minUsd ?? 0;
                          final eligibleShoes = allShoes.where((p) {
                            final base = (p.salePrice > 0 && p.salePrice < p.price)
                                ? p.salePrice
                                : p.price;
                            return base >= minUsd;
                          }).toList();
                          final displayShoes =
                              (eligibleShoes.isNotEmpty ? eligibleShoes : allShoes)
                                  .take(16)
                                  .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 32),
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.magic_star,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      activeCoupon != null
                                          ? (isEn
                                              ? 'Sneakers eligible for ${activeCoupon.id}'
                                              : 'Giày VELORA áp dụng ưu đãi mã ${activeCoupon.id}')
                                          : (isEn
                                              ? 'Featured discounted sneakers'
                                              : 'Giày VELORA đang ưu đãi giảm giá'),
                                      style: const TextStyle(
                                        fontSize: 17.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEn
                                    ? 'Tap any pair below to choose your EU size and apply your voucher at checkout.'
                                    : 'Chạm vào mẫu giày bên dưới để chọn size EU và áp mã giảm giá ngay khi thanh toán.',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 14),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayShoes.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: 238,
                                ),
                                itemBuilder: (context, idx) {
                                  final shoe = displayShoes[idx];
                                  final basePrice =
                                      (shoe.salePrice > 0 && shoe.salePrice < shoe.price)
                                          ? shoe.salePrice
                                          : shoe.price;
                                  final afterVoucher =
                                      _priceAfterCoupon(shoe, activeCoupon);
                                  final hasExtraOff = afterVoucher < basePrice;

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () =>
                                        Get.to(() => ProductDetail(product: shoe)),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color:
                                              theme.dividerColor.withValues(alpha: 0.16),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Stack(
                                              children: [
                                                Center(
                                                  child: CachedNetworkImage(
                                                    imageUrl: shoe.thumbnail,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                                if (activeCoupon != null)
                                                  Positioned(
                                                    left: 0,
                                                    top: 0,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF173E32),
                                                        borderRadius:
                                                            BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        activeCoupon.shipping
                                                            ? 'FREESHIP'
                                                            : '-${activeCoupon.percent}%',
                                                        style: const TextStyle(
                                                          color: Color(0xFFDDEABB),
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            shoe.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            formatShopMoney(
                                              afterVoucher,
                                              language: language,
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          if (hasExtraOff || shoe.salePrice > 0)
                                            Text(
                                              formatShopMoney(
                                                shoe.price,
                                                language: language,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                          const SizedBox(height: 6),
                                          Container(
                                            width: double.infinity,
                                            padding:
                                                const EdgeInsets.symmetric(vertical: 6),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF173E32),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isEn ? 'Buy with voucher' : 'Mua với mã này',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
