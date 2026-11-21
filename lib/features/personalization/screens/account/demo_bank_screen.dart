import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class DemoBankScreen extends StatelessWidget {
  const DemoBankScreen({super.key});

  Future<void> _topUp(BuildContext context) async {
    var amount = 10000000;
    final language = Localizations.localeOf(context).languageCode;
    final confirmed = await showModalBottomSheet<bool>(context: context, isScrollControlled: true,
      builder: (sheet) => SafeArea(child: StatefulBuilder(builder: (context, update) => Padding(
        padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            const ShopText('Top up balance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final value in [5000000, 10000000, 20000000])
              ChoiceChip(selected: amount == value, onSelected: (_) => update(() => amount = value),
                selectedColor: Theme.of(context).colorScheme.primary,
                label: Text(formatShopMoney(value / usdToVnd, language: language), style: TextStyle(
                    color: amount == value ? Colors.white : Theme.of(context).colorScheme.primary))),
            ]),
            const SizedBox(height: 20),
            const ShopText('Test funds only. No money is taken from a bank account.',
                style: TextStyle(fontSize: 12, height: 1.6)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(sheet, true),
                child: const ShopText('Confirm top-up'))),
          ],
        ),
      ))));
    if (confirmed != true) return;
    try { await CustomerBenefits.instance.topUp(amountVnd: amount); } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: ShopText('Couldn’t save. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final benefits = CustomerBenefits.instance;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: TAppbar(showBackArrow: true, title: const ShopText('Payment account',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)), actions: [
        IconButton(
          tooltip: 'Account information'.tr,
          icon: const Icon(Icons.info_outline, size: 21),
          onPressed: () => showDialog(
            context: context,
            builder: (dialog) {
              final dark = Theme.of(dialog).brightness == Brightness.dark;
              return Dialog(
                backgroundColor: dark ? const Color(0xFF17241E) : Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1E372D) : const Color(0xFFEAF2EE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Iconsax.info_circle,
                          color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const ShopText(
                        'Account information',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      ShopText(
                        'Test funds only. No money is taken from a bank account.',
                        textAlign: TextAlign.center,
                        style: Theme.of(dialog).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(dialog).hintColor,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(dialog),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF173E32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const ShopText('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ]),
      body: Obx(() => ListView(padding: const EdgeInsets.all(24), children: [
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(
          color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Expanded(child: ShopText('SHOPPING WALLET',
                style: TextStyle(color: Colors.white70, letterSpacing: 2, fontSize: 10))),
              Icon(Iconsax.wallet_2, color: Colors.white, size: 26)]),
            const SizedBox(height: 34),
            const ShopText('Available balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            Text(formatShopMoney(benefits.balanceVnd / usdToVnd, language: language),
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 26),
            const Row(children: [Icon(Icons.check_circle_outline, size: 16, color: Colors.white70),
              SizedBox(width: 8), Expanded(child: ShopText('Ready for checkout', style: TextStyle(color: Colors.white70, fontSize: 12)))]),
          ])),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: benefits.busy.value ? null : () => _topUp(context),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add, size: 20), SizedBox(width: 10), ShopText('Top up balance'),
          ])),
        const SizedBox(height: 32),
        const ShopText('Transaction history', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        if (benefits.ledger.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 36),
          child: Column(children: [Icon(Iconsax.receipt_item, size: 42), SizedBox(height: 18),
            ShopText('No transactions yet.', textAlign: TextAlign.center)])),
        for (final entry in benefits.ledger) Padding(padding: const EdgeInsets.only(bottom: 24), child: Row(children: [
          CircleAvatar(backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.07),
              child: Icon((entry['amount'] as num) > 0 ? Icons.south_west : Icons.north_east,
                  color: theme.colorScheme.primary, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShopText(entry['title'] == 'Demo top-up' ? 'Balance top-up'
                : entry['title'] == 'Demo refund' ? 'Refund' : 'Order payment',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text(DateFormat.yMMMd(language).add_Hm().format(DateTime.parse(entry['date']).toLocal()),
                style: theme.textTheme.labelSmall),
          ])),
          const SizedBox(width: 8),
          Text('${(entry['amount'] as num) > 0 ? '+' : '−'}${formatShopMoney((entry['amount'] as num).abs() / usdToVnd, language: language)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ])),
      ])),
    );
  }
}
