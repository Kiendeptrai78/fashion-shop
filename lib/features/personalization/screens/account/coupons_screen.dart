import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/cart/cart_screen.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({
    super.key,
    this.subtotal,
    this.initialCouponCode,
    this.currentlyAppliedCode,
    this.currentlyAppliedProductCode,
    this.currentlyAppliedShippingCode,
    this.focusShippingFirst = false,
  });

  final double? subtotal;
  final String? initialCouponCode;
  final String? currentlyAppliedCode;
  final String? currentlyAppliedProductCode;
  final String? currentlyAppliedShippingCode;
  final bool focusShippingFirst;

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  static const _brand = Color(0xFF173E32);
  static const _brandSoft = Color(0xFFF2F6F4);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE5E7EB);

  final _benefits = CustomerBenefits.instance;
  final _codeInput = TextEditingController();
  int _tab = 0;
  String? _selectedProductCouponId;
  String? _inputMessage;
  bool _inputError = false;
  Future<List<ProductModel>>? _productsFuture;

  double? get _effectiveSubtotal {
    if (widget.subtotal != null) return widget.subtotal;
    if (Get.isRegistered<CartController>()) {
      final cartTotal = CartController.instance.totalCartPrice.value;
      if (cartTotal > 0) return cartTotal;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selectedProductCouponId =
        (widget.currentlyAppliedProductCode?.trim().isNotEmpty == true)
            ? widget.currentlyAppliedProductCode!.trim()
            : (widget.currentlyAppliedCode?.trim().isNotEmpty == true
                ? widget.currentlyAppliedCode!.trim()
                : (widget.initialCouponCode?.trim().isNotEmpty == true
                    ? widget.initialCouponCode!.trim()
                    : _benefits.selectedProductCoupon.value?.id));
    _benefits.initialize().then((_) {
      _benefits.markCouponsSeen();
      if (!mounted) return;
      if (_selectedProductCouponId == null) {
        final best = _benefits.bestProductCouponFor(_effectiveSubtotal);
        if (best != null) {
          setState(() => _selectedProductCouponId = best.id);
        }
      }
    });
    if (widget.subtotal == null && Firebase.apps.isNotEmpty) {
      _productsFuture = _loadEligibleProducts();
    }
  }

  @override
  void dispose() {
    _codeInput.dispose();
    super.dispose();
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
    final base =
        (p.salePrice > 0 && p.salePrice < p.price) ? p.salePrice : p.price;
    if (coupon == null || coupon.shipping || coupon.percent <= 0) return base;
    final rawDiscount = base * (coupon.percent / 100.0);
    final capped = coupon.maxUsd > 0 && rawDiscount > coupon.maxUsd
        ? coupon.maxUsd
        : rawDiscount;
    return (base - capped).clamp(0.0, base);
  }

  void _applyTypedCode(String language) {
    final isEn = language == 'en';
    final raw = _codeInput.text.trim().toUpperCase();
    if (raw.isEmpty) {
      setState(() {
        _inputError = true;
        _inputMessage = isEn
            ? 'Please enter a voucher code.'
            : 'Vui lòng nhập mã giảm giá.';
      });
      return;
    }
    FocusScope.of(context).unfocus();

    final matchAny = _benefits.coupons.firstWhereOrNull(
      (c) => c.id.trim().toUpperCase() == raw,
    );
    if (matchAny == null) {
      setState(() {
        _inputError = true;
        _inputMessage = isEn
            ? 'Code "$raw" is invalid or not available for your account.'
            : 'Mã "$raw" không tồn tại hoặc không áp dụng cho tài khoản của bạn.';
      });
      return;
    }
    if (_benefits.used.contains(matchAny.id)) {
      setState(() {
        _inputError = true;
        _inputMessage = isEn
            ? 'Code "$raw" has already been used.'
            : 'Mã "$raw" đã được sử dụng trước đó.';
      });
      return;
    }
    if (!_benefits.now().isBefore(matchAny.expires)) {
      setState(() {
        _inputError = true;
        _inputMessage =
            isEn ? 'Code "$raw" has expired.' : 'Mã "$raw" đã hết hạn.';
      });
      return;
    }

    if (widget.subtotal != null) {
      if (!_benefits.eligible(matchAny, widget.subtotal!)) {
        final missing =
            (matchAny.minUsd - widget.subtotal!).clamp(0, double.infinity);
        setState(() {
          _inputError = true;
          _inputMessage = isEn
              ? 'Add ${formatShopMoney(missing, language: language)} more to use "$raw".'
              : 'Mua thêm ${formatShopMoney(missing, language: language)} để áp dụng mã "$raw".';
        });
        return;
      }
      _benefits.saveCouponSelection(matchAny);
      Navigator.of(context).pop<ShopCoupon?>(matchAny);
      return;
    }

    _benefits.saveCouponSelection(matchAny);
    setState(() {
      _tab = 0;
      if (!matchAny.shipping) _selectedProductCouponId = matchAny.id;
      _inputError = false;
      _inputMessage = matchAny.shipping
          ? (isEn
              ? 'Saved Freeship "${matchAny.id}" — stackable with 1 product discount!'
              : 'Đã lưu mã Freeship "${matchAny.id}" — dùng kèm được thêm 1 mã giảm giá sản phẩm!')
          : (isEn
              ? 'Saved "${matchAny.id}" — stackable with 1 Freeship voucher!'
              : 'Đã lưu mã "${matchAny.id}" — dùng kèm được thêm 1 mã Freeship!');
    });
    _codeInput.clear();
  }

  String _offerHeadline(ShopCoupon coupon, String language) {
    final isEn = language == 'en';
    if (coupon.shipping) {
      return isEn ? 'Free nationwide shipping' : 'Miễn phí vận chuyển';
    }
    final maxText = coupon.maxUsd > 0
        ? (isEn
            ? 'up to ${formatShopMoney(coupon.maxUsd, language: language)}'
            : 'tối đa ${formatShopMoney(coupon.maxUsd, language: language)}')
        : '';
    return isEn
        ? '${coupon.percent}% off${maxText.isNotEmpty ? ' · $maxText' : ''}'
        : 'Giảm ${coupon.percent}%${maxText.isNotEmpty ? ' · $maxText' : ''}';
  }

  bool _isCouponCurrentlyActive(ShopCoupon coupon, bool isPickerMode) {
    final code = coupon.id.toUpperCase();
    if (isPickerMode) {
      if (coupon.shipping) {
        final s = widget.currentlyAppliedShippingCode?.toUpperCase() ?? '';
        final legacy = widget.currentlyAppliedCode?.toUpperCase() ?? '';
        return s == code || legacy == code;
      } else {
        final p = widget.currentlyAppliedProductCode?.toUpperCase() ?? '';
        final legacy = widget.currentlyAppliedCode?.toUpperCase() ?? '';
        return p == code || legacy == code;
      }
    }
    return coupon.shipping
        ? _benefits.selectedShippingCoupon.value?.id.toUpperCase() == code
        : _benefits.selectedProductCoupon.value?.id.toUpperCase() == code;
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _ink),
          const SizedBox(width: 7),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '$title ($count)',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final isEn = language == 'en';
    final isPickerMode = widget.subtotal != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: TAppbar(
        showBackArrow: true,
        leadingOnPressed: () => Navigator.of(context).pop<ShopCoupon?>(null),
        title: Text(
          isPickerMode
              ? (isEn ? 'Select Voucher' : 'Chọn mã ưu đãi')
              : (isEn ? 'My Vouchers' : 'Mã ưu đãi'),
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clean white header: manual code input + colorless underline tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: TextField(
                          controller: _codeInput,
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (_) => _applyTypedCode(language),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                            letterSpacing: 0.5,
                          ),
                          decoration: InputDecoration(
                            hintText: isEn
                                ? 'Enter Freeship or Discount code'
                                : 'Nhập mã Freeship hoặc Giảm giá...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Iconsax.ticket_discount,
                              size: 18,
                              color: _muted,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: _brand, width: 1.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 42,
                      child: FilledButton(
                        onPressed: () => _applyTypedCode(language),
                        style: FilledButton.styleFrom(
                          backgroundColor: _brand,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isEn ? 'Apply' : 'Áp mã',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_inputMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _inputMessage!,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _inputError
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF15803D),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  isEn
                      ? 'You can combine up to 1 Free Shipping + 1 Product Discount per order.'
                      : 'Có thể áp dụng đồng thời tối đa 1 Mã Freeship + 1 Mã giảm giá sản phẩm.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 6),

                // Colorless underline tabs
                Obx(() {
                  final all = _benefits.coupons;
                  final counts = [
                    all
                        .where((c) =>
                            !_benefits.used.contains(c.id) &&
                            _benefits.now().isBefore(c.expires))
                        .length,
                    all.where((c) => _benefits.used.contains(c.id)).length,
                    all
                        .where((c) =>
                            !_benefits.used.contains(c.id) &&
                            !_benefits.now().isBefore(c.expires))
                        .length,
                  ];
                  final labels = isEn
                      ? ['Available', 'Used', 'Expired']
                      : ['Dùng được', 'Đã dùng', 'Hết hạn'];
                  return SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        for (var index = 0; index < 3; index++)
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _tab = index),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _tab == index
                                          ? _ink
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '${labels[index]} (${counts[index]})',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _tab == index
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _tab == index ? _ink : _muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),

          // Voucher list (2 distinct sections in Available tab, NO bottom "Đồng ý" bar)
          Expanded(
            child: Obx(() {
              _benefits.revision.value;
              _benefits.selectedProductCoupon.value;
              _benefits.selectedShippingCoupon.value;

              final effSub = _effectiveSubtotal;

              if (_tab != 0) {
                final otherCoupons = _tab == 1
                    ? _benefits.coupons
                        .where((c) => _benefits.used.contains(c.id))
                        .toList()
                    : _benefits.coupons
                        .where((c) =>
                            !_benefits.used.contains(c.id) &&
                            !_benefits.now().isBefore(c.expires))
                        .toList();

                return RefreshIndicator(
                  onRefresh: _benefits.initialize,
                  color: _brand,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      if (otherCoupons.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 72),
                          child: Column(
                            children: [
                              Icon(
                                Iconsax.ticket_discount,
                                size: 46,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 14),
                              ShopText(
                                'No coupons in this section.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      for (final coupon in otherCoupons)
                        _buildHarmoniousVoucherCard(
                          context: context,
                          coupon: coupon,
                          language: language,
                          isEn: isEn,
                          isPickerMode: isPickerMode,
                          effectiveSubtotal: effSub,
                          isBestRecommended: false,
                          isSelectedCard: false,
                          isCurrentlyApplied: false,
                        ),
                    ],
                  ),
                );
              }

              final shippingCoupons =
                  _benefits.sortedShippingCouponsFor(effSub);
              final productCoupons =
                  _benefits.sortedProductCouponsFor(effSub);
              final bestShip = _benefits.bestShippingCouponFor(effSub);
              final bestProd = _benefits.bestProductCouponFor(effSub);

              final activeProdCoupon = productCoupons.firstWhereOrNull(
                    (c) =>
                        c.id.toUpperCase() ==
                        (_selectedProductCouponId ?? '').toUpperCase(),
                  ) ??
                  bestProd ??
                  productCoupons.firstOrNull;

              Widget buildShippingSection() {
                if (shippingCoupons.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.local_shipping_outlined,
                      title: isEn
                          ? 'Free Shipping Vouchers'
                          : 'Mã Miễn phí vận chuyển',
                      subtitle: isEn ? 'Max 1' : 'Tối đa 1 mã',
                      count: shippingCoupons.length,
                    ),
                    for (final coupon in shippingCoupons)
                      _buildHarmoniousVoucherCard(
                        context: context,
                        coupon: coupon,
                        language: language,
                        isEn: isEn,
                        isPickerMode: isPickerMode,
                        effectiveSubtotal: effSub,
                        isBestRecommended: bestShip?.id == coupon.id,
                        isSelectedCard: false,
                        isCurrentlyApplied:
                            _isCouponCurrentlyActive(coupon, isPickerMode),
                      ),
                    const SizedBox(height: 10),
                  ],
                );
              }

              Widget buildProductSection() {
                if (productCoupons.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Iconsax.ticket_discount,
                      title: isEn
                          ? 'Product Discount Vouchers'
                          : 'Mã Giảm giá sản phẩm',
                      subtitle: isEn ? 'Max 1' : 'Tối đa 1 mã',
                      count: productCoupons.length,
                    ),
                    for (final coupon in productCoupons)
                      _buildHarmoniousVoucherCard(
                        context: context,
                        coupon: coupon,
                        language: language,
                        isEn: isEn,
                        isPickerMode: isPickerMode,
                        effectiveSubtotal: effSub,
                        isBestRecommended: bestProd?.id == coupon.id,
                        isSelectedCard:
                            !isPickerMode && activeProdCoupon?.id == coupon.id,
                        isCurrentlyApplied:
                            _isCouponCurrentlyActive(coupon, isPickerMode),
                      ),
                    const SizedBox(height: 10),
                  ],
                );
              }

              return RefreshIndicator(
                onRefresh: _benefits.initialize,
                color: _brand,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (shippingCoupons.isEmpty && productCoupons.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 72),
                        child: Column(
                          children: [
                            Icon(
                              Iconsax.ticket_discount,
                              size: 46,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 14),
                            ShopText(
                              'No coupons in this section.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),

                    if (widget.focusShippingFirst) ...[
                      buildShippingSection(),
                      buildProductSection(),
                    ] else ...[
                      buildProductSection(),
                      buildShippingSection(),
                    ],

                    // Eligible Sneakers showcase when browsing standalone
                    if (!isPickerMode && _productsFuture != null)
                      FutureBuilder<List<ProductModel>>(
                        future: _productsFuture,
                        builder: (context, snap) {
                          final allShoes = snap.data ?? const <ProductModel>[];
                          if (allShoes.isEmpty) return const SizedBox.shrink();
                          final minUsd = activeProdCoupon?.minUsd ?? 0;
                          final eligibleShoes = allShoes.where((p) {
                            final base =
                                (p.salePrice > 0 && p.salePrice < p.price)
                                    ? p.salePrice
                                    : p.price;
                            return base >= minUsd;
                          }).toList();
                          final displayShoes = (eligibleShoes.isNotEmpty
                                  ? eligibleShoes
                                  : allShoes)
                              .take(12)
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 22, color: _border),
                              Text(
                                activeProdCoupon != null
                                    ? (isEn
                                        ? 'Sneakers eligible for ${activeProdCoupon.id}'
                                        : 'Sản phẩm áp dụng mã ${activeProdCoupon.id}')
                                    : (isEn
                                        ? 'Featured sneakers'
                                        : 'Sản phẩm ưu đãi'),
                                softWrap: true,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayShoes.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: 224,
                                ),
                                itemBuilder: (context, idx) {
                                  final shoe = displayShoes[idx];
                                  final basePrice = (shoe.salePrice > 0 &&
                                          shoe.salePrice < shoe.price)
                                      ? shoe.salePrice
                                      : shoe.price;
                                  final afterVoucher = _priceAfterCoupon(
                                      shoe, activeProdCoupon);
                                  final hasExtraOff = afterVoucher < basePrice;

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      if (activeProdCoupon != null) {
                                        _benefits.selectedProductCoupon.value =
                                            activeProdCoupon;
                                      }
                                      Get.to(() => ProductDetail(product: shoe));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _border),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Center(
                                              child: CachedNetworkImage(
                                                imageUrl: shoe.thumbnail,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            shoe.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: _ink,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            formatShopMoney(
                                              afterVoucher,
                                              language: language,
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.5,
                                              color: _brand,
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
                                                color: Color(0xFF94A3B8),
                                                decoration:
                                                    TextDecoration.lineThrough,
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

  Widget _buildHarmoniousVoucherCard({
    required BuildContext context,
    required ShopCoupon coupon,
    required String language,
    required bool isEn,
    required bool isPickerMode,
    required double? effectiveSubtotal,
    required bool isBestRecommended,
    required bool isSelectedCard,
    required bool isCurrentlyApplied,
  }) {
    final isAvailableTab = _tab == 0;
    final hasSubtotal = effectiveSubtotal != null && effectiveSubtotal > 0;
    final canUse = isAvailableTab &&
        (!hasSubtotal || _benefits.eligible(coupon, effectiveSubtotal));
    final savings =
        (hasSubtotal && canUse) ? coupon.discount(effectiveSubtotal) : 0.0;
    final missingAmount = (hasSubtotal && !canUse)
        ? (coupon.minUsd - effectiveSubtotal).clamp(0.0, double.infinity)
        : 0.0;

    final expText = DateFormat('dd/MM/yyyy').format(
      coupon.expires.subtract(const Duration(days: 1)),
    );
    final minOrderText = coupon.minUsd > 0
        ? (isEn
            ? 'Min ${formatShopMoney(coupon.minUsd, language: language)}'
            : 'Đơn từ ${formatShopMoney(coupon.minUsd, language: language)}')
        : (isEn ? 'No min spend' : 'Đơn 0đ');

    final isHighlighted = canUse && (isCurrentlyApplied || isSelectedCard);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (!coupon.shipping) {
              setState(() => _selectedProductCouponId = coupon.id);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHighlighted ? _brand : _border,
                width: isHighlighted ? 1.3 : 1.0,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Soft, harmonious light-sage ticket stub
                  Container(
                    width: 82,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: canUse ? _brandSoft : const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(11),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            coupon.shipping
                                ? 'FREESHIP'
                                : '-${coupon.percent}%',
                            style: TextStyle(
                              color: canUse ? _brand : const Color(0xFF94A3B8),
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          coupon.shipping
                              ? (isEn ? 'Shipping' : 'Freeship')
                              : (isEn ? 'Product' : 'Sản phẩm'),
                          style: TextStyle(
                            color: canUse ? _muted : const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, color: const Color(0xFFF1F5F9)),

                  // 2. Center compact details + strictly ONE subtle status badge
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (isAvailableTab)
                                _buildSingleSoftBadge(
                                  isBestRecommended: isBestRecommended,
                                  canUse: canUse,
                                  hasSubtotal: hasSubtotal,
                                  isEn: isEn,
                                ),
                              Text(
                                coupon.id,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: canUse ? _ink : _muted,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _offerHeadline(coupon, language),
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: canUse ? _ink : _muted,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$minOrderText · HSD $expText',
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _muted,
                            ),
                          ),
                          if (isAvailableTab && hasSubtotal) ...[
                            const SizedBox(height: 3),
                            if (canUse && savings > 0)
                              Text(
                                isEn
                                    ? 'Saves ${formatShopMoney(savings, language: language)}'
                                    : 'Giảm ${formatShopMoney(savings, language: language)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _brand,
                                ),
                              )
                            else if (!canUse && missingAmount > 0)
                              Text(
                                isEn
                                    ? 'Add ${formatShopMoney(missingAmount, language: language)} more'
                                    : 'Mua thêm ${formatShopMoney(missingAmount, language: language)}',
                                softWrap: true,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _muted,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 3. Direct single-tap Apply button (no extra "Đồng ý" bar needed)
                  if (isAvailableTab)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Center(
                        child: isPickerMode
                            ? OutlinedButton(
                                onPressed: canUse
                                    ? () {
                                        _benefits.saveCouponSelection(coupon);
                                        Navigator.of(context)
                                            .pop<ShopCoupon?>(coupon);
                                      }
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: canUse &&
                                          (isBestRecommended ||
                                              isCurrentlyApplied)
                                      ? _brand
                                      : Colors.white,
                                  foregroundColor: canUse
                                      ? ((isBestRecommended ||
                                              isCurrentlyApplied)
                                          ? Colors.white
                                          : _brand)
                                      : const Color(0xFF94A3B8),
                                  side: BorderSide(
                                    color: canUse ? _brand : _border,
                                  ),
                                  minimumSize: const Size(74, 33),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 6,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: isCurrentlyApplied
                                    ? Text(
                                        isEn ? 'Applied' : 'Đang dùng',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      )
                                    : ShopText(
                                        canUse ? 'Apply' : 'Chưa đủ',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: canUse
                                              ? (isBestRecommended
                                                  ? Colors.white
                                                  : _brand)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                              )
                            : OutlinedButton(
                                onPressed: () {
                                  if (!coupon.shipping) {
                                    setState(() =>
                                        _selectedProductCouponId = coupon.id);
                                  }
                                  if (isCurrentlyApplied) {
                                    if (Get.isRegistered<CartController>() &&
                                        CartController
                                            .instance.cartItems.isNotEmpty) {
                                      Get.to(() => const CartScreen());
                                    } else {
                                      if (coupon.shipping) {
                                        _benefits.selectedShippingCoupon.value =
                                            null;
                                      } else {
                                        _benefits.selectedProductCoupon.value =
                                            null;
                                      }
                                    }
                                    return;
                                  }
                                  _benefits.saveCouponSelection(coupon);
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                        content: Text(
                                          isEn
                                              ? 'Saved ${coupon.id} — auto-applied at checkout.'
                                              : 'Đã lưu mã ${coupon.id} — tự động áp khi Thanh toán.',
                                        ),
                                      ),
                                    );
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isCurrentlyApplied
                                      ? _brandSoft
                                      : _brand,
                                  foregroundColor: isCurrentlyApplied
                                      ? _brand
                                      : Colors.white,
                                  side: const BorderSide(color: _brand),
                                  minimumSize: const Size(74, 33),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  isCurrentlyApplied
                                      ? (isEn ? 'Saved' : 'Đã lưu')
                                      : (isEn ? 'Save' : 'Dùng mã'),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Center(
                        child: Text(
                          _tab == 1
                              ? (isEn ? 'Used' : 'Đã dùng')
                              : (isEn ? 'Expired' : 'Hết hạn'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _muted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleSoftBadge({
    required bool isBestRecommended,
    required bool canUse,
    required bool hasSubtotal,
    required bool isEn,
  }) {
    if (isBestRecommended && canUse) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Text(
          hasSubtotal
              ? (isEn ? 'Best choice' : 'Đề xuất tốt nhất')
              : (isEn ? 'Recommended' : 'Đề xuất dùng'),
          style: const TextStyle(
            color: Color(0xFFB91C1C),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (canUse) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _brandSoft,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isEn ? 'Eligible' : 'Đề xuất dùng',
          style: const TextStyle(
            color: _brand,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isEn ? 'Min not met' : 'Chưa đủ điều kiện',
        style: const TextStyle(
          color: _muted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
