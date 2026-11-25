import 'product_model.dart';

class VeloraAiReply {
  const VeloraAiReply({
    required this.text,
    this.products = const [],
    this.showVoucherShortcut = false,
    this.showOrdersShortcut = false,
    this.showReturnsShortcut = false,
    this.showSupportChatShortcut = false,
    this.showCartShortcut = false,
    this.followUpPrompts = const [],
  });

  final String text;
  final List<ProductModel> products;
  final bool showVoucherShortcut;
  final bool showOrdersShortcut;
  final bool showReturnsShortcut;
  final bool showSupportChatShortcut;
  final bool showCartShortcut;
  final List<String> followUpPrompts;
}

