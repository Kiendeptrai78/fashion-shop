import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/personalization/services/customer_benefits.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class DemoBankScreen extends StatefulWidget {
  const DemoBankScreen({super.key});

  @override
  State<DemoBankScreen> createState() => _DemoBankScreenState();
}

class _DemoBankScreenState extends State<DemoBankScreen> {
  bool _showBalance = false;

  Future<void> _topUp(BuildContext context) async {
    var amount = 10000000;
    final language = Localizations.localeOf(context).languageCode;
    final confirmed = await showShopBottomSheet<bool>(context: context, isScrollControlled: true,
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
    final isEn = language == 'en';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TAppbar(showBackArrow: true, title: const ShopText('Payment account',
          style: shopAppbarTitleStyle), actions: [
        ShopGlassIconButton(
          tooltip: 'Account information'.tr,
          icon: Icons.info_outline,
          onPressed: () => showDialog(
            context: context,
            builder: (dialog) {
              final dark = Theme.of(dialog).brightness == Brightness.dark;
              return ShopGlassDialog(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: ShopGlassDecoration(
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
      body: Obx(() => ListView(padding: shopAppbarContentPadding(context, EdgeInsets.all(24)), children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0E2A22), Color(0xFF173E32), Color(0xFF215243)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(
                child: ShopText(
                  'SHOPPING WALLET',
                  style: TextStyle(color: Color(0xFFDDEABB), letterSpacing: 1.8, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                key: const ValueKey('toggle-wallet-balance-visibility'),
                tooltip: _showBalance
                    ? (isEn ? 'Hide balance' : 'Ẩn số dư')
                    : (isEn ? 'Show balance' : 'Hiện số dư'),
                onPressed: () => setState(() => _showBalance = !_showBalance),
                icon: Icon(
                  _showBalance ? Iconsax.eye : Iconsax.eye_slash,
                  color: const Color(0xFFDDEABB),
                  size: 22,
                ),
              ),
            ]),
            const SizedBox(height: 18),
            const ShopText('Available balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _showBalance = !_showBalance),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _showBalance
                          ? formatShopMoney(benefits.balanceVnd / usdToVnd, language: language)
                          : (isEn ? '••••••••' : '•••••••• ₫'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _showBalance
                  ? (isEn ? 'Tap eye icon to hide balance' : 'Chạm biểu tượng mắt để ẩn số dư')
                  : (isEn ? 'Tap balance or eye icon to reveal' : 'Chạm để hiện số dư tài khoản'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11.5),
            ),
            const SizedBox(height: 20),
            const Row(children: [Icon(Icons.check_circle_outline, size: 16, color: Color(0xFFDDEABB)),
              SizedBox(width: 8), Expanded(child: ShopText('Ready for checkout', style: TextStyle(color: Colors.white70, fontSize: 12)))]),
          ]),
        ),
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
          Text(
            _showBalance
                ? '${(entry['amount'] as num) > 0 ? '+' : '−'}${formatShopMoney((entry['amount'] as num).abs() / usdToVnd, language: language)}'
                : '•••••• ₫',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ])),
      ])),
    );
  }
}
