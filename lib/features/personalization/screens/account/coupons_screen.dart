import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key, this.subtotal});
  final double? subtotal;
  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _benefits = CustomerBenefits.instance;
  int _tab = 0;
  @override
  void initState() {
    super.initState();
    _benefits.initialize().then((_) => _benefits.markCouponsSeen());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: const TAppbar(showBackArrow: true, title: ShopText('My Coupons',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.fromLTRB(24, 12, 24, 20), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShopText('A little extra for your next pair.', style: TextStyle(fontSize: 27,
                height: 1.2, fontWeight: FontWeight.w600, letterSpacing: -0.8)),
            SizedBox(height: 12), ShopText('One coupon per order. Check the conditions before applying.'),
          ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Obx(() {
          final all = _benefits.coupons;
          final counts = [
            all.where((coupon) => !_benefits.used.contains(coupon.id) && _benefits.now().isBefore(coupon.expires)).length,
            all.where((coupon) => _benefits.used.contains(coupon.id)).length,
            all.where((coupon) => !_benefits.used.contains(coupon.id) && !_benefits.now().isBefore(coupon.expires)).length,
          ];
          return Wrap(spacing: 8, runSpacing: 8, children: [for (var index = 0; index < 3; index++) ChoiceChip(
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              ShopText(['Available', 'Used', 'Expired'][index], style: TextStyle(
                  color: _tab == index ? Colors.white : theme.colorScheme.primary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6), Text('${counts[index]}', style: TextStyle(fontSize: 11,
                  color: _tab == index ? Colors.white : theme.colorScheme.primary)),
            ]), selectedColor: theme.colorScheme.primary, selected: _tab == index,
            onSelected: (_) => setState(() => _tab = index)),
          ]);
        })),
        const SizedBox(height: 16),
        Expanded(child: Obx(() {
          final coupons = _benefits.coupons.where((coupon) {
            final used = _benefits.used.contains(coupon.id);
            final expired = !_benefits.now().isBefore(coupon.expires);
            return _tab == 1 ? used : _tab == 2 ? expired && !used : !used && !expired;
          }).toList();
          return RefreshIndicator(onRefresh: _benefits.initialize, child: ListView(
            physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              if (coupons.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 80),
                child: Column(children: [Icon(Iconsax.ticket_discount, size: 52), SizedBox(height: 20),
                  ShopText('No coupons in this section.', textAlign: TextAlign.center)])),
              for (final coupon in coupons) Container(margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(border: Border.all(color: theme.dividerColor.withValues(alpha: 0.18)),
                    borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.06),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ShopText(coupon.shipping ? 'Free shipping' : '${coupon.percent}% off',
                          style: TextStyle(color: theme.colorScheme.primary, fontSize: 27, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8), ShopText(coupon.title),
                    ])),
                  Padding(padding: const EdgeInsets.all(20), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SelectableText(coupon.id, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
                      const SizedBox(height: 12),
                      if (!coupon.shipping) Wrap(spacing: 6, children: [const ShopText('Up to'),
                        Text(formatShopMoney(coupon.maxUsd, language: language))]),
                      if (coupon.minUsd > 0) Wrap(spacing: 6, children: [const ShopText('Minimum order'),
                        Text(formatShopMoney(coupon.minUsd, language: language))]),
                      const SizedBox(height: 8),
                      Row(children: [const ShopText('Valid until'), const SizedBox(width: 6),
                        Text(DateFormat.yMMMd(language).format(coupon.expires.subtract(const Duration(days: 1))),
                            style: theme.textTheme.bodySmall)]),
                      if (widget.subtotal != null && _tab == 0) ...[
                        const SizedBox(height: 16),
                        SizedBox(width: double.infinity, child: OutlinedButton(
                          onPressed: _benefits.eligible(coupon, widget.subtotal!) ? () => Navigator.pop(context, coupon) : null,
                          child: ShopText(_benefits.eligible(coupon, widget.subtotal!) ? 'Apply' : 'Order minimum not reached'),
                        )),
                      ],
                    ],
                  )),
                ])),
            ],
          ));
        })),
      ]),
    );
  }
}
