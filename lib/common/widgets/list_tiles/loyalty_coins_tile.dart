import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fashion_business_app/features/personalization/services/loyalty_coins.dart';

class GoldCoinIcon extends StatelessWidget {
  const GoldCoinIcon({super.key});
  @override
  Widget build(BuildContext context) => Container(width: 44, height: 44,
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFF1BF),
      border: Border.all(color: const Color(0xFFE0B64F))),
    child: CustomPaint(painter: _GoldBarPainter()));
}

class _GoldBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 26, size.height / 26);
    canvas.drawPath(Path()..moveTo(7, 8)..lineTo(19, 8)..lineTo(24, 20)
      ..lineTo(2, 20)..close(), Paint()..color = const Color(0xFFC98B11));
    canvas.drawPath(Path()..moveTo(7, 8)..lineTo(19, 8)..lineTo(20, 14)
      ..lineTo(6, 14)..close(), Paint()..color = const Color(0xFFFFD968));
    canvas.drawLine(const Offset(8, 10), const Offset(17, 10),
      Paint()..color = const Color(0xFFFFF2BD)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(_GoldBarPainter oldDelegate) => false;
}

class LoyaltyCoinsTile extends StatelessWidget {
  const LoyaltyCoinsTile({super.key, required this.balance, this.useCoins,
    this.onChanged, this.loading = false, this.error});
  final int balance;
  final bool? useCoins;
  final ValueChanged<bool>? onChanged;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final amount = NumberFormat.decimalPattern(isEn ? 'en_US' : 'vi_VN').format(balance);
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0B64F).withValues(alpha: 0.45))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [
        const GoldCoinIcon(), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(useCoins == null ? (isEn ? 'VELORA coins' : 'Xu tích lũy')
              : (isEn ? 'Use VELORA coins' : 'Dùng xu thanh toán'),
            style: theme.textTheme.titleSmall?.copyWith(fontSize: 15, fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface)),
          const SizedBox(height: 5),
          Text(error ?? (loading ? (isEn ? 'Loading balance…' : 'Đang tải số dư…')
              : '$amount ${isEn ? 'coins' : 'xu'} · $amount ₫'),
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600,
              color: error == null ? theme.colorScheme.onSurface : theme.colorScheme.error)),
        ])),
        if (useCoins != null) Switch(value: useCoins!,
          onChanged: loading || error != null || balance == 0 ? null : onChanged),
      ]),
      const SizedBox(height: 10),
      Text(useCoins != null
          ? (isEn ? '1 coin = 1₫ · Coins reduce your order total.' : '1 xu = 1đ · Xu được trừ vào tổng thanh toán.')
          : (isEn ? 'Earn 1,000 coins for the first review of each purchased pair.'
              : 'Đánh giá lần đầu mỗi sản phẩm đã nhận để nhận 1.000 xu.'),
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 12.5, fontWeight: FontWeight.w400,
          color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
      ]));
  }
}

class CoinWalletCard extends StatefulWidget {
  const CoinWalletCard({super.key});
  @override
  State<CoinWalletCard> createState() => _CoinWalletCardState();
}

class _CoinWalletCardState extends State<CoinWalletCard> {
  late final Stream<int> _balance = LoyaltyCoins().watchBalance();
  @override
  Widget build(BuildContext context) => StreamBuilder<int>(stream: _balance,
    builder: (context, snapshot) => LoyaltyCoinsTile(balance: snapshot.data ?? 0,
      loading: !snapshot.hasData && !snapshot.hasError,
      error: snapshot.hasError ? (Localizations.localeOf(context).languageCode == 'en'
          ? 'Balance unavailable. Reopen to retry.' : 'Chưa tải được số dư. Hãy mở lại để thử.') : null));
}
