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
  });

  final String text;
  final List<ProductModel> products;
  final bool showVoucherShortcut;
}

class VeloraAiService {
  VeloraAiService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  List<ProductModel>? _cachedProducts;

  Future<List<ProductModel>> _loadProducts() async {
    if (_cachedProducts != null && _cachedProducts!.isNotEmpty) {
      return _cachedProducts!;
    }
    try {
      final snap = await _db.collection('Products').get();
      _cachedProducts = snap.docs.map(ProductModel.fromSnapshot).toList();
      return _cachedProducts!;
    } catch (_) {
      return [];
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

  static const _categoryAliases = <String, List<String>>{
    'Running': ['chay bo', 'chay', 'running', 'marathon', 'jogging', 'the duc'],
    'Basketball': ['bong ro', 'basketball', 'san bong', 'court'],
    'Lifestyle': ['hang ngay', 'di choi', 'di hoc', 'di lam', 'lifestyle', 'street', 'thoi trang', 'casual'],
    'Training': ['tap luyen', 'gym', 'training', 'tap ta', 'fitness'],
    'Trail': ['dia hinh', 'leo nui', 'trail', 'outdoor', 'phuot'],
  };

  static const _colorAliases = <String, List<String>>{
    'White': ['trang', 'white'],
    'Black': ['den', 'black'],
    'Red': ['do', 'red'],
    'Blue': ['xanh duong', 'xanh bien', 'xanh', 'blue', 'navy'],
    'Green': ['xanh la', 'green', 'reu'],
    'Grey': ['xam', 'ghi', 'grey', 'gray'],
    'Cream': ['kem', 'be', 'beige', 'cream'],
    'Pink': ['hong', 'pink'],
    'Purple': ['tim', 'purple'],
    'Brown': ['nau', 'brown'],
    'Orange': ['cam', 'orange'],
    'Yellow': ['vang', 'yellow'],
  };

  double? _extractMaxBudgetUsd(String norm) {
    // Vietnamese million patterns: "duoi 3 trieu", "3tr", "2.5 trieu", "2,5tr"
    final trieuMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:trieu|tr)\b').firstMatch(norm);
    if (trieuMatch != null) {
      final val = double.tryParse(trieuMatch.group(1)!.replaceAll(',', '.'));
      if (val != null && val > 0) return (val * 1000000) / usdToVnd;
    }
    // Vietnamese k patterns: "1500k", "2000k"
    final kMatch = RegExp(r'(\d{3,4})\s*k\b').firstMatch(norm);
    if (kMatch != null) {
      final val = double.tryParse(kMatch.group(1)!);
      if (val != null && val >= 200) return (val * 1000) / usdToVnd;
    }
    // USD patterns: "$120", "120 usd", "under 150"
    final usdMatch = RegExp(r'(?:\$|usd\s*)(\d+(?:\.\d+)?)|(\d+(?:\.\d+)?)\s*(?:usd|\$)').firstMatch(norm);
    if (usdMatch != null) {
      final raw = usdMatch.group(1) ?? usdMatch.group(2);
      final val = double.tryParse(raw ?? '');
      if (val != null && val > 0) return val;
    }
    return null;
  }

  String? _extractSize(String norm) {
    final m = RegExp(r'(?:size|co|sz)\s*(3[5-9]|4[0-7])\b').firstMatch(norm);
    if (m != null) return m.group(1);
    return null;
  }

  Future<VeloraAiReply> ask(String query, {String language = 'vi'}) async {
    final trimmed = query.trim();
    final isEn = language == 'en';
    if (trimmed.isEmpty) {
      return VeloraAiReply(
        text: isEn
            ? 'Tell me what kind of sneakers you are looking for — brand, color, activity, or budget!'
            : 'Bạn đang tìm đôi giày như thế nào? Hãy nhắn thương hiệu, màu sắc, mục đích sử dụng hoặc tầm giá nhé!',
      );
    }

    final norm = _normalize(trimmed);

    // 1. Voucher inquiry
    if (norm.contains('voucher') ||
        norm.contains('ma giam') ||
        norm.contains('coupon') ||
        norm.contains('freeship') ||
        norm.contains('khuyen mai')) {
      final vouchers = await _loadActiveVouchers();
      if (vouchers.isEmpty) {
        return VeloraAiReply(
          text: isEn
              ? 'You can check welcome offers like WELCOME10 or FREESHIP directly in your Voucher Wallet!'
              : 'Bạn có thể xem ngay các ưu đãi thành viên mới như **WELCOME10** hoặc **FREESHIP** trong Ví Voucher nhé!',
          showVoucherShortcut: true,
        );
      }
      final lines = vouchers.take(4).map((v) {
        final code = v['code'] ?? '';
        final title = v['title'] ?? '';
        final shipping = v['shipping'] == true;
        final pct = v['percent'] ?? 0;
        final offer = shipping
            ? (isEn ? 'Free shipping' : 'Miễn phí vận chuyển')
            : (isEn ? '$pct% off' : 'Giảm $pct%');
        return '• **$code** — $offer ($title)';
      }).join('\n');
      return VeloraAiReply(
        text: isEn
            ? 'Here are the active VELORA vouchers you can apply at checkout:\n\n$lines'
            : 'Hiện tại VELORA đang có các mã ưu đãi khả dụng dành cho bạn:\n\n$lines\n\nNhấn nút bên dưới để mở Ví Voucher và áp dụng ngay nhé!',
        showVoucherShortcut: true,
      );
    }

    // 2. Load catalog & parse user intent
    final products = await _loadProducts();
    if (products.isEmpty) {
      return VeloraAiReply(
        text: isEn
            ? 'I couldn’t load the catalog right now. Please check your connection and try again.'
            : 'Hiện chưa tải được danh mục sản phẩm. Bạn vui lòng kiểm tra kết nối mạng và thử lại nhé.',
      );
    }

    // Detect brands dynamically from catalog
    final allBrands = products
        .map((p) => p.brand?.name.trim() ?? '')
        .where((b) => b.isNotEmpty)
        .toSet();
    final matchedBrands = <String>[];
    for (final brand in allBrands) {
      final bn = _normalize(brand);
      if (norm.contains(bn) || (bn == 'new balance' && RegExp(r'\bnb\b').hasMatch(norm))) {
        matchedBrands.add(brand);
      }
    }

    // Detect categories
    final matchedCategories = <String>[];
    for (final entry in _categoryAliases.entries) {
      if (entry.value.any((alias) => norm.contains(alias))) {
        matchedCategories.add(entry.key);
      }
    }

    // Detect colors
    final matchedColors = <String>[];
    for (final entry in _colorAliases.entries) {
      if (entry.value.any((alias) => norm.contains(alias))) {
        matchedColors.add(entry.key);
      }
    }

    final size = _extractSize(norm);
    final maxBudgetUsd = _extractMaxBudgetUsd(norm);
    final wantsSale = norm.contains('sale') || norm.contains('giam gia') || norm.contains('uu dai');
    final wantsCheap = norm.contains('re') || norm.contains('gia tot') || norm.contains('cheap');

    final tokens = norm
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 2)
        .toSet();

    // Score each product
    final scored = <(ProductModel, int)>[];
    for (final p in products) {
      var score = 0;
      final titleNorm = _normalize(p.title);
      final brandName = p.brand?.name ?? '';
      final brandNorm = _normalize(brandName);
      final catNorm = _normalize(p.categoryName);
      final effectivePrice = (p.salePrice > 0 && p.salePrice < p.price) ? p.salePrice : p.price;

      if (matchedBrands.isNotEmpty) {
        if (matchedBrands.any((b) => _normalize(b) == brandNorm)) {
          score += 12;
        } else {
          score -= 4;
        }
      }

      if (matchedCategories.isNotEmpty) {
        if (matchedCategories.any((c) => catNorm.contains(_normalize(c)))) {
          score += 10;
        } else {
          score -= 3;
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
        if (matchedColors.any((c) => pColors.contains(_normalize(c)) || titleNorm.contains(_normalize(c)))) {
          score += 8;
        }
      }

      if (size != null) {
        final hasSize = (p.productVariations ?? []).any((v) =>
                v.stock > 0 &&
                v.attributeValues.values.any((val) => val.trim() == size)) ||
            (p.productAttributes
                    ?.where((a) => a.name?.toLowerCase() == 'size')
                    .firstOrNull
                    ?.values
                    ?.contains(size) ??
                false);
        if (hasSize) score += 7;
      }

      if (maxBudgetUsd != null) {
        if (effectivePrice <= maxBudgetUsd) {
          score += 8;
        } else {
          score -= 8;
        }
      }

      final onSale = p.salePrice > 0 && p.salePrice < p.price;
      if (wantsSale) {
        score += onSale ? 12 : -5;
      }

      // Direct title/description token match
      for (final token in tokens) {
        if (titleNorm.contains(token)) score += 5;
        if (brandNorm.contains(token)) score += 3;
      }

      if (p.stock > 0) score += 2;
      if (p.isFeatured == true) score += 1;

      scored.add((p, score));
    }

    scored.sort((a, b) {
      if (wantsCheap && b.$2 == a.$2) {
        final pa = a.$1.salePrice > 0 ? a.$1.salePrice : a.$1.price;
        final pb = b.$1.salePrice > 0 ? b.$1.salePrice : b.$1.price;
        return pa.compareTo(pb);
      }
      return b.$2.compareTo(a.$2);
    });

    final hasSpecificConstraint = matchedBrands.isNotEmpty ||
        matchedCategories.isNotEmpty ||
        matchedColors.isNotEmpty ||
        size != null ||
        maxBudgetUsd != null ||
        wantsSale;

    var picks = scored
        .where((e) => hasSpecificConstraint ? e.$2 >= 5 : e.$2 > 0)
        .take(5)
        .map((e) => e.$1)
        .toList();

    if (picks.isEmpty) {
      // Fallback: show top 4 popular in-stock items
      picks = products.where((p) => p.stock > 0).take(4).toList();
    }

    // Track user interest for Admin insights & future product alerts
    final matchedCategoryIds = picks
        .map((p) => p.categoryId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final trackedBrands = matchedBrands.isNotEmpty
        ? matchedBrands
        : picks.map((p) => p.brand?.name ?? '').where((b) => b.isNotEmpty).toSet().take(2).toList();
    final trackedCats = matchedCategories.isNotEmpty
        ? matchedCategories
        : picks.map((p) => p.categoryName).where((c) => c.isNotEmpty).toSet().take(2).toList();

    // Non-blocking interest logging
    _recordUserInterest(
      query: trimmed,
      brands: trackedBrands,
      categories: trackedCats,
      categoryIds: matchedCategoryIds,
      colors: matchedColors,
      maxBudgetUsd: maxBudgetUsd,
    );

    // Craft helpful reply
    final summaryParts = <String>[];
    if (matchedBrands.isNotEmpty) summaryParts.add(matchedBrands.join(', '));
    if (matchedCategories.isNotEmpty) {
      summaryParts.add(matchedCategories.map((c) => isEn ? c : _viCat(c)).join(', '));
    }
    if (matchedColors.isNotEmpty) {
      summaryParts.add(isEn
          ? matchedColors.join(', ')
          : 'màu ${matchedColors.map(_viColor).join(', ')}');
    }
    if (size != null) summaryParts.add('size EU $size');
    if (maxBudgetUsd != null) {
      summaryParts.add(isEn
          ? 'under ${formatShopMoney(maxBudgetUsd, language: 'en')}'
          : 'dưới ${formatShopMoney(maxBudgetUsd, language: 'vi')}');
    }
    if (wantsSale) summaryParts.add(isEn ? 'on sale' : 'đang ưu đãi');

    final replyText = summaryParts.isNotEmpty
        ? (isEn
            ? 'I found ${picks.length} great matches for ${summaryParts.join(' · ')}. Tap any pair below to view sizes or buy right away!'
            : 'Mình tìm được ${picks.length} đôi phù hợp nhất theo tiêu chí **${summaryParts.join(' · ')}** dành cho bạn. Chạm vào sản phẩm bên dưới để xem size hoặc mua ngay nhé!')
        : (isEn
            ? 'Here are ${picks.length} standout pairs at VELORA right now. You can also ask by brand, color, size, or budget!'
            : 'Dưới đây là ${picks.length} mẫu giày nổi bật đang có tại VELORA. Bạn có thể hỏi cụ thể hơn theo hãng, màu sắc, size hoặc tầm giá nhé!');

    return VeloraAiReply(text: replyText, products: picks);
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
        'Green' => 'Xanh lá',
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
    required List<String> brands,
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
        if (brands.isNotEmpty) 'interestedBrands': FieldValue.arrayUnion(brands),
        if (categories.isNotEmpty) 'interestedCategories': FieldValue.arrayUnion(categories),
        if (categoryIds.isNotEmpty) 'interestedCategoryIds': FieldValue.arrayUnion(categoryIds),
        if (colors.isNotEmpty) 'interestedColors': FieldValue.arrayUnion(colors),
        if (maxBudgetUsd != null) 'lastBudgetUsd': maxBudgetUsd,
        'queryCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also sync matched categories to Users/{uid}.FavoriteCategoryIds for automatic new-product alerts
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
