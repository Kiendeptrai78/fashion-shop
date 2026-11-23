import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class VeloraAiReply {
  const VeloraAiReply({
    required this.text,
    this.products = const [],
    this.showVoucherShortcut = false,
    this.followUpPrompts = const [],
  });

  final String text;
  final List<ProductModel> products;
  final bool showVoucherShortcut;
  final List<String> followUpPrompts;
}

class VeloraAiService {
  VeloraAiService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  List<ProductModel>? _cachedProducts;
  DateTime? _cacheTime;

  /// Curated rotating library of 36+ diverse VELORA discovery ideas
  static const List<String> promptIdeasVi = [
    'Giày chạy bộ dưới 2.5 triệu',
    'Mẫu nào đang giảm giá sâu nhất?',
    'Giày trắng tối giản đi học & đi làm',
    'Chân dài 26cm đi size mấy?',
    'Đôi nào giá mềm nhất tại VELORA?',
    'Giày tập gym đế bám chắc',
    'Phối đồ với quần jeans nên chọn đôi nào?',
    'Giày bóng rổ bật nhảy êm cổ chân',
    'Giày leo núi địa hình chống trơn',
    'Gợi ý giày đi du lịch đi bộ cả ngày',
    'Tư vấn quà tặng giày cho người yêu',
    'Giày chân bè đi không bị đau mũi',
    'Mẫu nào hack dáng nhẹ cho cả nam nữ?',
    'Giày thoáng khí cho mùa hè không bí chân',
    'Tầm giá từ 2 đến 3 triệu có đôi nào đẹp?',
    'Giày màu đen dễ vệ sinh đi mưa',
    'Có mã giảm giá / voucher nào hôm nay?',
    'Cách vệ sinh giày trắng không bị ố vàng',
    'Chính sách đổi size & giao hàng VELORA',
    'Đôi nào nổi bật bán chạy nhất hiện tại?',
    'Giày màu xanh rêu signature của VELORA',
    'Đi chạy bộ 5km mỗi sáng chọn mẫu nào?',
    'Giày cặp đôi unisex phối đồ cực chất',
    'Mẫu nào trên 3 triệu dòng cao cấp nhất?',
  ];

  static const List<String> promptIdeasEn = [
    'Running shoes under \$100',
    'Biggest discounts right now?',
    'Minimal white sneakers for daily wear',
    '26cm foot length — what EU size?',
    'Most affordable VELORA pairs?',
    'Gym & HIIT stability trainers',
    'Best pair to style with jeans?',
    'Basketball shoes with ankle support',
    'Trail sneakers for outdoor hiking',
    'All-day walking & travel shoes',
    'Gift ideas for my partner',
    'Any active VELORA vouchers?',
    'How to clean white sneakers safely',
    'VELORA sizing & return policy',
  ];

  Future<List<ProductModel>> _loadProducts({bool forceRefresh = false}) async {
    final fresh = _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < const Duration(minutes: 2);
    if (!forceRefresh && fresh && _cachedProducts != null && _cachedProducts!.isNotEmpty) {
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
      final snap = await _db.collection('Vouchers').where('active', isEqualTo: true).get();
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
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a', 'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o', 'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u', 'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
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
      '5km', '10km', 'chay sang', 'chay duong dai', 'dem em', 'nhe chan',
    ],
    'Basketball': [
      'bong ro', 'basketball', 'san bong', 'court', 'bat nhay', 'co chan', 'co lung',
    ],
    'Lifestyle': [
      'hang ngay', 'di choi', 'di hoc', 'di lam', 'lifestyle', 'street', 'thoi trang',
      'casual', 'toi gian', 'minimal', 'quan jeans', 'phoi do', 'hen ho', 'cong so',
      'cap doi', 'unisex', 'hack dang', 'tang chieu cao', 'qua tang', 'tang nguoi yeu',
    ],
    'Training': [
      'tap luyen', 'gym', 'training', 'tap ta', 'fitness', 'hiit', 'cardio', 'de phang', 'bam san',
    ],
    'Trail': [
      'dia hinh', 'leo nui', 'trail', 'outdoor', 'phuot', 'du lich', 'di bo nhieu',
      'chong tron', 'di mua', 'da ngoai',
    ],
  };

  static const _colorAliases = <String, List<String>>{
    'White': ['trang', 'white', 'ngoc', 'tinh khoi'],
    'Black': ['den', 'black', 'than', 'obsidian'],
    'Red': ['do', 'red', 'do do', 'crimson'],
    'Blue': ['xanh duong', 'xanh bien', 'navy', 'blue', 'xanh bang'],
    'Green': ['xanh la', 'xanh reu', 'xanh rung', 'olive', 'sage', 'green', 'reu'],
    'Grey': ['xam', 'ghi', 'bac', 'grey', 'gray'],
    'Cream': ['kem', 'be', 'cat', 'beige', 'cream', 'sand'],
    'Pink': ['hong', 'pink'],
    'Purple': ['tim', 'purple'],
    'Brown': ['nau', 'brown', 'dat'],
    'Orange': ['cam', 'san ho', 'orange'],
    'Yellow': ['vang', 'yellow', 'dong'],
  };

  /// Parses budget range (minUsd, maxUsd) from Vietnamese or English text
  (double?, double?) _extractPriceRangeUsd(String norm) {
    // Range: "tu 2 den 3 trieu" / "2 - 3tr" / "2 den 3.5 trieu"
    final rangeTrieu = RegExp(
      r'(?:tu\s+)?(\d+(?:[.,]\d+)?)\s*(?:trieu|tr)?\s*(?:den|-|~|to)\s*(\d+(?:[.,]\d+)?)\s*(?:trieu|tr)\b',
    ).firstMatch(norm);
    if (rangeTrieu != null) {
      final lo = double.tryParse(rangeTrieu.group(1)!.replaceAll(',', '.'));
      final hi = double.tryParse(rangeTrieu.group(2)!.replaceAll(',', '.'));
      if (lo != null && hi != null && hi >= lo) {
        return ((lo * 1000000) / usdToVnd, (hi * 1000000) / usdToVnd);
      }
    }

    // "tren 3 trieu" / "hon 2.5tr"
    final minTrieu = RegExp(r'(?:tren|hon|tu|over|above)\s+(\d+(?:[.,]\d+)?)\s*(?:trieu|tr)\b')
        .firstMatch(norm);
    if (minTrieu != null) {
      final val = double.tryParse(minTrieu.group(1)!.replaceAll(',', '.'));
      if (val != null && val > 0) return ((val * 1000000) / usdToVnd, null);
    }

    // "duoi 3 trieu" / "tam 2.5tr" / "khoang 2 trieu" / "3tr"
    final maxTrieu = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:trieu|tr)\b').firstMatch(norm);
    if (maxTrieu != null) {
      final val = double.tryParse(maxTrieu.group(1)!.replaceAll(',', '.'));
      if (val != null && val > 0) {
        final usd = (val * 1000000) / usdToVnd;
        if (norm.contains('tam') || norm.contains('khoang') || norm.contains('around')) {
          return (usd * 0.78, usd * 1.18);
        }
        return (null, usd);
      }
    }

    // k patterns: "2000k", "1800k"
    final kMatch = RegExp(r'(\d{3,4})\s*k\b').firstMatch(norm);
    if (kMatch != null) {
      final val = double.tryParse(kMatch.group(1)!);
      if (val != null && val >= 200) return (null, (val * 1000) / usdToVnd);
    }

    // USD patterns: "$120", "under 100$"
    final usdMatch = RegExp(r'(?:\$|usd\s*)(\d+(?:\.\d+)?)|(\d+(?:\.\d+)?)\s*(?:usd|\$)')
        .firstMatch(norm);
    if (usdMatch != null) {
      final raw = usdMatch.group(1) ?? usdMatch.group(2);
      final val = double.tryParse(raw ?? '');
      if (val != null && val > 0) {
        if (norm.contains('over') || norm.contains('above') || norm.contains('tren')) {
          return (val, null);
        }
        return (null, val);
      }
    }
    return (null, null);
  }

  String? _extractSize(String norm) {
    final m = RegExp(r'(?:size|co|sz)\s*(3[6-9]|4[0-6])\b').firstMatch(norm);
    return m?.group(1);
  }

  double? _extractFootLengthCm(String norm) {
    final m = RegExp(r'(\d{2}(?:[.,]\d)?)\s*cm\b').firstMatch(norm);
    if (m == null) return null;
    final val = double.tryParse(m.group(1)!.replaceAll(',', '.'));
    if (val != null && val >= 21.5 && val <= 31.0) return val;
    return null;
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

  Future<VeloraAiReply> ask(String query, {String language = 'vi'}) async {
    final trimmed = query.trim();
    final isEn = language == 'en';
    if (trimmed.isEmpty) {
      return VeloraAiReply(
        text: isEn
            ? 'Tell me how you plan to wear your next VELORA pair — running, gym, daily style, foot length, or budget!'
            : 'Bạn đang tìm mẫu giày VELORA cho dịp nào? Hãy nhắn mục đích sử dụng, màu sắc, tầm giá hoặc chiều dài bàn chân để mình tư vấn chính xác nhất nhé!',
      );
    }

    final norm = _normalize(trimmed);

    // -------------------------------------------------------------------------
    // 1. Greeting / About VELORA
    // -------------------------------------------------------------------------
    if (RegExp(r'^(xin chao|chao|hello|hi|hey|alo)\b').hasMatch(norm) && norm.length < 24) {
      final products = await _loadProducts();
      final highlights = products.where((p) => p.isFeatured && p.stock > 0).take(3).toList();
      return VeloraAiReply(
        text: isEn
            ? 'Welcome to VELORA! I can recommend sneakers by activity, exact budget, color, EU size (even from foot length in cm), outfit matching, or care tips. Here are 3 standout VELORA designs today:'
            : 'Chào bạn đến với VELORA! Mình có thể giúp bạn:\n'
                '• Lọc giày VELORA chuẩn theo ngân sách & mục đích (chạy bộ, gym, bóng rổ, hằng ngày, địa hình)\n'
                '• Tính size EU chuẩn từ chiều dài bàn chân (cm)\n'
                '• Tư vấn phối đồ, chọn quà tặng & kiểm tra mã ưu đãi hôm nay\n\n'
                'Dưới đây là 3 mẫu VELORA đang được yêu thích nhất:',
        products: highlights,
        followUpPrompts: const [
          'Mẫu nào đang giảm giá sâu nhất?',
          'Chân dài 26cm đi size mấy?',
          'Giày chạy bộ dưới 2.5 triệu',
        ],
      );
    }

    if (norm.contains('velora la gi') ||
        norm.contains('ve velora') ||
        norm.contains('thuong hieu velora') ||
        norm.contains('about velora')) {
      final products = await _loadProducts();
      return VeloraAiReply(
        text: isEn
            ? 'VELORA is our independent athletic footwear studio crafting minimalist, high-performance sneakers across 5 lines: Running, Lifestyle, Training, Basketball, and Trail — all engineered for everyday comfort and modern silhouette.'
            : 'VELORA là thương hiệu giày thể thao thiết kế độc quyền với triết lý **tối giản · chuẩn công thái học · bền bỉ mỗi ngày**. Bộ sưu tập hiện có 5 dòng chuyên biệt: Chạy bộ, Hằng ngày, Tập luyện, Bóng rổ và Địa hình — tất cả đều thiết kế riêng với bảng màu xanh rừng & trung tính sang trọng.',
        products: products.where((p) => p.stock > 0).take(4).toList(),
        followUpPrompts: const [
          'Đôi nào nổi bật bán chạy nhất hiện tại?',
          'Giày trắng tối giản đi học & đi làm',
          'Có mã giảm giá / voucher nào hôm nay?',
        ],
      );
    }

    // -------------------------------------------------------------------------
    // 2. Shoe Care / Cleaning Advice
    // -------------------------------------------------------------------------
    if (norm.contains('ve sinh') ||
        norm.contains('giat giay') ||
        norm.contains('bao quan') ||
        norm.contains('o vang') ||
        norm.contains('clean') ||
        norm.contains('wash')) {
      return VeloraAiReply(
        text: isEn
            ? 'VELORA Sneaker Care Guide:\n'
                '• Remove laces & insoles before cleaning.\n'
                '• Use a soft brush + mild soap & cold water (avoid bleach and washing machines).\n'
                '• For white sneakers: wrap in dry tissue paper while air-drying in shade to prevent yellowing.\n'
                '• For suede/knit: dry-brush gently and use a waterproof spray before rainy days.'
            : 'Mẹo vệ sinh & giữ form giày VELORA luôn như mới:\n'
                '1. Tháo dây và lót giày giặt riêng với nước mát + xà phòng dịu nhẹ.\n'
                '2. Dùng bàn chải lông mềm chà nhẹ theo 1 chiều — tuyệt đối không bỏ máy giặt hoặc ngâm chất tẩy mạnh.\n'
                '3. Chống ố vàng cho giày trắng: bọc kín giấy ăn khô quanh thân giày rồi phơi nơi râm gió (tránh nắng gắt trực tiếp).\n'
                '4. Nhét giấy báo hoặc shoe-tree bên trong để giữ chuẩn form mũi giày.',
        followUpPrompts: const [
          'Giày màu đen dễ vệ sinh đi mưa',
          'Giày trắng tối giản đi học & đi làm',
          'Chính sách đổi size & giao hàng VELORA',
        ],
      );
    }

    // -------------------------------------------------------------------------
    // 3. Shipping, Returns, Exchange & Warranty Policy
    // -------------------------------------------------------------------------
    if (norm.contains('doi size') ||
        norm.contains('doi tra') ||
        norm.contains('bao hanh') ||
        norm.contains('ship mat bao lau') ||
        norm.contains('giao hang') ||
        norm.contains('return') ||
        norm.contains('shipping')) {
      return VeloraAiReply(
        text: isEn
            ? 'VELORA Shopping Policy:\n'
                '• Delivery: 2–3 business days nationwide with live order tracking.\n'
                '• Size Exchange: Free size exchange within 7 days for unworn pairs in original box.\n'
                '• Warranty: 6-month sole & stitching warranty on all authentic VELORA footwear.'
            : 'Chính sách mua sắm tại VELORA:\n'
                '• Giao hàng nhanh 2–3 ngày toàn quốc, theo dõi trực tiếp từng chặng trong mục Đơn hàng.\n'
                '• Hỗ trợ đổi size dễ dàng trong vòng 7 ngày nếu giày chưa qua sử dụng ngoài trời.\n'
                '• Bảo hành keo & đường may 6 tháng cho toàn bộ sản phẩm VELORA chính hãng.',
        followUpPrompts: const [
          'Chân dài 26cm đi size mấy?',
          'Có mã giảm giá / voucher nào hôm nay?',
          'Đôi nào giá mềm nhất tại VELORA?',
        ],
      );
    }

    // -------------------------------------------------------------------------
    // 4. Vouchers / Promotions
    // -------------------------------------------------------------------------
    if (norm.contains('voucher') ||
        norm.contains('ma giam') ||
        norm.contains('coupon') ||
        norm.contains('freeship')) {
      final vouchers = await _loadActiveVouchers();
      final products = await _loadProducts();
      final salePicks = products.where((p) => _discountPct(p) > 0 && p.stock > 0).take(3).toList();
      if (vouchers.isEmpty) {
        return VeloraAiReply(
          text: isEn
              ? 'Open your VELORA Voucher Wallet to claim welcome & holiday offers (like WELCOME10 and SHIPNEW) at checkout!'
              : 'Bạn hãy mở ngay Ví Voucher của VELORA để nhận mã chào mừng thành viên mới (WELCOME10, SHIPNEW) và các ưu đãi dịp lễ đang có sẵn nhé!',
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
        final offer = shipping
            ? (isEn ? 'Free shipping' : 'Miễn phí vận chuyển')
            : (isEn ? '$pct% off' : 'Giảm $pct%');
        final minLabel = minUsd > 0
            ? (isEn
                ? ' (min ${formatShopMoney(minUsd, language: 'en')})'
                : ' (đơn từ ${formatShopMoney(minUsd, language: 'vi')})')
            : '';
        return '• $code — $offer$minLabel: $title';
      }).join('\n');
      return VeloraAiReply(
        text: isEn
            ? 'Active VELORA vouchers right now:\n\n$lines\n\nTap below to open your Voucher Wallet!'
            : 'Các mã ưu đãi VELORA đang hoạt động hôm nay:\n\n$lines\n\nChạm nút bên dưới để mở Ví Voucher và áp dụng khi thanh toán nhé!',
        products: salePicks,
        showVoucherShortcut: true,
        followUpPrompts: const [
          'Mẫu nào đang giảm giá sâu nhất?',
          'Đôi nào giá mềm nhất tại VELORA?',
        ],
      );
    }

    // -------------------------------------------------------------------------
    // 5. Foot Length (cm) → EU Size Calculator + Matching Stock!
    // -------------------------------------------------------------------------
    final footCm = _extractFootLengthCm(norm);
    final products = await _loadProducts();
    if (products.isEmpty) {
      return VeloraAiReply(
        text: isEn
            ? 'I couldn’t load the VELORA catalog right now. Please check your connection and try again.'
            : 'Hiện chưa tải được danh mục giày VELORA. Bạn kiểm tra kết nối mạng và thử lại giúp mình nhé.',
      );
    }

    if (footCm != null) {
      final eu = _euFromCm(footCm);
      final wideFoot = norm.contains('be') || norm.contains('rong') || norm.contains('wide');
      final recommendedEu = wideFoot ? min(45, eu + 1) : eu;
      final sizeStr = '$recommendedEu';
      final inSize = products.where((p) {
        if (p.stock <= 0) return false;
        final hasVar = (p.productVariations ?? []).any(
          (v) => v.stock > 0 && v.attributeValues.values.any((val) => val.trim() == sizeStr),
        );
        final hasAttr = p.productAttributes
                ?.where((a) => a.name?.toLowerCase() == 'size')
                .firstOrNull
                ?.values
                ?.contains(sizeStr) ??
            false;
        return hasVar || hasAttr;
      }).take(5).toList();

      return VeloraAiReply(
        text: isEn
            ? 'For a ${footCm.toStringAsFixed(1)} cm foot${wideFoot ? ' (wide fit)' : ''}, your ideal VELORA size is EU $recommendedEu. Here are ${inSize.length} VELORA pairs currently in stock in EU $recommendedEu:'
            : 'Với chiều dài bàn chân ${footCm.toStringAsFixed(1)} cm${wideFoot ? ' (form chân bè, đã cộng +1 size cho thoải mái)' : ''}, size chuẩn VELORA dành cho bạn là **EU $recommendedEu** (nếu chân bè ngang bạn có thể cân nhắc tăng 0.5–1 size).\n\n'
                'Dưới đây là ${inSize.length} mẫu VELORA đang sẵn size EU $recommendedEu trong kho:',
        products: inSize.isNotEmpty ? inSize : products.take(4).toList(),
        followUpPrompts: [
          'Giày chạy bộ size $recommendedEu',
          'Giày trắng size $recommendedEu dưới 3 triệu',
          'Chính sách đổi size & giao hàng VELORA',
        ],
      );
    }

    // -------------------------------------------------------------------------
    // 6. Direct Product Price / Detail Lookup or Comparison
    // -------------------------------------------------------------------------
    final directMatches = products.where((p) {
      final t = _normalize(p.title).replaceFirst('velora ', '').trim();
      if (t.length < 3) return false;
      return norm.contains(t) ||
          t.split(' ').where((w) => w.length >= 4).any((w) => norm.contains(w));
    }).toList();

    if (directMatches.length >= 2 && (norm.contains('so sanh') || norm.contains('compare') || norm.contains('hay'))) {
      final a = directMatches[0];
      final b = directMatches[1];
      final pa = formatShopMoney(_effectivePrice(a), language: language);
      final pb = formatShopMoney(_effectivePrice(b), language: language);
      return VeloraAiReply(
        text: isEn
            ? 'Comparing ${a.title} vs ${b.title}:\n'
                '• ${a.title} (${a.categoryName}): $pa — ${a.stock} pairs in stock.\n'
                '• ${b.title} (${b.categoryName}): $pb — ${b.stock} pairs in stock.\n'
                'Tap either pair below to check exact colors & sizes!'
            : 'So sánh nhanh 2 mẫu VELORA bạn đang cân nhắc:\n'
                '• ${a.title} (${_viCat(a.categoryName)}): giá chuẩn $pa · còn ${a.stock} đôi trong kho.\n'
                '• ${b.title} (${_viCat(b.categoryName)}): giá chuẩn $pb · còn ${b.stock} đôi trong kho.\n\n'
                'Nếu ưu tiên ${_viCat(a.categoryName).toLowerCase()} hãy chọn ${a.title}, còn thiên về ${_viCat(b.categoryName).toLowerCase()} thì ${b.title} sẽ tối ưu hơn!',
        products: [a, b],
      );
    }

    if (directMatches.length == 1 && (norm.contains('gia') || norm.contains('bao nhieu') || norm.contains('price') || norm.contains('con hang'))) {
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
      return VeloraAiReply(
        text: isEn
            ? '${p.title} (${p.categoryName}):\n'
                '• Current price: $eff${pct > 0 ? ' (-$pct% off from $orig)' : ''}\n'
                '• Stock: ${p.stock} pairs available${sizes.isNotEmpty ? ' · Sizes: EU $sizes' : ''}'
            : 'Thông tin chính xác cho **${p.title}** (${_viCat(p.categoryName)}):\n'
                '• Giá bán hiện tại: $eff${pct > 0 ? ' (đang giảm $pct% từ $orig)' : ''}\n'
                '• Tình trạng kho: ${p.stock > 0 ? 'Còn ${p.stock} đôi' : 'Tạm hết hàng'}${sizes.isNotEmpty ? ' · Size EU: $sizes' : ''}\n'
                'Chạm vào thẻ bên dưới để chọn màu và đặt mua ngay nhé!',
        products: [p],
      );
    }

    // -------------------------------------------------------------------------
    // 7. Smart Multi-Criteria Sneaker Recommendation Engine (100+ scenarios)
    // -------------------------------------------------------------------------
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
        norm.contains('affordable') ||
        norm.contains('cheapest') ||
        norm.contains('sinh vien');
    final wantsPremium = norm.contains('cao cap') ||
        norm.contains('dat nhat') ||
        norm.contains('xin nhat') ||
        norm.contains('flagship') ||
        norm.contains('premium');
    final wantsBestSeller = norm.contains('ban chay') ||
        norm.contains('noi bat') ||
        norm.contains('hot nhat') ||
        norm.contains('dep nhat') ||
        norm.contains('popular');

    // Context-aware style advice snippets (makes AI feel rich & human!)
    String? lifestyleTip;
    if (norm.contains('quan jeans') || norm.contains('phoi do') || norm.contains('outfit')) {
      lifestyleTip = isEn
          ? 'Styling tip: Clean low-top silhouettes in white, cream, or forest accents pair effortlessly with slim/straight jeans and chinos.'
          : 'Gợi ý phối đồ: Form cổ thấp gọn gàng tông Trắng, Kem hoặc nhấn Xanh rêu cực kỳ dễ phối với quần jeans ống đứng, quần kaki hay jogger.';
    } else if (norm.contains('chan be') || norm.contains('dau mui') || norm.contains('wide')) {
      lifestyleTip = isEn
          ? 'Wide-foot tip: Breathable knit uppers with flexible toe-boxes give instant comfort without pinching.'
          : 'Mẹo cho chân bè: Ưu tiên thân giày dệt knit co giãn hoặc mũi tròn thoáng, chọn tăng 0.5–1 size sẽ cực kỳ êm mũi chân.';
    } else if (norm.contains('qua tang') || norm.contains('nguoi yeu') || norm.contains('sinh nhat') || norm.contains('gift')) {
      lifestyleTip = isEn
          ? 'Gift tip: Neutral lifestyle colorways (white/cream/sage) are the safest crowd-pleasers — and VELORA supports free 7-day size exchange!'
          : 'Gợi ý chọn quà: Các tông màu trung tính (Trắng, Kem, Xanh rêu) dễ mang nhất cho mọi phong cách — VELORA còn hỗ trợ đổi size trong 7 ngày nếu chưa vừa!';
    } else if (norm.contains('di mua') || norm.contains('de ve sinh')) {
      lifestyleTip = isEn
          ? 'Rain-ready tip: Dark obsidian/slate uppers with rugged outsoles resist splashes and wipe clean in seconds.'
          : 'Mẹo đi mưa: Các mẫu tông Đen / Xám đậm hoặc dòng địa hình chống trượt giúp ít bám bẩn và cực dễ lau sạch sau khi đi mưa.';
    } else if (norm.contains('mua he') || norm.contains('thoang khi') || norm.contains('khong bi')) {
      lifestyleTip = isEn
          ? 'Summer tip: Engineered mesh running & knit uppers maximize airflow so feet stay cool all day.'
          : 'Mẹo mùa hè: Các mẫu thân lưới engineered mesh & dệt knit siêu thoáng giúp thoát nhiệt nhanh, đi cả ngày không bị bí chân.';
    } else if (norm.contains('hack dang') || norm.contains('chieu cao')) {
      lifestyleTip = isEn
          ? 'Height-boost tip: Sculpted foam midsoles add a subtle 3–4cm lift while staying featherlight.'
          : 'Mẹo hack dáng: Đế giữa đúc foam nguyên khối giúp tăng chiều cao tự nhiên 3–4cm mà vẫn cực nhẹ chân.';
    }

    final tokens = norm
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 2)
        .toSet();

    // Filter strictly by budget first if budget was explicitly specified
    var pool = products.where((p) => p.stock > 0).toList();
    if (pool.isEmpty) pool = products.toList();

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

    // Score remaining products accurately
    final scored = <(ProductModel, int)>[];
    for (final p in pool) {
      var score = 0;
      final titleNorm = _normalize(p.title);
      final catNorm = _normalize(p.categoryName);
      final descNorm = _normalize(p.description ?? '');
      final pct = _discountPct(p);

      if (matchedCategories.isNotEmpty) {
        if (matchedCategories.any((c) => catNorm.contains(_normalize(c)))) {
          score += 14;
        } else {
          score -= 4;
        }
      }

      if (matchedColors.isNotEmpty) {
        final pColors = (p.productAttributes
                    ?.where((a) => a.name?.toLowerCase() == 'color')
                    .firstOrNull
                    ?.values ??
                [])
            .map(_normalize)
            .join(' ');
        if (matchedColors.any(
          (c) => pColors.contains(_normalize(c)) || titleNorm.contains(_normalize(c)),
        )) {
          score += 10;
        }
      }

      if (size != null) {
        final hasSize = (p.productVariations ?? []).any(
              (v) => v.stock > 0 && v.attributeValues.values.any((val) => val.trim() == size),
            ) ||
            (p.productAttributes
                    ?.where((a) => a.name?.toLowerCase() == 'size')
                    .firstOrNull
                    ?.values
                    ?.contains(size) ??
                false);
        if (hasSize) score += 9;
      }

      if (wantsSale) {
        score += pct > 0 ? (10 + pct) : -8;
      }
      if (wantsBestSeller && p.isFeatured) {
        score += 6;
      }

      for (final token in tokens) {
        if (titleNorm.contains(token)) score += 6;
        if (descNorm.contains(token)) score += 2;
      }

      if (p.stock > 0) score += 2;
      scored.add((p, score));
    }

    scored.sort((a, b) {
      if (wantsCheapest) {
        final cmp = _effectivePrice(a.$1).compareTo(_effectivePrice(b.$1));
        if (cmp != 0) return cmp;
      }
      if (wantsPremium) {
        final cmp = _effectivePrice(b.$1).compareTo(_effectivePrice(a.$1));
        if (cmp != 0) return cmp;
      }
      if (wantsSale) {
        final cmp = _discountPct(b.$1).compareTo(_discountPct(a.$1));
        if (cmp != 0) return cmp;
      }
      final scoreCmp = b.$2.compareTo(a.$2);
      if (scoreCmp != 0) return scoreCmp;
      return _effectivePrice(a.$1).compareTo(_effectivePrice(b.$1));
    });

    final picks = scored.take(5).map((e) => e.$1).toList();

    // Record user interest in Firestore for Admin Web insights & restock alerts
    final matchedCategoryIds = picks
        .map((p) => p.categoryId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final trackedCats = matchedCategories.isNotEmpty
        ? matchedCategories
        : picks.map((p) => p.categoryName).where((c) => c.isNotEmpty).toSet().take(2).toList();
    _recordUserInterest(
      query: trimmed,
      categories: trackedCats,
      categoryIds: matchedCategoryIds,
      colors: matchedColors,
      maxBudgetUsd: maxBudgetUsd,
    );

    // Build accurate, dynamic, price-verified response!
    final criteria = <String>[];
    if (matchedCategories.isNotEmpty) {
      criteria.add(matchedCategories.map((c) => isEn ? c : _viCat(c)).join(', '));
    }
    if (matchedColors.isNotEmpty) {
      criteria.add(isEn ? matchedColors.join(', ') : 'màu ${matchedColors.map(_viColor).join(', ')}');
    }
    if (size != null) criteria.add('size EU $size');
    if (minBudgetUsd != null && maxBudgetUsd != null) {
      criteria.add(
        '${formatShopMoney(minBudgetUsd, language: language)} – ${formatShopMoney(maxBudgetUsd, language: language)}',
      );
    } else if (maxBudgetUsd != null) {
      criteria.add('${isEn ? 'under' : 'dưới'} ${formatShopMoney(maxBudgetUsd, language: language)}');
    } else if (minBudgetUsd != null) {
      criteria.add('${isEn ? 'over' : 'trên'} ${formatShopMoney(minBudgetUsd, language: language)}');
    }
    if (wantsSale) criteria.add(isEn ? 'best discounts' : 'giảm giá tốt nhất');
    if (wantsCheapest) criteria.add(isEn ? 'best value' : 'giá mềm nhất');
    if (wantsPremium) criteria.add(isEn ? 'flagship tier' : 'dòng cao cấp');

    final buf = StringBuffer();
    if (!budgetStrictMatched && maxBudgetUsd != null) {
      buf.writeln(
        isEn
            ? 'Currently our closest VELORA pairs start slightly above ${formatShopMoney(maxBudgetUsd, language: 'en')} — here are the best-priced matches:'
            : 'Hiện tại các mẫu VELORA có giá khởi điểm nhỉnh hơn ${formatShopMoney(maxBudgetUsd, language: 'vi')} một chút — mình gợi ý những đôi giá tốt sát ngân sách nhất cho bạn:',
      );
    } else if (criteria.isNotEmpty) {
      buf.writeln(
        isEn
            ? 'Here are the top ${picks.length} VELORA matches for ${criteria.join(' · ')}:'
            : 'Mình đã lọc ra ${picks.length} mẫu VELORA chuẩn nhất theo tiêu chí ${criteria.join(' · ')}:',
      );
    } else {
      buf.writeln(
        isEn
            ? 'Here are ${picks.length} standout VELORA designs ready to ship:'
            : 'Dưới đây là ${picks.length} mẫu giày VELORA nổi bật đang sẵn hàng:',
      );
    }

    for (final p in picks.take(3)) {
      final eff = formatShopMoney(_effectivePrice(p), language: language);
      final pct = _discountPct(p);
      final saleNote = pct > 0 ? ' (-$pct%)' : '';
      buf.writeln('• ${p.title} (${isEn ? p.categoryName : _viCat(p.categoryName)}): $eff$saleNote');
    }

    if (lifestyleTip != null) {
      buf.writeln('\n$lifestyleTip');
    }

    final followUps = <String>[
      if (size == null) 'Chân dài 26cm đi size mấy?',
      if (!wantsSale) 'Mẫu nào đang giảm giá sâu nhất?',
      if (picks.length >= 2) 'So sánh ${picks[0].title} và ${picks[1].title}',
      'Có mã giảm giá / voucher nào hôm nay?',
    ].take(3).toList();

    return VeloraAiReply(
      text: buf.toString().trim(),
      products: picks,
      followUpPrompts: followUps,
    );
  }

  static String _viCat(String c) => switch (c) {
        'Running' => 'Chạy bộ',
        'Basketball' => 'Bóng rổ',
        'Lifestyle' => 'Hằng ngày',
        'Training' => 'Tập luyện',
        'Trail' => 'Địa hình',
        _ => c,
      };

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
    double? maxBudgetUsd,
  }) async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) return;
      final uid = authUser.uid;
      final userName = Get.isRegistered<UserController>() &&
              UserController.instance.user.value.fullName.trim().isNotEmpty
          ? UserController.instance.user.value.fullName.trim()
          : (authUser.displayName ?? authUser.email ?? 'Khách hàng');
      final userEmail = authUser.email ?? '';

      final ref = _db.collection('UserInterests').doc(uid);
      await ref.set({
        'userId': uid,
        'userName': userName,
        'userEmail': userEmail,
        'lastQuery': query,
        'recentQueries': FieldValue.arrayUnion([query]),
        'interestedBrands': FieldValue.arrayUnion(['VELORA']),
        if (categories.isNotEmpty) 'interestedCategories': FieldValue.arrayUnion(categories),
        if (categoryIds.isNotEmpty) 'interestedCategoryIds': FieldValue.arrayUnion(categoryIds),
        if (colors.isNotEmpty) 'interestedColors': FieldValue.arrayUnion(colors),
        if (maxBudgetUsd != null) 'lastBudgetUsd': maxBudgetUsd,
        'queryCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (categoryIds.isNotEmpty) {
        await _db.collection('Users').doc(uid).set({
          'FavoriteCategoryIds': FieldValue.arrayUnion(categoryIds),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Non-blocking analytics write.
    }
  }
}
