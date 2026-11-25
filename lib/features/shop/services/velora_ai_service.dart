import 'dart:math';
import '../models/velora_ai_reply.dart';
import 'velora_gemini_assistant.dart';
export '../models/velora_ai_reply.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/features/shop/controllers/product/cart_controller.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/models/return_request_model.dart';
import 'package:fashion_business_app/features/shop/models/shipping_route_helper.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart' show FirebaseAIException;
import 'package:get/get.dart';

class VeloraAiService {
  VeloraAiService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _gemini = VeloraGeminiAssistant();
  List<ProductModel>? _cachedProducts;
  DateTime? _cacheTime;

  static const List<String> promptIdeasVi = [
    'Giày chạy bộ dưới 2.5 triệu',
    'Kiểm tra đơn hàng của tôi đến đâu rồi?',
    'Mẫu nào đang giảm giá sâu nhất?',
    'Giày trắng tối giản đi học & đi làm',
    'Chân dài 26cm đi size mấy?',
    'Mình muốn đổi size / đổi trả giày thì làm thế nào?',
    'Ship về Thanh Hóa mất mấy ngày?',
    'Đôi nào giá mềm nhất tại VELORA?',
    'Giày tập gym đế bám chắc',
    'Phối đồ với quần jeans nên chọn đôi nào?',
    'Giày bóng rổ bật nhảy êm cổ chân',
    'Giày leo núi địa hình chống trơn',
    'Gợi ý giày đi du lịch đi bộ cả ngày không đau chân',
    'Tư vấn quà tặng giày cho người yêu',
    'Giày chân bè đi không bị đau mũi',
    'Chọn size thế nào khi chân mình hơi bè?',
    'Giày thoáng khí cho mùa hè không bí chân',
    'Tầm giá từ 2 đến 3 triệu có đôi nào đẹp?',
    'Giày màu đen dễ vệ sinh đi mưa',
    'Có mã giảm giá / voucher nào hôm nay?',
    'Cách vệ sinh giày trắng không bị ố vàng',
    'Đôi nào nổi bật bán chạy nhất hiện tại?',
    'Giày màu xanh rêu signature của VELORA',
    'Giỏ hàng của tôi đang có những gì?',
  ];

  static const List<String> promptIdeasEn = [
    'Running shoes under \$100',
    'Where is my current order?',
    'Biggest discounts right now?',
    'Minimal white sneakers for daily wear',
    '26cm foot length — what EU size?',
    'How do I exchange size or return a pair?',
    'Most affordable VELORA pairs?',
    'Gym & HIIT stability trainers',
    'Best pair to style with jeans?',
    'Basketball shoes with ankle support',
    'Trail sneakers for outdoor hiking',
    'All-day walking & travel shoes',
    'Any active VELORA vouchers?',
    'How to clean white sneakers safely',
  ];

  Future<List<ProductModel>> _loadProducts({bool forceRefresh = false}) async {
    final fresh = _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < const Duration(minutes: 2);
    if (!forceRefresh &&
        fresh &&
        _cachedProducts != null &&
        _cachedProducts!.isNotEmpty) {
      return _cachedProducts!;
    }
    try {
      final snap = await _db.collection('Products').get();
      _cachedProducts = snap.docs.map(ProductModel.fromSnapshot).toList();
      _cacheTime = DateTime.now();
      return _cachedProducts!;
    } catch (_) {
      return _cachedProducts ?? [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadActiveVouchers() async {
    try {
      final snap = await _db
          .collection('Vouchers')
          .where('active', isEqualTo: true)
          .get();
      final now = DateTime.now();
      return snap.docs
          .map((d) => {...d.data(), 'code': d.id})
          .where((v) {
            final exp = v['expires'];
            if (exp is Timestamp) return exp.toDate().isAfter(now);
            return true;
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String _normalize(String input) {
    const map = {
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'đ': 'd',
    };
    final lower = input.toLowerCase();
    final buf = StringBuffer();
    for (var i = 0; i < lower.length; i++) {
      final ch = lower[i];
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
  }

  static double _effectivePrice(ProductModel p) =>
      (p.salePrice > 0 && p.salePrice < p.price) ? p.salePrice : p.price;

  static int _discountPct(ProductModel p) =>
      (p.salePrice > 0 && p.salePrice < p.price && p.price > 0)
          ? (((p.price - p.salePrice) / p.price) * 100).round()
          : 0;

  static const _categoryAliases = <String, List<String>>{
    'Running': [
      'chay bo', 'chay', 'running', 'marathon', 'jogging', 'the duc',
      '5km', '10km', '21km', 'chay sang', 'chay duong dai', 'cardio',
    ],
    'Basketball': [
      'bong ro', 'basketball', 'san bong', 'court', 'bat nhay', 'co chan', 'co lung', 'bong chuyen', 'cau long', 'tennis',
    ],
    'Lifestyle': [
      'hang ngay', 'di choi', 'di hoc', 'di lam', 'lifestyle', 'street', 'thoi trang',
      'casual', 'toi gian', 'minimal', 'quan jeans', 'quan au', 'quan kaki', 'phoi do', 'hen ho', 'cong so',
      'cap doi', 'unisex', 'hack dang', 'tang chieu cao', 'qua tang', 'tang nguoi yeu', 'van phong',
    ],
    'Training': [
      'tap luyen', 'gym', 'training', 'tap ta', 'fitness', 'hiit', 'squat', 'deadlift', 'de phang', 'bam san',
    ],
    'Trail': [
      'dia hinh', 'leo nui', 'trail', 'outdoor', 'phuot', 'du lich', 'di bo nhieu',
      'chong tron', 'di mua', 'da ngoai', 'trekking', 'camping',
    ],
  };

  /// Matches product category whether stored in Vietnamese, English, or categoryId ('1'..'5').
  static bool _productMatchesCategory(ProductModel p, String canonicalCat) {
    final cNorm = _normalize(p.categoryName);
    final id = p.categoryId.trim();
    return switch (canonicalCat) {
      'Running' =>
        id == '1' || cNorm.contains('running') || cNorm.contains('chay'),
      'Basketball' =>
        id == '2' || cNorm.contains('basketball') || cNorm.contains('bong ro'),
      'Lifestyle' =>
        id == '3' ||
            cNorm.contains('lifestyle') ||
            cNorm.contains('hang ngay') ||
            cNorm.contains('thoi trang'),
      'Training' =>
        id == '4' ||
            cNorm.contains('training') ||
            cNorm.contains('tap luyen') ||
            cNorm.contains('gym'),
      'Trail' =>
        id == '5' ||
            cNorm.contains('trail') ||
            cNorm.contains('dia hinh') ||
            cNorm.contains('leo nui'),
      _ => cNorm.contains(_normalize(canonicalCat)),
    };
  }

  static const _colorAliases = <String, List<String>>{
    'White': ['trang', 'white', 'ngoc', 'tinh khoi', 'studio'],
    'Black': ['den', 'black', 'than', 'obsidian'],
    'Red': ['do', 'red', 'do do', 'crimson'],
    'Blue': ['xanh duong', 'xanh bien', 'navy', 'blue', 'xanh bang'],
    'Green': ['xanh la', 'xanh reu', 'xanh rung', 'olive', 'sage', 'green', 'reu', 'forest'],
    'Grey': ['xam', 'ghi', 'bac', 'grey', 'gray', 'slate'],
    'Cream': ['kem', 'be', 'cat', 'beige', 'cream', 'sand', 'nga'],
    'Pink': ['hong', 'pink'],
    'Purple': ['tim', 'purple'],
    'Brown': ['nau', 'brown', 'dat', 'mocha'],
    'Orange': ['cam', 'san ho', 'orange'],
    'Yellow': ['vang', 'yellow', 'dong'],
  };

  static bool _productMatchesColor(ProductModel p, String canonicalColor) {
    final keywords = _colorAliases[canonicalColor] ?? [_normalize(canonicalColor)];
    final pColors = (p.productAttributes
                ?.where((a) =>
                    a.name?.toLowerCase() == 'color' ||
                    _normalize(a.name ?? '').contains('mau'))
                .firstOrNull
                ?.values ??
            [])
        .map(_normalize)
        .join(' ');
    final titleNorm = _normalize(p.title);
    final descNorm = _normalize(p.description ?? '');
    return keywords.any(
      (kw) =>
          pColors.contains(kw) ||
          titleNorm.contains(kw) ||
          descNorm.contains(kw),
    );
  }

  (double?, double?) _extractPriceRangeUsd(String norm) {
    final rangeTrieu = RegExp(
      r'(?:tu\s+)?(\d+(?:[.,]\d+)?)\s*(?:trieu|tr|củ|cu)?\s*(?:den|-|~|to)\s*(\d+(?:[.,]\d+)?)\s*(?:trieu|tr|cu)\b',
    ).firstMatch(norm);
    if (rangeTrieu != null) {
      final lo = double.tryParse(rangeTrieu.group(1)!.replaceAll(',', '.'));
      final hi = double.tryParse(rangeTrieu.group(2)!.replaceAll(',', '.'));
      if (lo != null && hi != null && hi >= lo) {
        return ((lo * 1000000) / usdToVnd, (hi * 1000000) / usdToVnd);
      }
    }

    final minTrieu = RegExp(
            r'(?:tren|hon|tu|over|above)\s+(\d+(?:[.,]\d+)?)\s*(?:trieu|tr|cu)\b')
        .firstMatch(norm);
    if (minTrieu != null) {
      final val = double.tryParse(minTrieu.group(1)!.replaceAll(',', '.'));
      if (val != null && val > 0) return ((val * 1000000) / usdToVnd, null);
    }

    final maxTrieu =
        RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:trieu|tr|cu)\b').firstMatch(norm);
    if (maxTrieu != null) {
      final val = double.tryParse(maxTrieu.group(1)!.replaceAll(',', '.'));
      if (val != null && val > 0) {
        final usd = (val * 1000000) / usdToVnd;
        if (norm.contains('tam') ||
            norm.contains('khoang') ||
            norm.contains('around')) {
          return (usd * 0.78, usd * 1.18);
        }
        return (null, usd);
      }
    }

    final kMatch = RegExp(r'(\d{3,4})\s*k\b').firstMatch(norm);
    if (kMatch != null) {
      final val = double.tryParse(kMatch.group(1)!);
      if (val != null && val >= 200) return (null, (val * 1000) / usdToVnd);
    }

    final usdMatch = RegExp(
            r'(?:\$|usd\s*)(\d+(?:\.\d+)?)|(\d+(?:\.\d+)?)\s*(?:usd|\$)')
        .firstMatch(norm);
    if (usdMatch != null) {
      final raw = usdMatch.group(1) ?? usdMatch.group(2);
      final val = double.tryParse(raw ?? '');
      if (val != null && val > 0) {
        if (norm.contains('over') ||
            norm.contains('above') ||
            norm.contains('tren')) {
          return (val, null);
        }
        return (null, val);
      }
    }
    return (null, null);
  }

  String? _extractSize(String norm) {
    final m = RegExp(r'(?:size|co|sz|eu)\s*(3[6-9]|4[0-6])\b').firstMatch(norm);
    return m?.group(1);
  }

  double? _extractFootLengthCm(String norm) {
    final m = RegExp(r'(\d{2}(?:[.,]\d)?)\s*cm\b').firstMatch(norm);
    if (m == null) return null;
    final val = double.tryParse(m.group(1)!.replaceAll(',', '.'));
    if (val != null && val >= 21.5 && val <= 31.0) return val;
    return null;
  }

  /// Extracts height in cm (e.g., "1m72", "1.72m", "172cm") and weight in kg ("68kg")
  (double?, double?) _extractHeightWeight(String norm) {
    double? heightCm;
    final m1 = RegExp(r'1\s*m\s*(\d{2})\b').firstMatch(norm);
    if (m1 != null) {
      final sub = double.tryParse(m1.group(1)!);
      if (sub != null) heightCm = 100 + sub;
    } else {
      final m2 = RegExp(r'(1[4-9]\d)\s*cm\b').firstMatch(norm);
      if (m2 != null) heightCm = double.tryParse(m2.group(1)!);
    }
    double? weightKg;
    final w = RegExp(r'(\d{2,3})\s*(?:kg|can|ky)\b').firstMatch(norm);
    if (w != null) weightKg = double.tryParse(w.group(1)!);
    return (heightCm, weightKg);
  }

  int _euFromCm(double cm) {
    if (cm <= 23.2) return 37;
    if (cm <= 24.0) return 38;
    if (cm <= 24.6) return 39;
    if (cm <= 25.3) return 40;
    if (cm <= 26.0) return 41;
    if (cm <= 26.7) return 42;
    if (cm <= 27.4) return 43;
    if (cm <= 28.2) return 44;
    return 45;
  }

  int _euFromHeightWeight(double? heightCm, double? weightKg) {
    final h = heightCm ?? 168;
    var base = 40;
    if (h < 158) {
      base = 38;
    } else if (h < 164) {
      base = 39;
    } else if (h < 170) {
      base = 40;
    } else if (h < 175) {
      base = 41;
    } else if (h < 180) {
      base = 42;
    } else if (h < 185) {
      base = 43;
    } else {
      base = 44;
    }
    if (weightKg != null && weightKg >= 78 && base < 44) {
      base += 1;
    }
    return base;
  }

  Future<VeloraAiReply> ask(String query, {String language = 'vi'}) async {
    final text = query.trim();
    if (text.isEmpty) return _askLocal(text, language: language);
    if (VeloraGeminiAssistant.containsPersonalData(text)) {
      return VeloraAiReply(text: language == 'en'
          ? 'Please leave out personal or payment details. I only need your preferred style, budget and shoe size.'
          : 'Bạn không cần gửi thông tin cá nhân hoặc thanh toán. Mình chỉ cần biết kiểu giày, ngân sách và size bạn đang tìm.',
          showSupportChatShortcut: true);
    }
    if (handlesLocally(text)) {
      _gemini.clearHistory();
      return _askLocal(text, language: language);
    }
    try {
      final norm = _normalize(text);
      Query<Map<String, dynamic>> query = _db.collection('Products');
      final category = _categoryAliases.entries.where((entry) =>
          entry.value.any((alias) => norm.contains(alias))).firstOrNull?.key;
      if (category != null) {
        final categories = await _db.collection('Categories').limit(40).get();
        final match = categories.docs.where((doc) {
          final name = _normalize((doc.data()['Name'] ?? '').toString());
          return name == _normalize(category) || name == _normalize(_viCat(category));
        }).firstOrNull;
        if (match != null) query = query.where('CategoryId', isEqualTo: match.id);
      }
      final snapshot = await query.limit(41).get();
      final recentIds = _gemini.recentProductIds;
      final recent = recentIds.isEmpty ? <ProductModel>[] :
          (await _db.collection('Products').where(FieldPath.documentId, whereIn: recentIds).get())
              .docs.map(ProductModel.fromSnapshot).toList();
      final products = [...recent,
        ...snapshot.docs.map(ProductModel.fromSnapshot).where((p) => !recentIds.contains(p.id)),
      ].take(40).toList();
      final reply = await _gemini.ask(text, language: language, products: products,
          catalogIsPartial: snapshot.docs.length > 40 || category != null);
      if (reply.products.isNotEmpty) {
        _recordUserInterest(query: text,
            categories: reply.products.map((p) => p.categoryName).toSet().toList(),
            categoryIds: reply.products.map((p) => p.categoryId).where((id) => id.isNotEmpty).toSet().toList(),
            colors: const [], maxBudgetUsd: null);
      }
      return reply;
    } catch (error) {
      if (error is FirebaseAIException &&
          RegExp(r'quota|resource_exhausted|429', caseSensitive: false).hasMatch(error.message)) {
        return VeloraAiReply(text: language == 'en'
            ? 'The assistant has reached its request limit. Please try again later or chat with VELORA support.'
            : 'Trợ lý đang đạt giới hạn lượt tư vấn. Bạn quay lại sau hoặc nhắn CSKH VELORA nhé.',
            showSupportChatShortcut: true);
      }
      return VeloraAiReply(text: language == 'en'
          ? 'I couldn’t connect to the assistant right now. Please try again or chat with VELORA support.'
          : 'Mình chưa kết nối được trợ lý lúc này. Bạn thử lại hoặc nhắn CSKH VELORA nhé.',
          showSupportChatShortcut: true);
    }
  }

  static bool handlesLocally(String query) {
    final norm = _normalize(query);
    return const ['don hang', 'don cua', 'don nay', 'kiem tra don', 'huy don', 'order',
      'doi tra', 'doi size', 'doi giay', 'tra hang', 'hoan tien', 'bao hanh', 'giao sai',
      'giay loi', 'bi loi', 'bi chat', 'bi rong', 'return', 'exchange', 'refund',
      'gio hang', 'trong gio', 'cart', 'thanh toan', 'chuyen khoan', 'ship cod', 'ngan hang',
      'so tai khoan', 'mat khau', 'dia chi cua', 'ship', 'giao hang', 'voucher', 'ma giam',
      'coupon', 'freeship'].any(norm.contains);
  }

  Future<VeloraAiReply> _askLocal(String query, {String language = 'vi'}) async {
    final trimmed = query.trim();
    final isEn = language == 'en';
    if (trimmed.isEmpty) {
      return VeloraAiReply(
        text: isEn
            ? 'Ask me anything — your orders, return/exchange requests, shipping time to your city, foot size calculator, or sneaker recommendations!'
            : 'Bạn muốn hỏi mình về đơn hàng, đổi trả sản phẩm, thời gian giao hàng về tỉnh của bạn, cách tính size giày hay tìm mẫu giày theo ngân sách? Cứ nhắn thoải mái nhé!',
      );
    }

    final norm = _normalize(trimmed);
    final allProducts = await _loadProducts();
    final activeProducts =
        allProducts.where((p) => !p.isDiscontinued && p.stock > 0).toList();
    final poolProducts =
        activeProducts.isNotEmpty ? activeProducts : allProducts;

    // =========================================================================
    // 1. LIVE ORDER TRACKING / MY ORDERS / CANCELLATION INQUIRIES
    // =========================================================================
    if (norm.contains('don hang') ||
        norm.contains('don cua toi') ||
        norm.contains('don cua minh') ||
        norm.contains('kiem tra don') ||
        norm.contains('huy don') ||
        norm.contains('my order') ||
        norm.contains('cancel order') ||
        norm.contains('track order')) {
      final user = Firebase.apps.isNotEmpty
          ? FirebaseAuth.instance.currentUser
          : null;
      if (user != null) {
        try {
          final snap = await _db
              .collection('Users')
              .doc(user.uid)
              .collection('Orders')
              .get();
          final orders = snap.docs
              .map(OrderModel.fromSnapshot)
              .toList()
            ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

          if (norm.contains('huy don') || norm.contains('cancel')) {
            final pendingOrders =
                orders.where((o) => o.status == OrderStatus.pending).toList();
            final shippingOrders = orders
                .where((o) =>
                    o.status == OrderStatus.processing ||
                    o.status == OrderStatus.shipped)
                .toList();
            final buf = StringBuffer();
            buf.writeln(
              '📌 Quy định hủy đơn tại VELORA: Bạn **chỉ có thể hủy đơn hàng khi đơn đang ở trạng thái "Chờ xác nhận"**.',
            );
            buf.writeln(
              'Khi đơn đã chuyển sang **Đang đóng gói** hoặc **Đang vận chuyển**, đơn đã xuất kho nên không thể hủy nữa.',
            );
            if (pendingOrders.isNotEmpty) {
              buf.writeln(
                '\n• Hiện bạn có **${pendingOrders.length} đơn đang Chờ xác nhận** (${pendingOrders.first.itemsSummary()}) — bạn có thể bấm vào Chi tiết đơn hàng để hủy ngay nếu muốn.',
              );
            } else if (shippingOrders.isNotEmpty) {
              buf.writeln(
                '\n• Đơn hàng hiện tại của bạn (${shippingOrders.first.itemsSummary()}) đã ở bước **${shippingOrders.first.orderStatusLabel()}** nên không thể hủy. Sau khi nhận hàng, nếu cần đổi size hoặc trả hàng bạn có thể tạo yêu cầu **Đổi trả & Bảo hành** miễn phí nhé!',
              );
            }
            return VeloraAiReply(
              text: buf.toString().trim(),
              showOrdersShortcut: true,
              showSupportChatShortcut: true,
              followUpPrompts: const [
                'Kiểm tra đơn hàng của tôi đến đâu rồi?',
                'Mình muốn đổi size / đổi trả giày thì làm thế nào?',
              ],
            );
          }

          if (orders.isEmpty) {
            return VeloraAiReply(
              text:
                  'Mình vừa kiểm tra tài khoản của bạn: hiện bạn chưa có đơn hàng nào tại VELORA. Bạn muốn mình gợi ý một vài mẫu giày đang giảm giá tốt để đặt thử không?',
              products: poolProducts.take(3).toList(),
              followUpPrompts: const [
                'Mẫu nào đang giảm giá sâu nhất?',
                'Giày chạy bộ dưới 2.5 triệu',
              ],
            );
          }

          final buf = StringBuffer();
          buf.writeln(
            '📦 Mình vừa tra cứu trực tiếp **${orders.length} đơn hàng** trong tài khoản của bạn:',
          );
          for (final o in orders.take(3)) {
            final eta = ShippingRouteHelper.estimateForAddress(o.address);
            final total = formatShopMoney(o.totalAmount, language: language);
            buf.writeln(
              '\n• **${o.itemsSummary()}** ($total)\n'
              '  Trạng thái: **${o.orderStatusLabel()}** — ${o.orderStatusSubtitle()}\n'
              '  Lộ trình: Tổng Kho Hà Nội → ${eta.destinationCity} (dự kiến ${eta.minDays}–${eta.maxDays} ngày)',
            );
          }
          buf.writeln(
            '\nBạn có thể bấm nút bên dưới để mở danh sách Đơn hàng hoặc Chat riêng với VELORA nếu cần hỗ trợ về đơn nhé!',
          );
          return VeloraAiReply(
            text: buf.toString().trim(),
            showOrdersShortcut: true,
            showSupportChatShortcut: true,
            followUpPrompts: const [
              'Mình muốn đổi size / đổi trả giày thì làm thế nào?',
              'Quy định hủy đơn hàng như thế nào?',
            ],
          );
        } catch (_) {}
      }
      return VeloraAiReply(
        text:
            'Bạn có thể theo dõi bản đồ hành trình đơn hàng trực tiếp trong mục **Đơn hàng của tôi**. Lưu ý: Đơn hàng chỉ có thể hủy khi đang ở trạng thái **Chờ xác nhận**; khi đã đóng gói hoặc đang giao hàng sẽ không hủy được nữa.',
        showOrdersShortcut: true,
        showSupportChatShortcut: true,
      );
    }

    // =========================================================================
    // 2. RETURN / EXCHANGE / DEFECTIVE SHOE / WRONG SIZE / WARRANTY INQUIRIES
    // =========================================================================
    if (norm.contains('doi tra') ||
        norm.contains('doi size') ||
        norm.contains('doi giay') ||
        norm.contains('tra hang') ||
        norm.contains('hoan tien') ||
        norm.contains('bao hanh') ||
        norm.contains('giao sai') ||
        norm.contains('giay loi') ||
        norm.contains('bi loi') ||
        norm.contains('bi chat') ||
        norm.contains('bi rong') ||
        norm.contains('return') ||
        norm.contains('exchange') ||
        norm.contains('refund')) {
      final user = Firebase.apps.isNotEmpty
          ? FirebaseAuth.instance.currentUser
          : null;
      String activeReturnInfo = '';
      if (user != null) {
        try {
          final rSnap = await _db
              .collection('ReturnRequests')
              .where('userId', isEqualTo: user.uid)
              .get();
          if (rSnap.docs.isNotEmpty) {
            final reqs = rSnap.docs
                .map(ReturnRequestModel.fromSnapshot)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final latest = reqs.first;
            activeReturnInfo =
                '\n\n🔄 **Yêu cầu Đổi/Trả hiện tại của bạn:**\n'
                '• Sản phẩm: **${latest.productTitle}** (${latest.typeLabel()} — ${latest.requestedSizeOrColor})\n'
                '• Trạng thái: **${latest.statusLabel()}**\n'
                '• Địa chỉ đổi mới: ${latest.pickupAddress}';
          }
        } catch (_) {}
      }

      return VeloraAiReply(
        text: '🛡️ **Quy trình Đổi trả & Bảo hành trong 7 ngày tại VELORA:**\n'
            '1. Với các đơn hàng đã **Giao thành công trong vòng 7 ngày**, bạn vào **Chi tiết đơn hàng** hoặc mục **Đổi trả & Bảo hành** → bấm **Đổi / Trả**.\n'
            '2. Chọn 1 trong 3 hình thức: **Đổi kích cỡ EU (38–44)**, **Đổi đôi mới 1-1** (nếu giày lỗi / giao sai) hoặc **Trả hàng & Hoàn tiền 100%**.\n'
            '3. Đính kèm ảnh/video thực tế và điền **Địa chỉ đổi mới**.\n'
            '4. Sau khi Admin VELORA kiểm tra (duyệt hoặc từ chối nếu không đạt điều kiện), Admin sẽ gửi thông báo và **nhắn tin riêng trực tiếp cho bạn** qua mục **Chat với VELORA**!'
            '$activeReturnInfo',
        showReturnsShortcut: true,
        showSupportChatShortcut: true,
        followUpPrompts: const [
          'Kiểm tra đơn hàng của tôi đến đâu rồi?',
          'Chân dài 26cm đi size mấy?',
        ],
      );
    }

    // =========================================================================
    // 3. LIVE CART / PAYMENT / BANK WALLET INQUIRIES
    // =========================================================================
    if (norm.contains('gio hang') ||
        norm.contains('trong gio') ||
        norm.contains('my cart') ||
        norm.contains('thanh toan') ||
        norm.contains('phuong thuc thanh toan') ||
        norm.contains('chuyen khoan') ||
        norm.contains('ship cod') ||
        norm.contains('ngan hang')) {
      final hasCart = Get.isRegistered<CartController>();
      final items = hasCart ? CartController.instance.cartItems : const [];
      final buf = StringBuffer();
      if (items.isNotEmpty) {
        final total = CartController.instance.totalCartPrice.value;
        buf.writeln(
          '🛒 Trong giỏ hàng của bạn hiện đang có **${items.length} sản phẩm** (Tổng tạm tính: **${formatShopMoney(total, language: language)}**):',
        );
        for (final item in items.take(4)) {
          buf.writeln(
            '• **${item.title}** × ${item.quantity} (${formatShopMoney(item.price * item.quantity, language: language)})',
          );
        }
        buf.writeln();
      } else if (norm.contains('gio hang') || norm.contains('trong gio')) {
        buf.writeln('🛒 Giỏ hàng của bạn hiện đang trống.\n');
      }
      buf.writeln(
        '💳 **Phương thức thanh toán tại VELORA:**\n'
        '• Thanh toán khi nhận hàng (COD)\n'
        '• Thanh toán qua Tài khoản Ngân hàng liên kết trong ứng dụng (Demo Bank)\n'
        '• Áp dụng trực tiếp mã Voucher giảm giá hoặc Freeship ở bước Thanh toán.',
      );
      return VeloraAiReply(
        text: buf.toString().trim(),
        showCartShortcut: true,
        showVoucherShortcut: true,
        followUpPrompts: const [
          'Có mã giảm giá / voucher nào hôm nay?',
          'Mẫu nào đang giảm giá sâu nhất?',
        ],
      );
    }

    // =========================================================================
    // 4. WAREHOUSE LOCATION & SHIPPING TIME TO ANY PROVINCE/CITY
    // =========================================================================
    if (norm.contains('shop o dau') ||
        norm.contains('kho o dau') ||
        norm.contains('dia chi shop') ||
        norm.contains('cua hang o dau') ||
        norm.contains('ship ve') ||
        norm.contains('giao ve') ||
        norm.contains('ship thanh hoa') ||
        norm.contains('ship ha noi') ||
        norm.contains('ship hcm') ||
        norm.contains('ship saigon') ||
        norm.contains('ship da nang') ||
        norm.contains('giao mat bao lau') ||
        norm.contains('may ngay nhan duoc') ||
        norm.contains('bao lau nhan duoc')) {
      final eta = ShippingRouteHelper.estimateFromRawText(trimmed);
      return VeloraAiReply(
        text: '📍 **Tổng Kho & Showroom VELORA:** đặt tại **Cầu Giấy, Hà Nội**.\n\n'
            '🚚 **Thời gian giao hàng tự động theo khoảng cách từ Tổng Kho Hà Nội:**\n'
            '• **Hà Nội & khu vực lân cận (~5–30 km):** Nhận hàng siêu tốc trong **1–2 ngày**.\n'
            '• **Thanh Hóa & các tỉnh Miền Bắc / Bắc Trung Bộ (~60–180 km):** Dự kiến **2–3 ngày**.\n'
            '• **Đà Nẵng, Nghệ An, Huế & Miền Trung (~300–760 km):** Dự kiến **3–4 ngày**.\n'
            '• **TP.HCM & các tỉnh Miền Nam (~1.100–1.700 km):** Dự kiến **3–5 ngày**.\n\n'
            '👉 Theo địa điểm bạn hỏi (**${eta.destinationCity}**, cách kho ~${eta.distanceKm} km): đơn hàng sẽ giao tới tay bạn trong khoảng **${eta.minDays}–${eta.maxDays} ngày**!',
        showOrdersShortcut: true,
        followUpPrompts: const [
          'Kiểm tra đơn hàng của tôi đến đâu rồi?',
          'Có mã giảm giá / voucher nào hôm nay?',
        ],
      );
    }

    // =========================================================================
    // 5. CHAT WITH HUMAN SUPPORT / CSKH / CONTACT
    // =========================================================================
    if (norm.contains('nhan vien') ||
        norm.contains('cskh') ||
        norm.contains('nguoi that') ||
        norm.contains('chat voi shop') ||
        norm.contains('chat voi admin') ||
        norm.contains('chat voi velora') ||
        norm.contains('lien he') ||
        norm.contains('hotline') ||
        norm.contains('so dien thoai shop')) {
      return VeloraAiReply(
        text:
            '💬 Bạn có thể nhắn tin **trực tiếp 1-1 với Quản trị viên VELORA** ngay trong ứng dụng!\n\n'
            'Chỉ cần bấm nút **"Chat riêng 1-1 với VELORA"** bên dưới, bạn có thể gửi tin nhắn, hình ảnh thực tế đôi giày hoặc trao đổi trực tiếp về đơn hàng & địa chỉ đổi trả với đội ngũ VELORA.',
        showSupportChatShortcut: true,
        showReturnsShortcut: true,
      );
    }

    // =========================================================================
    // 6. SHOE CARE / CLEANING GUIDE
    // =========================================================================
    if (norm.contains('ve sinh') ||
        norm.contains('giat giay') ||
        norm.contains('bao quan') ||
        norm.contains('o vang') ||
        norm.contains('lau giay') ||
        norm.contains('bi ban') ||
        norm.contains('clean') ||
        norm.contains('wash')) {
      return VeloraAiReply(
        text: '🧼 **Hướng dẫn vệ sinh & giữ form giày VELORA chuẩn Studio:**\n'
            '1. **Tháo rời dây & lót giày**: Giặt riêng bằng nước mát và dung dịch vệ sinh giày chuyên dụng (hoặc xà phòng dịu nhẹ).\n'
            '2. **Vệ sinh thân giày**: Dùng bàn chải lông mềm chà nhẹ theo một chiều — tuyệt đối không cho vào máy giặt hoặc dùng thuốc tẩy Javel.\n'
            '3. **Mẹo chống ố vàng cho giày trắng**: Sau khi rửa sạch bọt, dùng khăn khô thấm ráo rồi đắp 1 lớp giấy ăn trắng phủ kín bề mặt giày, phơi ở nơi thoáng gió, tránh ánh nắng gắt chiếu trực tiếp.\n'
            '4. **Khử mùi & giữ form**: Nhét giấy hút ẩm hoặc shoe-tree vào mũi giày khi không sử dụng.',
        followUpPrompts: const [
          'Giày màu đen dễ vệ sinh đi mưa',
          'Giày trắng tối giản đi học & đi làm',
        ],
      );
    }

    // =========================================================================
    // 7. VOUCHERS & PROMOTIONS
    // =========================================================================
    if (norm.contains('voucher') ||
        norm.contains('ma giam') ||
        norm.contains('coupon') ||
        norm.contains('freeship')) {
      final vouchers = await _loadActiveVouchers();
      final salePicks =
          poolProducts.where((p) => _discountPct(p) > 0).take(3).toList();
      if (vouchers.isEmpty) {
        return VeloraAiReply(
          text:
              '🎟️ Bạn hãy mở **Ví Voucher VELORA** bên dưới để lưu các mã chào mừng thành viên mới (`WELCOME10`, `SHIPNEW`) và ưu đãi theo sự kiện nhé!',
          products: salePicks,
          showVoucherShortcut: true,
          followUpPrompts: const [
            'Mẫu nào đang giảm giá sâu nhất?',
            'Giày chạy bộ dưới 2.5 triệu',
          ],
        );
      }
      final lines = vouchers.take(5).map((v) {
        final code = v['code'] ?? '';
        final title = v['title'] ?? '';
        final shipping = v['shipping'] == true;
        final pct = v['percent'] ?? 0;
        final minUsd = (v['minUsd'] as num? ?? 0).toDouble();
        final offer =
            shipping ? 'Miễn phí vận chuyển' : 'Giảm $pct%';
        final minLabel = minUsd > 0
            ? ' (đơn từ ${formatShopMoney(minUsd, language: 'vi')})'
            : '';
        return '• **$code** — $offer$minLabel: $title';
      }).join('\n');
      return VeloraAiReply(
        text: '🎟️ **Các mã Voucher VELORA đang có hiệu lực hôm nay:**\n\n'
            '$lines\n\n'
            'Bạn bấm vào nút bên dưới để mở Ví Voucher hoặc xem các đôi giày đang được áp dụng ưu đãi nhé!',
        products: salePicks,
        showVoucherShortcut: true,
        followUpPrompts: const [
          'Mẫu nào đang giảm giá sâu nhất?',
          'Đôi nào giá mềm nhất tại VELORA?',
        ],
      );
    }

    // =========================================================================
    // 8. FOOT LENGTH (cm) OR HEIGHT + WEIGHT → EXACT EU SIZE CALCULATOR
    // =========================================================================
    final footCm = _extractFootLengthCm(norm);
    final (heightCm, weightKg) = _extractHeightWeight(norm);
    if (footCm != null || heightCm != null || weightKg != null) {
      final wideFoot =
          norm.contains('be') || norm.contains('rong') || norm.contains('day');
      final baseEu = footCm != null
          ? _euFromCm(footCm)
          : _euFromHeightWeight(heightCm, weightKg);
      final recommendedEu = wideFoot ? min(44, baseEu + 1) : baseEu;
      final sizeStr = '$recommendedEu';

      final inSize = poolProducts.where((p) {
        final hasVar = (p.productVariations ?? []).any(
          (v) =>
              v.stock > 0 &&
              v.attributeValues.values.any((val) => val.trim().contains(sizeStr)),
        );
        final hasAttr = p.productAttributes
                ?.where((a) => a.name?.toLowerCase() == 'size')
                .firstOrNull
                ?.values
                ?.any((v) => v.contains(sizeStr)) ??
            false;
        return hasVar || hasAttr;
      }).take(4).toList();

      final reasonText = footCm != null
          ? 'chiều dài bàn chân **${footCm.toStringAsFixed(1)} cm**'
          : '${heightCm != null ? 'chiều cao **${heightCm.round()} cm**' : ''}${heightCm != null && weightKg != null ? ' · ' : ''}${weightKg != null ? 'cân nặng **${weightKg.round()} kg**' : ''}';

      return VeloraAiReply(
        text: '📏 Với $reasonText${wideFoot ? ' (form chân bè ngang)' : ''}, size giày chuẩn nhất tại VELORA cho bạn là **Size EU $recommendedEu**.\n'
            '• Nếu bạn thích đi tất dày thể thao hoặc mũi chân bè rộng, có thể chọn lên **EU ${min(44, recommendedEu + 1)}**.\n'
            '• Nếu nhận giày về mang thử trong nhà thấy hơi chật/rộng, VELORA hỗ trợ **đổi size miễn phí tận nơi trong 7 ngày**!\n\n'
            'Dưới đây là các mẫu VELORA đang sẵn **size EU $recommendedEu** trong kho:',
        products: inSize.isNotEmpty ? inSize : poolProducts.take(4).toList(),
        followUpPrompts: [
          'Giày chạy bộ size $recommendedEu',
          'Giày đi làm hằng ngày size $recommendedEu',
          'Mình muốn đổi size / đổi trả giày thì làm thế nào?',
        ],
      );
    }

    // =========================================================================
    // 9. DIRECT PRODUCT LOOKUP (including Discontinued Check & Comparison)
    // =========================================================================
    final directMatches = allProducts.where((p) {
      final t = _normalize(p.title).replaceFirst('velora ', '').trim();
      if (t.length < 3) return false;
      return norm.contains(t) ||
          t.split(' ').where((w) => w.length >= 4).any((w) => norm.contains(w));
    }).toList();

    if (directMatches.isNotEmpty) {
      // Check if user asked to compare 2 specific shoes
      if (directMatches.length >= 2 &&
          (norm.contains('so sanh') ||
              norm.contains('khac gi') ||
              norm.contains('chon doi nao') ||
              norm.contains('hay'))) {
        final a = directMatches[0];
        final b = directMatches[1];
        final pa = formatShopMoney(_effectivePrice(a), language: language);
        final pb = formatShopMoney(_effectivePrice(b), language: language);
        return VeloraAiReply(
          text: '⚖️ **So sánh chi tiết ${a.title} và ${b.title}:**\n\n'
              '1. **${a.title}** (Dòng ${_viCat(a.categoryName)}):\n'
              '   • Giá: **$pa**${_discountPct(a) > 0 ? ' (đang giảm ${_discountPct(a)}%)' : ''}\n'
              '   • Tồn kho: ${a.isDiscontinued ? 'Đã ngừng bán' : 'Còn ${a.stock} đôi'}\n'
              '   • Đặc điểm: ${a.description ?? 'Thiết kế chuyên biệt, êm ái.'}\n\n'
              '2. **${b.title}** (Dòng ${_viCat(b.categoryName)}):\n'
              '   • Giá: **$pb**${_discountPct(b) > 0 ? ' (đang giảm ${_discountPct(b)}%)' : ''}\n'
              '   • Tồn kho: ${b.isDiscontinued ? 'Đã ngừng bán' : 'Còn ${b.stock} đôi'}\n'
              '   • Đặc điểm: ${b.description ?? 'Form hiện đại, bám sàn tốt.'}\n\n'
              '👉 **Lời khuyên:** Nếu bạn ưu tiên ${_viCat(a.categoryName).toLowerCase()} thì chọn **${a.title}**, còn nếu thiên về ${_viCat(b.categoryName).toLowerCase()} thì **${b.title}** là lựa chọn tối ưu hơn!',
          products: [a, b].where((p) => !p.isDiscontinued).toList(),
        );
      }

      // Single product deep Q&A
      final p = directMatches.first;
      final eff = formatShopMoney(_effectivePrice(p), language: language);
      final orig = formatShopMoney(p.price, language: language);
      final pct = _discountPct(p);
      final sizes = (p.productAttributes
                  ?.where((a) => a.name?.toLowerCase() == 'size')
                  .firstOrNull
                  ?.values ??
              [])
          .join(', ');
      final colors = (p.productAttributes
                  ?.where((a) =>
                      a.name?.toLowerCase() == 'color' ||
                      _normalize(a.name ?? '').contains('mau'))
                  .firstOrNull
                  ?.values ??
              [])
          .join(', ');

      if (p.isDiscontinued) {
        final alternatives = poolProducts
            .where((x) => x.id != p.id && x.categoryId == p.categoryId)
            .take(3)
            .toList();
        return VeloraAiReply(
          text:
              '🚫 Mẫu **${p.title}** hiện **đã ngừng kinh doanh (Ngừng bán)** tại VELORA.\n\n'
              'Mình gợi ý cho bạn các mẫu cùng phân khúc **${_viCat(p.categoryName)}** mới nhất đang sẵn hàng để thay thế nhé:',
          products: alternatives,
        );
      }

      return VeloraAiReply(
        text: '👟 Thông tin chi tiết mẫu **${p.title}** (Dòng ${_viCat(p.categoryName)}):\n'
            '• **Giá bán:** $eff${pct > 0 ? ' (Giảm $pct% từ $orig)' : ''}\n'
            '• **Tồn kho:** ${p.stock > 0 ? 'Sẵn hàng (${p.stock} đôi)' : 'Tạm hết hàng'}\n'
            '${sizes.isNotEmpty ? '• **Size EU sẵn có:** $sizes\n' : ''}'
            '${colors.isNotEmpty ? '• **Phối màu:** $colors\n' : ''}'
            '• **Mô tả:** ${p.description ?? 'Đệm êm ái, thoáng khí, thiết kế chính hãng VELORA.'}\n\n'
            'Bạn có thể bấm trực tiếp vào thẻ sản phẩm bên dưới để xem video/ảnh góc nghiêng và chọn size nhé!',
        products: [p],
        followUpPrompts: [
          'Chân dài 26cm đi size mấy?',
          'Ship về Hà Nội mất mấy ngày?',
          'Có mã giảm giá / voucher nào hôm nay?',
        ],
      );
    }

    // =========================================================================
    // 10. GREETING / CONVERSATIONAL / IDENTITY QUESTIONS
    // =========================================================================
    if (norm.contains('ban la ai') ||
        norm.contains('ban ten gi') ||
        norm.contains('ai day') ||
        norm.contains('lam duoc gi') ||
        (RegExp(r'^(xin chao|chao|hello|hi|hey|alo)\b').hasMatch(norm) &&
            norm.length < 28)) {
      return VeloraAiReply(
        text: 'Xin chào! Mình là **Trợ lý AI thông minh của VELORA**.\n'
            'Bạn hỏi gì mình sẽ trả lời trực tiếp vấn đề đó:\n'
            '• **Tra cứu đơn hàng trực tiếp**: Kiểm tra đơn của bạn đang ở đâu, bao giờ giao, quy định hủy đơn.\n'
            '• **Hỗ trợ Đổi trả & Bảo hành**: Hướng dẫn đổi size EU 38–44, đổi mới 1-1, hoàn tiền hoặc kết nối **Chat 1-1 với nhân viên VELORA**.\n'
            '• **Tính size giày chuẩn**: Từ chiều dài chân (cm) hoặc chiều cao + cân nặng.\n'
            '• **Tư vấn chọn giày chuẩn gu & đúng tầm giá**: Chạy bộ, Hằng ngày, Tập gym, Bóng rổ, Địa hình.',
        showOrdersShortcut: true,
        showSupportChatShortcut: true,
        followUpPrompts: const [
          'Kiểm tra đơn hàng của tôi đến đâu rồi?',
          'Giày chạy bộ dưới 2.5 triệu',
          'Mình muốn đổi size / đổi trả giày thì làm thế nào?',
        ],
      );
    }

    if (norm.contains('cam on') ||
        norm.contains('thank') ||
        norm.contains('ok shop') ||
        norm.contains('tuyet voi')) {
      return VeloraAiReply(
        text:
            'Rất vui được hỗ trợ bạn! Nếu bạn cần kiểm tra đơn hàng, đổi size hay nhắn tin riêng với quản trị viên VELORA, cứ nhắn mình bất cứ lúc nào nhé ❤️',
        showSupportChatShortcut: true,
      );
    }

    // =========================================================================
    // 11. SPECIFIC USE-CASE & SYMPTOM CONSULTATION (Foot pain, standing long, weather, etc.)
    // =========================================================================
    final matchedCategories = <String>[];
    for (final entry in _categoryAliases.entries) {
      if (entry.value.any((alias) => norm.contains(alias))) {
        matchedCategories.add(entry.key);
      }
    }

    final matchedColors = <String>[];
    for (final entry in _colorAliases.entries) {
      if (entry.value.any((alias) => norm.contains(alias))) {
        matchedColors.add(entry.key);
      }
    }

    String? directAdviceHeader;
    if (norm.contains('dung lau') ||
        norm.contains('dau chan') ||
        norm.contains('dau got') ||
        norm.contains('moi chan') ||
        norm.contains('em nhat') ||
        norm.contains('di bo nhieu')) {
      if (matchedCategories.isEmpty) {
        matchedCategories.addAll(['Running', 'Lifestyle']);
      }
      directAdviceHeader =
          '💡 **Tư vấn cho người hay đứng lâu / đi bộ nhiều / cần đế cực êm:**\n'
          'Bạn nên ưu tiên dòng **Chạy bộ (Running)** hoặc **Hằng ngày (Lifestyle)** có đệm giữa NitroFoam / CloudFoam dày và cổ giày bọc đệm mềm để giảm áp lực lên gót chân & lòng bàn chân.';
    } else if (norm.contains('nhe nhat') || norm.contains('sieu nhe')) {
      if (matchedCategories.isEmpty) matchedCategories.add('Running');
      directAdviceHeader =
          '🪶 **Tư vấn dòng giày siêu nhẹ tại VELORA:**\n'
          'Các mẫu dòng **Chạy bộ (AeroMesh / CloudPace / AeroPulse)** có trọng lượng nhẹ nhất (chỉ ~210–240g/chiếc) nhờ thân lưới dệt thoáng khí.';
    } else if (norm.contains('quan jeans') ||
        norm.contains('quan au') ||
        norm.contains('cong so') ||
        norm.contains('di lam') ||
        norm.contains('di hoc') ||
        norm.contains('phoi do')) {
      if (matchedCategories.isEmpty) matchedCategories.add('Lifestyle');
      directAdviceHeader =
          '👔 **Tư vấn phối đồ đi học / đi làm / mặc quần Jeans & Kaki:**\n'
          'Dòng **Hằng ngày (Lifestyle)** cổ thấp với phom tối giản (tông Trắng, Kem hoặc Xanh rêu VELORA) là lựa chọn thanh lịch và dễ phối đồ nhất.';
    } else if (norm.contains('di mua') ||
        norm.contains('chong nuoc') ||
        norm.contains('chong tron') ||
        norm.contains('leo nui') ||
        norm.contains('phuot')) {
      if (matchedCategories.isEmpty) matchedCategories.add('Trail');
      directAdviceHeader =
          '🌧️ **Tư vấn giày đi mưa / chống trơn trượt / dã ngoại:**\n'
          'Bạn nên chọn dòng **Địa hình (Trail)** hoặc các mẫu tối màu có gai đế cao su bám đường ướt và bề mặt chống bám bẩn.';
    } else if (norm.contains('chan be') || norm.contains('mui chan to')) {
      directAdviceHeader =
          '🦶 **Tư vấn cho bàn chân bè ngang:**\n'
          'Bạn nên chọn các mẫu có thân vải dệt Knit co giãn hoặc lưới Engineered Mesh mềm và **tăng thêm 1 size EU** so với chiều dài chân để phần mũi luôn thoải mái.';
    }

    final size = _extractSize(norm);
    final (minBudgetUsd, maxBudgetUsd) = _extractPriceRangeUsd(norm);
    final wantsSale = norm.contains('sale') ||
        norm.contains('giam gia') ||
        norm.contains('uu dai') ||
        norm.contains('khuyen mai') ||
        norm.contains('discount');
    final wantsCheapest = norm.contains('re nhat') ||
        norm.contains('gia mem') ||
        norm.contains('tiet kiem') ||
        norm.contains('thap nhat') ||
        norm.contains('sinh vien');
    final wantsPremium = norm.contains('cao cap') ||
        norm.contains('dat nhat') ||
        norm.contains('xin nhat') ||
        norm.contains('flagship');
    final wantsBestSeller = norm.contains('ban chay') ||
        norm.contains('noi bat') ||
        norm.contains('hot nhat') ||
        norm.contains('dep nhat');

    final hasProductCriteria = matchedCategories.isNotEmpty ||
        matchedColors.isNotEmpty ||
        size != null ||
        minBudgetUsd != null ||
        maxBudgetUsd != null ||
        wantsSale ||
        wantsCheapest ||
        wantsPremium ||
        wantsBestSeller ||
        directAdviceHeader != null ||
        norm.contains('giay') ||
        norm.contains('doi nao') ||
        norm.contains('mau nao') ||
        norm.contains('goi y') ||
        norm.contains('tu van');

    // If the user typed a completely general question that doesn't ask for shoes,
    // answer their message directly and offer helpful actions instead of dumping random shoes!
    if (!hasProductCriteria) {
      return VeloraAiReply(
        text: 'Mình đã nhận câu hỏi của bạn: **"$trimmed"**.\n\n'
            'Tại VELORA, mình có thể hỗ trợ trực tiếp cho bạn các thông tin chính xác từ hệ thống:\n'
            '• **Kiểm tra đơn hàng & lộ trình giao từ Tổng Kho Hà Nội** (hoặc quy định hủy đơn khi còn Chờ xác nhận).\n'
            '• **Tạo yêu cầu Đổi size / Đổi mới 1-1 / Hoàn tiền** (chỉ cần điền Địa chỉ đổi mới).\n'
            '• **Nhắn tin riêng 1-1 với Quản trị viên VELORA** để được nhân viên hỗ trợ trực tiếp.\n'
            '• **Tìm giày theo đúng mục đích, màu sắc, size EU và ngân sách**.\n\n'
            'Bạn muốn mình kiểm tra mục nào ngay bây giờ, hay kết nối khung Chat 1-1 với nhân viên VELORA cho bạn nhé?',
        showSupportChatShortcut: true,
        showOrdersShortcut: true,
        showReturnsShortcut: true,
        followUpPrompts: const [
          'Kiểm tra đơn hàng của tôi đến đâu rồi?',
          'Mình muốn đổi size / đổi trả giày thì làm thế nào?',
          'Giày chạy bộ dưới 2.5 triệu',
        ],
      );
    }

    // Filter strictly by category, color, size, and budget when specified!
    var pool = List<ProductModel>.from(poolProducts);

    if (matchedCategories.isNotEmpty) {
      final catFiltered = pool
          .where((p) =>
              matchedCategories.any((c) => _productMatchesCategory(p, c)))
          .toList();
      if (catFiltered.isNotEmpty) {
        pool = catFiltered;
      }
    }

    if (matchedColors.isNotEmpty) {
      final colorFiltered = pool
          .where(
              (p) => matchedColors.any((c) => _productMatchesColor(p, c)))
          .toList();
      if (colorFiltered.isNotEmpty) {
        pool = colorFiltered;
      }
    }

    if (size != null) {
      final sizeFiltered = pool.where((p) {
        final hasVar = (p.productVariations ?? []).any(
          (v) =>
              v.stock > 0 &&
              v.attributeValues.values.any((val) => val.trim().contains(size)),
        );
        final hasAttr = p.productAttributes
                ?.where((a) => a.name?.toLowerCase() == 'size')
                .firstOrNull
                ?.values
                ?.any((v) => v.contains(size)) ??
            false;
        return hasVar || hasAttr;
      }).toList();
      if (sizeFiltered.isNotEmpty) {
        pool = sizeFiltered;
      }
    }

    bool budgetStrictMatched = true;
    if (minBudgetUsd != null || maxBudgetUsd != null) {
      final inBudget = pool.where((p) {
        final eff = _effectivePrice(p);
        if (minBudgetUsd != null && eff < minBudgetUsd) return false;
        if (maxBudgetUsd != null && eff > maxBudgetUsd) return false;
        return true;
      }).toList();
      if (inBudget.isNotEmpty) {
        pool = inBudget;
      } else {
        budgetStrictMatched = false;
      }
    }

    final tokens = norm
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 2)
        .toSet();

    final scored = <(ProductModel, int)>[];
    for (final p in pool) {
      var score = 0;
      final titleNorm = _normalize(p.title);
      final descNorm = _normalize(p.description ?? '');
      final pct = _discountPct(p);

      if (matchedCategories.isNotEmpty &&
          matchedCategories.any((c) => _productMatchesCategory(p, c))) {
        score += 20;
      }
      if (matchedColors.isNotEmpty &&
          matchedColors.any((c) => _productMatchesColor(p, c))) {
        score += 15;
      }
      if (wantsSale) {
        score += pct > 0 ? (15 + pct) : -10;
      }
      if (wantsBestSeller && p.isFeatured) {
        score += 10;
      }
      for (final token in tokens) {
        if (titleNorm.contains(token)) score += 6;
        if (descNorm.contains(token)) score += 3;
      }
      scored.add((p, score));
    }

    scored.sort((a, b) {
      if (wantsCheapest) {
        return _effectivePrice(a.$1).compareTo(_effectivePrice(b.$1));
      }
      if (wantsPremium) {
        return _effectivePrice(b.$1).compareTo(_effectivePrice(a.$1));
      }
      if (wantsSale) {
        final cmp = _discountPct(b.$1).compareTo(_discountPct(a.$1));
        if (cmp != 0) return cmp;
      }
      final scoreCmp = b.$2.compareTo(a.$2);
      if (scoreCmp != 0) return scoreCmp;
      return _effectivePrice(a.$1).compareTo(_effectivePrice(b.$1));
    });

    final picks = scored.take(4).map((e) => e.$1).toList();

    final matchedCategoryIds = picks
        .map((p) => p.categoryId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final trackedCats = matchedCategories.isNotEmpty
        ? matchedCategories
        : picks
            .map((p) => p.categoryName)
            .where((c) => c.isNotEmpty)
            .toSet()
            .take(2)
            .toList();
    _recordUserInterest(
      query: trimmed,
      categories: trackedCats,
      categoryIds: matchedCategoryIds,
      colors: matchedColors,
      maxBudgetUsd: maxBudgetUsd,
    );

    final criteria = <String>[];
    if (matchedCategories.isNotEmpty) {
      criteria.add(matchedCategories.map(_viCat).join(', '));
    }
    if (matchedColors.isNotEmpty) {
      criteria.add('màu ${matchedColors.map(_viColor).join(', ')}');
    }
    if (size != null) criteria.add('size EU $size');
    if (minBudgetUsd != null && maxBudgetUsd != null) {
      criteria.add(
        'từ ${formatShopMoney(minBudgetUsd, language: language)} đến ${formatShopMoney(maxBudgetUsd, language: language)}',
      );
    } else if (maxBudgetUsd != null) {
      criteria.add('dưới ${formatShopMoney(maxBudgetUsd, language: language)}');
    } else if (minBudgetUsd != null) {
      criteria.add('trên ${formatShopMoney(minBudgetUsd, language: language)}');
    }
    if (wantsSale) criteria.add('đang giảm giá sâu nhất');
    if (wantsCheapest) criteria.add('giá mềm nhất');
    if (wantsPremium) criteria.add('phân khúc cao cấp nhất');

    final buf = StringBuffer();
    if (directAdviceHeader != null) {
      buf.writeln(directAdviceHeader);
      buf.writeln();
    }

    if (!budgetStrictMatched && maxBudgetUsd != null) {
      buf.writeln(
        'Hiện tại các mẫu đúng dòng bạn chọn có mức giá nhỉnh hơn ${formatShopMoney(maxBudgetUsd, language: 'vi')} một chút — dưới đây là ${picks.length} mẫu có giá sát ngân sách của bạn nhất:',
      );
    } else if (criteria.isNotEmpty) {
      buf.writeln(
        'Mình đã lọc chính xác **${picks.length} mẫu VELORA** theo đúng yêu cầu **${criteria.join(' · ')}** của bạn:',
      );
    } else {
      buf.writeln(
        'Dưới đây là **${picks.length} mẫu giày VELORA** phù hợp nhất với yêu cầu của bạn:',
      );
    }

    for (final p in picks) {
      final eff = formatShopMoney(_effectivePrice(p), language: language);
      final pct = _discountPct(p);
      final saleNote = pct > 0 ? ' (đang giảm $pct%)' : '';
      buf.writeln(
        '• **${p.title}** (${_viCat(p.categoryName)}): **$eff**$saleNote',
      );
    }

    final followUps = <String>[
      if (picks.length >= 2) 'So sánh ${picks[0].title} và ${picks[1].title}',
      if (size == null) 'Chân dài 26cm đi size mấy?',
      'Ship về Hà Nội mất mấy ngày?',
    ].take(3).toList();

    return VeloraAiReply(
      text: buf.toString().trim(),
      products: picks,
      followUpPrompts: followUps,
    );
  }

  static String _viCat(String c) {
    final norm = _normalize(c);
    if (norm.contains('running') || norm.contains('chay')) return 'Chạy bộ';
    if (norm.contains('basketball') || norm.contains('bong ro')) {
      return 'Bóng rổ';
    }
    if (norm.contains('lifestyle') || norm.contains('hang ngay')) {
      return 'Hằng ngày';
    }
    if (norm.contains('training') || norm.contains('tap luyen')) {
      return 'Tập luyện';
    }
    if (norm.contains('trail') || norm.contains('dia hinh')) return 'Địa hình';
    return c;
  }

  static String _viColor(String c) => switch (c) {
        'White' => 'Trắng',
        'Black' => 'Đen',
        'Red' => 'Đỏ',
        'Blue' => 'Xanh dương',
        'Green' => 'Xanh rêu',
        'Grey' => 'Xám',
        'Cream' => 'Kem',
        'Pink' => 'Hồng',
        'Purple' => 'Tím',
        'Brown' => 'Nâu',
        'Orange' => 'Cam',
        'Yellow' => 'Vàng',
        _ => c,
      };

  Future<void> _recordUserInterest({
    required String query,
    required List<String> categories,
    required List<String> categoryIds,
    required List<String> colors,
    required double? maxBudgetUsd,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      var userName = user.displayName ?? '';
      var userEmail = user.email ?? '';
      if (Get.isRegistered<UserController>()) {
        final u = UserController.instance.user.value;
        if (u.fullName.trim().isNotEmpty) userName = u.fullName.trim();
        if (u.email.trim().isNotEmpty) userEmail = u.email.trim();
      }
      if (userName.isEmpty) {
        userName = userEmail.isNotEmpty
            ? userEmail.split('@').first
            : 'Khách hàng';
      }

      await _db.collection('UserInterests').doc(user.uid).set({
        'userId': user.uid,
        'userName': userName,
        'userEmail': userEmail,
        'lastQuery': query,
        'recentQueries': FieldValue.arrayUnion([query]),
        'interestedBrands': FieldValue.arrayUnion(['VELORA']),
        if (categories.isNotEmpty)
          'interestedCategories': FieldValue.arrayUnion(categories),
        if (categoryIds.isNotEmpty)
          'interestedCategoryIds': FieldValue.arrayUnion(categoryIds),
        if (colors.isNotEmpty)
          'interestedColors': FieldValue.arrayUnion(colors),
        if (maxBudgetUsd != null) 'lastMaxBudgetUsd': maxBudgetUsd,
        'queryCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (categoryIds.isNotEmpty) {
        await _db.collection('Users').doc(user.uid).set({
          'FavoriteCategoryIds': FieldValue.arrayUnion(categoryIds),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }
}
