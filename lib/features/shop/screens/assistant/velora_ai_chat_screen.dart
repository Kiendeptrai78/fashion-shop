import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';
import 'package:fashion_business_app/features/shop/services/velora_ai_service.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    required this.text,
    this.products = const [],
    this.showVoucherShortcut = false,
  });

  final bool isUser;
  final String text;
  final List<ProductModel> products;
  final bool showVoucherShortcut;
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

  static const _quickPromptsVi = [
    'Giày chạy bộ dưới 3 triệu',
    'Nike trắng đi hằng ngày',
    'Đôi nào đang giảm giá?',
    'Giày bóng rổ size 42',
    'Có mã giảm giá nào không?',
  ];

  static const _quickPromptsEn = [
    'Running shoes under \$120',
    'White Nike for lifestyle',
    'What is on sale?',
    'Basketball shoes size 42',
    'Any active vouchers?',
  ];

  @override
  void initState() {
    super.initState();
    final isEn = (Get.locale?.languageCode ?? 'vi') == 'en';
    _messages.add(_ChatMessage(
      isUser: false,
      text: isEn
          ? 'Hi! I’m VELORA AI Stylist. Tell me your preferred brand, color, size, activity, or budget — I’ll find the best pairs for you and remember your style for future drops!'
          : 'Xin chào! Mình là Trợ lý AI của VELORA. Bạn hãy nhắn hãng yêu thích, màu sắc, size, mục đích đi hay tầm giá — mình sẽ lọc nhanh những đôi chuẩn gu nhất và ghi nhớ để báo bạn khi có mẫu mới tương tự nhé!',
    ));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _thinking) return;
    _input.clear();
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
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
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
    final prompts = lang == 'en' ? _quickPromptsEn : _quickPromptsVi;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: dark ? const Color(0xFF13201A) : const Color(0xFF173E32),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFDDEABB).withValues(alpha: 0.18),
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
      ),
      body: Column(
        children: [
          // Quick suggestion strip
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF15231D) : const Color(0xFFF4F7F3),
              border: Border(
                bottom: BorderSide(
                  color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE4EAE3),
                ),
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: prompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final prompt = prompts[index];
                return ActionChip(
                  label: Text(
                    prompt,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                    ),
                  ),
                  backgroundColor: dark ? const Color(0xFF1E3229) : Colors.white,
                  side: BorderSide(
                    color: dark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFD8E3DC),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  onPressed: () => _send(prompt),
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
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF1C2C24) : const Color(0xFFF3F6F1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF173E32)),
                          ),
                          const SizedBox(width: 10),
                          ShopText(
                            'Finding matching pairs...',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final msg = _messages[index];
                return _buildBubble(context, msg, dark, lang);
              },
            ),
          ),

          // Composer
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
                              ? 'Ask for brand, color, size, budget...'
                              : 'Hỏi tìm giày theo hãng, màu, size, giá...',
                          filled: true,
                          fillColor: dark ? const Color(0xFF1E3028) : const Color(0xFFF3F5F0),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF1C2C24) : const Color(0xFFF3F6F1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: dark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE3EAE3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.text.replaceAll('**', ''),
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5, height: 1.5),
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
              height: 214,
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
                    width: 158,
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
                                  ColoredBox(color: dark ? const Color(0xFF22342B) : const Color(0xFFF3F4EF)),
                                  TRoundedImage(
                                    imageUrl: p.thumbnail,
                                    isNetworkImage: true,
                                    width: double.infinity,
                                    height: double.infinity,
                                    padding: const EdgeInsets.all(8),
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
                                  Text(
                                    (p.brand?.name ?? p.categoryName).toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.7,
                                      color: dark ? const Color(0xFFB6CEB4) : const Color(0xFF4F6B5D),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    formatShopMoney(displayPrice, language: lang),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                                    ),
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
        ],
      ),
    );
  }
}
