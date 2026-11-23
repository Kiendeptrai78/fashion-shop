import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';
import 'package:fashion_business_app/features/shop/services/velora_ai_service.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    required this.text,
    this.products = const [],
    this.showVoucherShortcut = false,
    this.followUpPrompts = const [],
  });

  final bool isUser;
  final String text;
  final List<ProductModel> products;
  final bool showVoucherShortcut;
  final List<String> followUpPrompts;
}

class VeloraAiChatScreen extends StatefulWidget {
  const VeloraAiChatScreen({super.key});

  @override
  State<VeloraAiChatScreen> createState() => _VeloraAiChatScreenState();
}

class _VeloraAiChatScreenState extends State<VeloraAiChatScreen> {
  final _service = VeloraAiService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_ChatMessage>[];
  bool _thinking = false;
  int _promptPage = 0;

  @override
  void initState() {
    super.initState();
    final isEn = (Get.locale?.languageCode ?? 'vi') == 'en';
    _messages.add(_ChatMessage(
      isUser: false,
      text: isEn
          ? 'Hi! I’m VELORA AI Stylist. Ask me about running, gym, daily sneakers, exact budgets, outfit pairing, shoe care, or your foot length in cm — I’ll match you with the exact VELORA pairs in stock!'
          : 'Xin chào! Mình là Trợ lý AI của VELORA. Bạn có thể hỏi mình bất cứ điều gì:\n'
              '• Tìm giày VELORA theo mục đích (chạy bộ, đi học/đi làm, gym, bóng rổ, địa hình) & đúng tầm giá\n'
              '• Tính size EU chuẩn từ chiều dài bàn chân (cm)\n'
              '• Tư vấn phối đồ, chọn quà tặng, cách vệ sinh giày & săn mã giảm giá',
      followUpPrompts: isEn
          ? const ['Running shoes under \$100', '26cm foot length — what EU size?', 'Biggest discounts right now?']
          : const ['Giày chạy bộ dưới 2.5 triệu', 'Chân dài 26cm đi size mấy?', 'Mẫu nào đang giảm giá sâu nhất?'],
    ));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<String> _visiblePrompts(String lang) {
    final bank = lang == 'en' ? VeloraAiService.promptIdeasEn : VeloraAiService.promptIdeasVi;
    const perPage = 6;
    final start = (_promptPage * perPage) % bank.length;
    return [
      for (var i = 0; i < perPage; i++) bank[(start + i) % bank.length],
    ];
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _thinking) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _thinking = true;
    });
    _scrollToBottom();

    final lang = Localizations.localeOf(context).languageCode;
    final reply = await _service.ask(text, language: lang);
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _messages.add(_ChatMessage(
        isUser: false,
        text: reply.text,
        products: reply.products,
        showVoucherShortcut: reply.showVoucherShortcut,
        followUpPrompts: reply.followUpPrompts,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 160,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final lang = Localizations.localeOf(context).languageCode;
    final prompts = _visiblePrompts(lang);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF101915) : const Color(0xFFFAFBF9),
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          backgroundColor: dark ? const Color(0xFF13221B) : const Color(0xFF173E32),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            tooltip: 'Back'.tr,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDEABB).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFFDDEABB).withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFDDEABB), size: 19),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShopText(
                      'VELORA AI Stylist',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    ShopText(
                      'Smart sneaker finder',
                      style: TextStyle(fontSize: 11, color: Color(0xFFDDEABB)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: lang == 'en' ? 'More ideas' : 'Đổi gợi ý khác',
              icon: const Icon(Iconsax.refresh, color: Color(0xFFDDEABB), size: 20),
              onPressed: () => setState(() => _promptPage++),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // Perfectly centered horizontal prompt strip
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF15241D) : const Color(0xFFF2F6F2),
                border: Border(
                  bottom: BorderSide(
                    color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE3EAE3),
                  ),
                ),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: prompts.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  if (index == prompts.length) {
                    return Material(
                      color: dark ? const Color(0xFF21372D) : const Color(0xFFE6EFEA),
                      borderRadius: BorderRadius.circular(999),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() => _promptPage++),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.refresh,
                                size: 14,
                                color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                lang == 'en' ? 'More ideas' : 'Đổi gợi ý',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final prompt = prompts[index];
                  return Material(
                    color: dark ? const Color(0xFF1D2F27) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: dark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFD7E2DA),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _send(prompt),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          child: Text(
                            prompt,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Chat thread
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                itemCount: _messages.length + (_thinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_thinking && index == _messages.length) {
                    return Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF173E32),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded,
                              color: Color(0xFFDDEABB), size: 15),
                        ),
                        const SizedBox(width: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                          decoration: BoxDecoration(
                            color: dark ? const Color(0xFF1C2C24) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE3EAE3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF173E32)),
                              ),
                              const SizedBox(width: 10),
                              ShopText(
                                'Finding matching pairs...',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return _buildBubble(context, _messages[index], dark, lang);
                },
              ),
            ),

            // Bottom Composer
            Container(
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF14211B) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5EAE3),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: lang == 'en'
                                ? 'Ask for style, price, cm size, care...'
                                : 'Hỏi tìm giày VELORA theo giá, size, phối đồ...',
                            filled: true,
                            fillColor: dark ? const Color(0xFF1E3028) : const Color(0xFFF3F5F0),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 46,
                        height: 46,
                        child: FilledButton(
                          onPressed: _thinking ? null : () => _send(),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF173E32),
                            foregroundColor: const Color(0xFFDDEABB),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Icon(Iconsax.send_1, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context, _ChatMessage msg, bool dark, String lang) {
    final theme = Theme.of(context);
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: const BoxDecoration(
            color: Color(0xFF173E32),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.45),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF173E32),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFDDEABB), size: 15),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF1A2821) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE3EAE3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.text.replaceAll('**', ''),
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5, height: 1.52),
                      ),
                      if (msg.showVoucherShortcut) ...[
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: () => Get.to(() => const CouponsScreen()),
                          icon: const Icon(Iconsax.ticket_discount, size: 16),
                          label: const ShopText('My Coupons', style: TextStyle(fontSize: 12.5)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF173E32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (msg.products.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 224,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 39),
                itemCount: msg.products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final p = msg.products[index];
                  final sale = p.salePrice > 0 && p.salePrice < p.price;
                  final displayPrice = sale ? p.salePrice : p.price;
                  return SizedBox(
                    width: 164,
                    child: Material(
                      color: dark ? const Color(0xFF1A2721) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE4E9E1),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Get.to(() => ProductDetail(product: p)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ColoredBox(
                                      color: dark ? const Color(0xFF22342B) : const Color(0xFFF3F4EF)),
                                  TRoundedImage(
                                    imageUrl: p.thumbnail,
                                    isNetworkImage: true,
                                    width: double.infinity,
                                    height: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    borderRadius: 0,
                                  ),
                                  if (sale)
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF173E32),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '-${(((p.price - p.salePrice) / p.price) * 100).round()}%',
                                          style: const TextStyle(
                                            color: Color(0xFFDDEABB),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShopText(
                                    'VELORA · ${p.categoryName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: dark ? const Color(0xFFB6CEB4) : const Color(0xFF4F6B5D),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 5,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        formatShopMoney(displayPrice, language: lang),
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                                        ),
                                      ),
                                      if (sale)
                                        Text(
                                          formatShopMoney(p.price, language: lang),
                                          style: TextStyle(
                                            fontSize: 10.5,
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
                },
              ),
            ),
          ],
          if (msg.followUpPrompts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 39),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: msg.followUpPrompts.map((idea) {
                  return Material(
                    color: dark ? const Color(0xFF1E3229) : const Color(0xFFEAF2EE),
                    borderRadius: BorderRadius.circular(999),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _send(idea),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        child: Text(
                          idea,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
