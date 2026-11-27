import 'package:fashion_business_app/common/widgets/chat/shop_chat_background.dart';
import 'package:fashion_business_app/common/widgets/chat/shop_chat_send_button.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/features/personalization/screens/account/coupons_screen.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/screens/cart/cart_screen.dart';
import 'package:fashion_business_app/features/shop/screens/order/order.dart';
import 'package:fashion_business_app/features/shop/screens/order/return_request_screen.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';
import 'package:fashion_business_app/features/shop/screens/support_chat/velora_support_chat_screen.dart';
import 'package:fashion_business_app/features/shop/services/velora_ai_service.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.products = const [],
    this.showVoucherShortcut = false,
    this.showOrdersShortcut = false,
    this.showReturnsShortcut = false,
    this.showSupportChatShortcut = false,
    this.showCartShortcut = false,
    this.followUpPrompts = const [],
  });

  final String id;
  final bool isUser;
  final String text;
  final List<ProductModel> products;
  final bool showVoucherShortcut;
  final bool showOrdersShortcut;
  final bool showReturnsShortcut;
  final bool showSupportChatShortcut;
  final bool showCartShortcut;
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
  int _msgSeq = 0;

  @override
  void initState() {
    super.initState();
    final isEn = (Get.locale?.languageCode ?? 'vi') == 'en';
    _messages.add(_ChatMessage(
      id: 'welcome_0',
      isUser: false,
      text: isEn
          ? 'Hi, I’m VELORA’s sneaker assistant. Tell me your budget and how you plan to use your next pair. I’ll consult the shop’s current catalog. Gemini processes advice messages; please leave out personal and payment details.'
          : 'Mình là trợ lý tư vấn giày VELORA. Bạn định mang giày đi đâu và có ngân sách bao nhiêu? Mình sẽ xem dữ liệu sản phẩm hiện có của shop để tư vấn. Gemini xử lý nội dung tư vấn; bạn đừng nhập thông tin cá nhân hoặc thanh toán nhé.',
      showOrdersShortcut: true,
      showSupportChatShortcut: true,
      followUpPrompts: isEn
          ? const [
              'Where is my current order?',
              'Running shoes under \$100',
              '26cm foot length — what EU size?',
            ]
          : const [
              'Kiểm tra đơn hàng của tôi đến đâu rồi?',
              'Giày chạy bộ dưới 2.5 triệu',
              'Mình muốn đổi size / đổi trả giày thì làm thế nào?',
            ],
    ));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<String> _visiblePrompts(String lang) {
    final bank = lang == 'en'
        ? VeloraAiService.promptIdeasEn
        : VeloraAiService.promptIdeasVi;
    const perPage = 6;
    final start = (_promptPage * perPage) % bank.length;
    return [
      for (var i = 0; i < perPage; i++) bank[(start + i) % bank.length],
    ];
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _thinking) return;
    if (preset == null) {
      _input.clear();
      FocusScope.of(context).unfocus();
    }

    final userMsgId = 'u_${++_msgSeq}';
    setState(() {
      _messages.add(_ChatMessage(id: userMsgId, isUser: true, text: text));
      _thinking = true;
    });

    final lang = Localizations.localeOf(context).languageCode;
    final reply = await _service.ask(text, language: lang);
    if (!mounted) return;

    final aiMsgId = 'a_${++_msgSeq}';
    setState(() {
      _thinking = false;
      _messages.add(_ChatMessage(
        id: aiMsgId,
        isUser: false,
        text: reply.text,
        products: reply.products,
        showVoucherShortcut: reply.showVoucherShortcut,
        showOrdersShortcut: reply.showOrdersShortcut,
        showReturnsShortcut: reply.showReturnsShortcut,
        showSupportChatShortcut: reply.showSupportChatShortcut,
        showCartShortcut: reply.showCartShortcut,
        followUpPrompts: reply.followUpPrompts,
      ));
    });
    _scrollToBottomSmoothly();
  }

  void _scrollToBottomSmoothly() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if ((target - _scroll.offset).abs() < 4) return;
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final lang = Localizations.localeOf(context).languageCode;
    final prompts = _visiblePrompts(lang);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ShopChatBackground(child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: TAppbar(
          showBackArrow: true,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShopText(
                'VELORA AI Stylist',
                style: shopAppbarTitleStyle,
              ),
            ],
          ),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(52),
            child: Container(
              height: 52,
              decoration: ShopGlassDecoration(
                color:
                    dark ? const Color(0xFF15241D) : const Color(0xFFF2F6F2),
                border: Border(
                  bottom: BorderSide(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE3EAE3),
                  ),
                ),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: prompts.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  if (index == prompts.length) {
                    return Material(
                      color: dark
                          ? const Color(0xFF21372D)
                          : const Color(0xFFE6EFEA),
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
                                color: dark
                                    ? const Color(0xFFDDEABB)
                                    : const Color(0xFF173E32),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                lang == 'en' ? 'More ideas' : 'Đổi gợi ý',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: dark
                                      ? const Color(0xFFDDEABB)
                                      : const Color(0xFF173E32),
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
                        color: dark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFD7E2DA),
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
                              color: dark
                                  ? const Color(0xFFDDEABB)
                                  : const Color(0xFF173E32),
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )),
          actions: [
            ShopGlassIconButton(
              tooltip: lang == 'en' ? 'Contact support' : 'Chat với CSKH',
              onPressed: () => Get.to(() => const VeloraSupportChatScreen()),
              icon: Iconsax.message_text_1,
            ),
            ShopGlassIconButton(
              tooltip: lang == 'en' ? 'More ideas' : 'Đổi gợi ý khác',
              icon: Iconsax.refresh,
              iconColor: const Color(0xFF173E32),
              iconSize: 19,
              onPressed: () => setState(() => _promptPage++),
            ),
          ],
        ),
        body: Column(
          children: [
            // Horizontal prompt strip


            // Chat thread (Smooth ClampingScrollPhysics & stable ValueKeys — no jumping)
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                physics: const ClampingScrollPhysics(),
                padding: shopAppbarContentPadding(context, const EdgeInsets.fromLTRB(16, 68, 16, 16)),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return KeyedSubtree(
                    key: ValueKey(msg.id),
                    child: _buildBubble(context, msg, dark, lang, theme),
                  );
                },
              ),
            ),

            if (_thinking)
              const LinearProgressIndicator(
                minHeight: 2.5,
                color: Color(0xFF173E32),
                backgroundColor: Color(0xFFDDEABB),
              ),

            // Bottom Composer
            SafeArea(
              top: false,
              child: ShopGlass(
                radius: 26,
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: lang == 'en'
                              ? 'Ask about orders, returns, size, shoes...'
                              : 'Hỏi bất cứ điều gì: đơn hàng, đổi trả, tính size, tìm giày...',
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ShopChatSendButton(onPressed: _thinking ? null : () => _send()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildBubble(
    BuildContext context,
    _ChatMessage msg,
    bool dark,
    String lang,
    ThemeData theme,
  ) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ),
      );
    }

    final hasAnyShortcut = msg.showVoucherShortcut ||
        msg.showOrdersShortcut ||
        msg.showReturnsShortcut ||
        msg.showSupportChatShortcut ||
        msg.showCartShortcut;

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
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFDDEABB),
                  size: 15,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: ShopGlassDecoration(
                    color: dark ? const Color(0xFF1A2821) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE3EAE3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: msg.text, selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5, height: 1.6),
                          strong: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onTapLink: (_, __, ___) {},
                        sizedImageBuilder: (_) => const SizedBox.shrink(),
                      ),
                      if (hasAnyShortcut) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (msg.showSupportChatShortcut)
                              FilledButton.icon(
                                onPressed: () => Get.to(
                                  () => const VeloraSupportChatScreen(),
                                ),
                                icon: const Icon(
                                  Iconsax.message_text_1,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Chat riêng 1-1 với VELORA',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF173E32),
                                  foregroundColor: const Color(0xFFDDEABB),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            if (msg.showOrdersShortcut)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    Get.to(() => const OrderScreen()),
                                icon: const Icon(Iconsax.bag_tick, size: 15),
                                label: const Text(
                                  'Xem Đơn hàng của tôi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF173E32),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            if (msg.showReturnsShortcut)
                              OutlinedButton.icon(
                                onPressed: () => Get.to(
                                  () => const MyReturnRequestsScreen(),
                                ),
                                icon: const Icon(
                                  Iconsax.refresh_circle,
                                  size: 15,
                                  color: Color(0xFF0284C7),
                                ),
                                label: const Text(
                                  'Đổi trả & Bảo hành',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF38BDF8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            if (msg.showCartShortcut)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    Get.to(() => const CartScreen()),
                                icon: const Icon(
                                  Iconsax.shopping_cart,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Mở Giỏ hàng',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF173E32),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            if (msg.showVoucherShortcut)
                              FilledButton.icon(
                                onPressed: () =>
                                    Get.to(() => const CouponsScreen()),
                                icon: const Icon(
                                  Iconsax.ticket_discount,
                                  size: 15,
                                ),
                                label: const ShopText(
                                  'My Coupons',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF173E32),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                          ],
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
              height: 248,
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
                    width: 178,
                    child: Material(
                      color: dark ? const Color(0xFF1A2721) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: dark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE4E9E1),
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
                                    color: dark
                                        ? const Color(0xFF22342B)
                                        : const Color(0xFFF3F4EF),
                                  ),
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF173E32),
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                              padding:
                                  const EdgeInsets.fromLTRB(10, 8, 10, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShopText(
                                    'VELORA · ${p.categoryName}',
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: dark
                                          ? const Color(0xFFB6CEB4)
                                          : const Color(0xFF4F6B5D),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    p.title,
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.22,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 5,
                                    runSpacing: 2,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        formatShopMoney(displayPrice,
                                            language: lang),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: dark
                                              ? const Color(0xFFDDEABB)
                                              : const Color(0xFF173E32),
                                        ),
                                      ),
                                      if (sale)
                                        Text(
                                          formatShopMoney(p.price,
                                              language: lang),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            decoration:
                                                TextDecoration.lineThrough,
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
                    color: dark
                        ? const Color(0xFF1E3229)
                        : const Color(0xFFEAF2EE),
                    borderRadius: BorderRadius.circular(999),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _send(idea),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        child: Text(
                          idea,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: dark
                                ? const Color(0xFFDDEABB)
                                : const Color(0xFF173E32),
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
