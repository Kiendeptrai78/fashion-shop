import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/features/personalization/services/loyalty_coins.dart';
import 'package:fashion_business_app/features/shop/screens/order/order.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class GoldCoinIcon extends StatelessWidget {
  const GoldCoinIcon({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.16),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.1),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFEF3C7).withValues(alpha: 0.72),
            width: 1.1,
          ),
        ),
        alignment: Alignment.center,
        child: ExcludeSemantics(
          child: Text(
            'V',
            style: TextStyle(
              fontSize: size * 0.44,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class LoyaltyCoinsTile extends StatelessWidget {
  const LoyaltyCoinsTile({
    super.key,
    required this.balance,
    this.useCoins,
    this.onChanged,
    this.loading = false,
    this.error,
    this.onTap,
  });

  final int balance;
  final bool? useCoins;
  final ValueChanged<bool>? onChanged;
  final bool loading;
  final String? error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final amount =
        NumberFormat.decimalPattern(isEn ? 'en_US' : 'vi_VN').format(balance);

    final isCheckoutMode = useCoins != null;
    final cardBg = dark ? const Color(0xFF19251F) : Colors.white;
    final borderColor =
        dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    final titleColor = dark ? Colors.white : const Color(0xFF111827);
    final subColor = dark ? Colors.white70 : const Color(0xFF64748B);

    String subtitleText;
    Color subtitleColor = subColor;
    FontWeight subtitleWeight = FontWeight.w500;

    if (error != null) {
      subtitleText = error!;
      subtitleColor = theme.colorScheme.error;
    } else if (loading) {
      subtitleText = isEn ? 'Loading coin balance...' : 'Đang tải số dư xu...';
    } else if (isCheckoutMode) {
      if (balance <= 0) {
        subtitleText = isEn
            ? '0 coins · Review delivered orders for +1,000'
            : '0 xu · Đánh giá đơn đã nhận để tích +1.000 xu';
      } else if (useCoins == true) {
        subtitleText = isEn
            ? 'Applying $amount coins (-$amount ₫)'
            : 'Đang dùng $amount xu (-$amount ₫)';
        subtitleColor =
            dark ? const Color(0xFF86EFAC) : const Color(0xFF173E32);
        subtitleWeight = FontWeight.w600;
      } else {
        subtitleText = isEn
            ? 'Available: $amount coins (= $amount ₫)'
            : 'Khả dụng: $amount xu (= $amount ₫)';
      }
    } else {
      subtitleText = balance > 0
          ? (isEn
              ? '$amount coins (= $amount ₫) · Tap for details'
              : 'Số dư $amount xu (= $amount ₫) · Dùng trừ khi thanh toán')
          : (isEn
              ? '0 coins · Review received orders to get +1,000 coins'
              : '0 xu · Đánh giá đơn đã nhận nhận ngay +1.000 xu');
      if (balance > 0) {
        subtitleColor =
            dark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
        subtitleWeight = FontWeight.w600;
      }
    }

    final child = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: isCheckoutMode ? 11 : 13,
      ),
      child: Row(
        children: [
          GoldCoinIcon(size: isCheckoutMode ? 28 : 32),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCheckoutMode
                      ? (isEn ? 'Use VELORA Coins' : 'Dùng Xu VELORA')
                      : (isEn ? 'VELORA Coins' : 'Xu tích lũy'),
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2.5),
                Text(
                  subtitleText,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: subtitleWeight,
                    color: subtitleColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (isCheckoutMode) ...[
            const SizedBox(width: 6),
            Switch(
              value: useCoins!,
              activeTrackColor: const Color(0xFF173E32),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged:
                  loading || error != null || balance <= 0 ? null : onChanged,
            ),
          ] else if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: dark ? Colors.white54 : const Color(0xFF94A3B8),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap != null ? InkWell(onTap: onTap, child: child) : child,
    );
  }
}

class CoinWalletCard extends StatefulWidget {
  const CoinWalletCard({super.key});

  @override
  State<CoinWalletCard> createState() => _CoinWalletCardState();
}

class _CoinWalletCardState extends State<CoinWalletCard> {
  late final Stream<int> _balance = LoyaltyCoins().watchBalance();

  void _openWalletSheet(BuildContext context, int balance) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final amount =
        NumberFormat.decimalPattern(isEn ? 'en_US' : 'vi_VN').format(balance);

    showShopBottomSheet<void>(
      context: context,

      useSafeArea: true,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const GoldCoinIcon(size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'VELORA Loyalty Coins' : 'Ví Xu VELORA',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$amount ${isEn ? 'coins' : 'xu'} · ${isEn ? 'Worth' : 'Tương đương'} $amount ₫',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                ShopGlassIconButton(
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                  icon: Icons.close_rounded,
                  iconSize: 20,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            _CoinRuleItem(
              step: '1',
              title: isEn
                  ? 'Review purchased sneakers (+1,000 coins)'
                  : 'Đánh giá sản phẩm đã mua (+1.000 xu)',
              desc: isEn
                  ? 'Leave your first review on each delivered sneaker to immediately receive 1,000 coins.'
                  : 'Viết đánh giá lần đầu cho mỗi đôi giày trong đơn Đã nhận để nhận ngay 1.000 xu.',
            ),
            const SizedBox(height: 12),
            _CoinRuleItem(
              step: '2',
              title: isEn
                  ? 'Redeem at checkout (1 coin = 1 ₫)'
                  : 'Trừ trực tiếp khi thanh toán (1 xu = 1 ₫)',
              desc: isEn
                  ? 'Turn on Use VELORA Coins at checkout; combinable with Free Shipping & Product Vouchers.'
                  : 'Bật thanh gạt Dùng Xu VELORA ở màn Thanh toán; dùng chung được với cả mã Freeship và mã Giảm giá SP.',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  Get.to(() => const OrderScreen(initialFilter: 4));
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF173E32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isEn
                      ? 'Review delivered orders (+1,000 coins)'
                      : 'Đánh giá đơn đã nhận (+1.000 xu)',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    return StreamBuilder<int>(
      stream: _balance,
      builder: (context, snapshot) {
        final bal = snapshot.data ?? 0;
        final isErr = snapshot.hasError;
        return LoyaltyCoinsTile(
          balance: bal,
          loading: !snapshot.hasData && !isErr,
          error: isErr
              ? (isEn
                  ? 'Balance unavailable. Tap to retry.'
                  : 'Chưa tải được số dư xu.')
              : null,
          onTap: () => _openWalletSheet(context, bal),
        );
      },
    );
  }
}

class _CoinRuleItem extends StatelessWidget {
  const _CoinRuleItem({
    required this.step,
    required this.title,
    required this.desc,
  });

  final String step;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: ShopGlassDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            step,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
