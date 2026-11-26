import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/features/authentication/models/user_model.dart';
import 'package:fashion_business_app/features/shop/models/banner_model.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/product_review_model.dart';

enum AdminSection {
  dashboard,
  finance,
  orders,
  returns,
  supportChat,
  products,
  featured,
  vouchers,
  brands,
  categories,
  banners,
  users,
  reviews,
  notifications,
}

enum FinancePeriod { last7Days, last6Months, last12Months }

enum AdminTimeFilter {
  today,
  yesterday,
  last7Days,
  thisMonth,
  customMonth,
  allTime,
  customDate,
}

class AdminSoldProductSummary {
  const AdminSoldProductSummary({
    required this.productId,
    required this.title,
    required this.thumbnail,
    required this.quantitySold,
    required this.orderCount,
    required this.grossRevenueUsd,
    required this.variationsSummary,
  });

  final String productId;
  final String title;
  final String thumbnail;
  final int quantitySold;
  final int orderCount;
  final double grossRevenueUsd;
  final String variationsSummary;
}

enum CustomerSegment {
  vip,
  loyal,
  newMember,
  bomHang,
  admin,
}

class CustomerProfileStats {
  const CustomerProfileStats({
    required this.user,
    required this.segment,
    required this.totalOrders,
    required this.receivedOrders,
    required this.cancelledOrders,
    required this.activeOrders,
    required this.totalSpent,
  });

  final UserModel user;
  final CustomerSegment segment;
  final int totalOrders;
  final int receivedOrders;
  final int cancelledOrders;
  final int activeOrders;
  final double totalSpent;

  double get cancelRate => totalOrders == 0 ? 0.0 : cancelledOrders / totalOrders;
}

class AdminStockReceipt {
  const AdminStockReceipt({
    required this.id,
    required this.productId,
    required this.productTitle,
    this.productThumbnail = '',
    required this.addedQuantity,
    required this.previousStock,
    required this.newStock,
    this.unitCostUsd = 0,
    this.supplier = '',
    this.note = '',
    this.variationDeltas = const {},
    this.createdAt,
  });

  final String id;
  final String productId;
  final String productTitle;
  final String productThumbnail;
  final int addedQuantity;
  final int previousStock;
  final int newStock;
  final double unitCostUsd;
  final String supplier;
  final String note;
  final Map<String, int> variationDeltas;
  final DateTime? createdAt;

  factory AdminStockReceipt.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawDeltas = data['variationDeltas'];
    final deltas = <String, int>{};
    if (rawDeltas is Map) {
      rawDeltas.forEach((k, v) {
        deltas[k.toString()] = (v as num? ?? 0).toInt();
      });
    }
    return AdminStockReceipt(
      id: doc.id,
      productId: (data['productId'] ?? '').toString(),
      productTitle: (data['productTitle'] ?? '').toString(),
      productThumbnail: (data['productThumbnail'] ?? '').toString(),
      addedQuantity: (data['addedQuantity'] as num? ?? 0).toInt(),
      previousStock: (data['previousStock'] as num? ?? 0).toInt(),
      newStock: (data['newStock'] as num? ?? 0).toInt(),
      unitCostUsd: (data['unitCostUsd'] as num? ?? 0).toDouble(),
      supplier: (data['supplier'] ?? '').toString(),
      note: (data['note'] ?? '').toString(),
      variationDeltas: deltas,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class AdminAutomationSettings {
  const AdminAutomationSettings({
    this.autoWelcomeVoucher = true,
    this.welcomePercent = 10,
    this.welcomeDays = 30,
    this.autoHolidayVoucher = true,
    this.holidayPercent = 15,
    this.holidayDays = 7,
    this.autoVipVoucher = true,
    this.vipPercent = 20,
    this.vipDays = 14,
    this.autoReviewReply = true,
    this.replyTemplateHigh =
        'Cảm ơn {name} đã tin tưởng và đánh giá {stars}★ cho {product}! VELORA rất vui khi bạn hài lòng — hẹn gặp lại bạn ở những bộ sưu tập tiếp theo nhé!',
    this.replyTemplateMid =
        'Cảm ơn {name} đã chia sẻ trải nghiệm về {product}. VELORA đã ghi nhận góp ý của bạn để cải thiện chất lượng và dịch vụ tốt hơn nữa!',
    this.replyTemplateLow =
        'VELORA thành thật xin lỗi {name} vì trải nghiệm chưa trọn vẹn với {product}. Đội ngũ CSKH sẽ liên hệ hỗ trợ kiểm tra và đổi trả tốt nhất cho bạn ngay!',
    this.autoVideoCommentReply = true,
    this.templateVideoCommentReply =
        'Cảm ơn {name} đã quan tâm video mẫu {product}! Đôi này đang sẵn đủ size EU 38–44 tại VELORA. Mình vừa mở khóa thêm vài mẫu {category} tương tự trên tab Nổi bật cho bạn tham khảo nhé ❤️',
    this.autoVideoSimilarPush = true,
    this.templateVideoSimilarPush =
        'Thấy {name} yêu thích video {product} — VELORA gợi ý thêm {similar} cùng dòng {category} đã được mở khóa trên tab Nổi bật Dành cho bạn!',
    this.autoReturnReply = true,
    this.templateReturnReply =
        'VELORA CSKH đã duyệt yêu cầu {type} cho mẫu {product} ({newSize}) của {name}. VELORA sẽ xử lý và nhắn tin xác nhận lịch gửi đôi mới về địa chỉ đổi mới cho bạn!',
    this.autoChatOnOrderStatus = true,
    this.templateChatOrderStatus =
        'Xin chào {name}, đơn hàng {items} của bạn vừa được cập nhật sang trạng thái "{status}"! {eta}. Nếu có bất kỳ yêu cầu nào về giao hàng hoặc đổi size (trong 7 ngày), bạn cứ nhắn trực tiếp tại đây nhé ❤️',
    this.autoChatOnNewProduct = true,
    this.templateChatNewProduct =
        '🔥 Chào {name}! VELORA vừa lên kệ mẫu giày mới {product} (dòng {category}) giá chỉ {price} — sẵn đủ size EU 38–44 tại Tổng Kho Hà Nội. Bạn xem thử và nhắn VELORA giữ size cho bạn nhé!',
  });

  final bool autoWelcomeVoucher;
  final int welcomePercent;
  final int welcomeDays;
  final bool autoHolidayVoucher;
  final int holidayPercent;
  final int holidayDays;
  final bool autoVipVoucher;
  final int vipPercent;
  final int vipDays;
  final bool autoReviewReply;
  final String replyTemplateHigh;
  final String replyTemplateMid;
  final String replyTemplateLow;
  final bool autoVideoCommentReply;
  final String templateVideoCommentReply;
  final bool autoVideoSimilarPush;
  final String templateVideoSimilarPush;
  final bool autoReturnReply;
  final String templateReturnReply;
  final bool autoChatOnOrderStatus;
  final String templateChatOrderStatus;
  final bool autoChatOnNewProduct;
  final String templateChatNewProduct;

  factory AdminAutomationSettings.defaults() => const AdminAutomationSettings();

  String renderAutoReply({
    required String authorName,
    required String productTitle,
    required int rating,
  }) {
    final template = rating >= 4
        ? replyTemplateHigh
        : rating == 3
            ? replyTemplateMid
            : replyTemplateLow;
    return template
        .replaceAll('{name}', authorName.trim().isEmpty ? 'bạn' : authorName.trim())
        .replaceAll('{product}', productTitle.trim().isEmpty ? 'sản phẩm' : productTitle.trim())
        .replaceAll('{stars}', '$rating');
  }

  String renderVideoCommentReply({
    required String authorName,
    required String productTitle,
    required String categoryName,
  }) {
    return templateVideoCommentReply
        .replaceAll('{name}', authorName.trim().isEmpty ? 'bạn' : authorName.trim())
        .replaceAll('{product}', productTitle.trim().isEmpty ? 'sản phẩm' : productTitle.trim())
        .replaceAll(
          '{category}',
          categoryName.trim().isEmpty ? 'giày thể thao' : categoryName.trim(),
        );
  }

  String renderVideoSimilarPush({
    required String userName,
    required String watchedProductTitle,
    required String similarProductTitles,
    required String categoryName,
  }) {
    return templateVideoSimilarPush
        .replaceAll('{name}', userName.trim().isEmpty ? 'bạn' : userName.trim())
        .replaceAll(
          '{product}',
          watchedProductTitle.trim().isEmpty ? 'sản phẩm' : watchedProductTitle.trim(),
        )
        .replaceAll(
          '{similar}',
          similarProductTitles.trim().isEmpty ? 'các mẫu mới' : similarProductTitles.trim(),
        )
        .replaceAll(
          '{category}',
          categoryName.trim().isEmpty ? 'giày thể thao' : categoryName.trim(),
        );
  }

  String renderReturnReply({
    required String customerName,
    required String productTitle,
    required String typeLabel,
    required String requestedSizeOrColor,
  }) {
    return templateReturnReply
        .replaceAll(
          '{name}',
          customerName.trim().isEmpty ? 'bạn' : customerName.trim(),
        )
        .replaceAll(
          '{product}',
          productTitle.trim().isEmpty ? 'sản phẩm VELORA' : productTitle.trim(),
        )
        .replaceAll(
          '{type}',
          typeLabel.trim().isEmpty ? 'Đổi trả & Bảo hành' : typeLabel.trim(),
        )
        .replaceAll(
          '{newSize}',
          requestedSizeOrColor.trim().isEmpty
              ? 'đôi mới 1-1'
              : requestedSizeOrColor.trim(),
        );
  }

  String renderOrderStatusChat({
    required String customerName,
    required String itemsSummary,
    required String statusLabel,
    required String etaNote,
  }) {
    return templateChatOrderStatus
        .replaceAll(
          '{name}',
          customerName.trim().isEmpty ? 'bạn' : customerName.trim(),
        )
        .replaceAll(
          '{items}',
          itemsSummary.trim().isEmpty ? 'đơn hàng VELORA' : itemsSummary.trim(),
        )
        .replaceAll('{status}', statusLabel.trim())
        .replaceAll('{eta}', etaNote.trim());
  }

  String renderNewProductChat({
    required String customerName,
    required String productTitle,
    required String categoryName,
    required String priceLabel,
  }) {
    return templateChatNewProduct
        .replaceAll(
          '{name}',
          customerName.trim().isEmpty ? 'bạn' : customerName.trim(),
        )
        .replaceAll(
          '{product}',
          productTitle.trim().isEmpty ? 'mẫu giày mới VELORA' : productTitle.trim(),
        )
        .replaceAll(
          '{category}',
          categoryName.trim().isEmpty ? 'giày thể thao' : categoryName.trim(),
        )
        .replaceAll('{price}', priceLabel.trim());
  }

  AdminAutomationSettings copyWith({
    bool? autoWelcomeVoucher,
    int? welcomePercent,
    int? welcomeDays,
    bool? autoHolidayVoucher,
    int? holidayPercent,
    int? holidayDays,
    bool? autoVipVoucher,
    int? vipPercent,
    int? vipDays,
    bool? autoReviewReply,
    String? replyTemplateHigh,
    String? replyTemplateMid,
    String? replyTemplateLow,
    bool? autoVideoCommentReply,
    String? templateVideoCommentReply,
    bool? autoVideoSimilarPush,
    String? templateVideoSimilarPush,
    bool? autoReturnReply,
    String? templateReturnReply,
    bool? autoChatOnOrderStatus,
    String? templateChatOrderStatus,
    bool? autoChatOnNewProduct,
    String? templateChatNewProduct,
  }) {
    return AdminAutomationSettings(
      autoWelcomeVoucher: autoWelcomeVoucher ?? this.autoWelcomeVoucher,
      welcomePercent: welcomePercent ?? this.welcomePercent,
      welcomeDays: welcomeDays ?? this.welcomeDays,
      autoHolidayVoucher: autoHolidayVoucher ?? this.autoHolidayVoucher,
      holidayPercent: holidayPercent ?? this.holidayPercent,
      holidayDays: holidayDays ?? this.holidayDays,
      autoVipVoucher: autoVipVoucher ?? this.autoVipVoucher,
      vipPercent: vipPercent ?? this.vipPercent,
      vipDays: vipDays ?? this.vipDays,
      autoReviewReply: autoReviewReply ?? this.autoReviewReply,
      replyTemplateHigh: replyTemplateHigh ?? this.replyTemplateHigh,
      replyTemplateMid: replyTemplateMid ?? this.replyTemplateMid,
      replyTemplateLow: replyTemplateLow ?? this.replyTemplateLow,
      autoVideoCommentReply: autoVideoCommentReply ?? this.autoVideoCommentReply,
      templateVideoCommentReply:
          templateVideoCommentReply ?? this.templateVideoCommentReply,
      autoVideoSimilarPush: autoVideoSimilarPush ?? this.autoVideoSimilarPush,
      templateVideoSimilarPush:
          templateVideoSimilarPush ?? this.templateVideoSimilarPush,
      autoReturnReply: autoReturnReply ?? this.autoReturnReply,
      templateReturnReply: templateReturnReply ?? this.templateReturnReply,
      autoChatOnOrderStatus:
          autoChatOnOrderStatus ?? this.autoChatOnOrderStatus,
      templateChatOrderStatus:
          templateChatOrderStatus ?? this.templateChatOrderStatus,
      autoChatOnNewProduct: autoChatOnNewProduct ?? this.autoChatOnNewProduct,
      templateChatNewProduct:
          templateChatNewProduct ?? this.templateChatNewProduct,
    );
  }

  Map<String, dynamic> toMap() => {
        'autoWelcomeVoucher': autoWelcomeVoucher,
        'welcomePercent': welcomePercent,
        'welcomeDays': welcomeDays,
        'autoHolidayVoucher': autoHolidayVoucher,
        'holidayPercent': holidayPercent,
        'holidayDays': holidayDays,
        'autoVipVoucher': autoVipVoucher,
        'vipPercent': vipPercent,
        'vipDays': vipDays,
        'autoReviewReply': autoReviewReply,
        'replyTemplateHigh': replyTemplateHigh,
        'replyTemplateMid': replyTemplateMid,
        'replyTemplateLow': replyTemplateLow,
        'autoVideoCommentReply': autoVideoCommentReply,
        'templateVideoCommentReply': templateVideoCommentReply,
        'autoVideoSimilarPush': autoVideoSimilarPush,
        'templateVideoSimilarPush': templateVideoSimilarPush,
        'autoReturnReply': autoReturnReply,
        'templateReturnReply': templateReturnReply,
        'autoChatOnOrderStatus': autoChatOnOrderStatus,
        'templateChatOrderStatus': templateChatOrderStatus,
        'autoChatOnNewProduct': autoChatOnNewProduct,
        'templateChatNewProduct': templateChatNewProduct,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory AdminAutomationSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return AdminAutomationSettings.defaults();
    const d = AdminAutomationSettings();
    return AdminAutomationSettings(
      autoWelcomeVoucher: data['autoWelcomeVoucher'] as bool? ?? d.autoWelcomeVoucher,
      welcomePercent: (data['welcomePercent'] as num? ?? d.welcomePercent).toInt(),
      welcomeDays: (data['welcomeDays'] as num? ?? d.welcomeDays).toInt(),
      autoHolidayVoucher: data['autoHolidayVoucher'] as bool? ?? d.autoHolidayVoucher,
      holidayPercent: (data['holidayPercent'] as num? ?? d.holidayPercent).toInt(),
      holidayDays: (data['holidayDays'] as num? ?? d.holidayDays).toInt(),
      autoVipVoucher: data['autoVipVoucher'] as bool? ?? d.autoVipVoucher,
      vipPercent: (data['vipPercent'] as num? ?? d.vipPercent).toInt(),
      vipDays: (data['vipDays'] as num? ?? d.vipDays).toInt(),
      autoReviewReply: data['autoReviewReply'] as bool? ?? d.autoReviewReply,
      replyTemplateHigh: (data['replyTemplateHigh'] as String?)?.trim().isNotEmpty == true
          ? data['replyTemplateHigh'] as String
          : d.replyTemplateHigh,
      replyTemplateMid: (data['replyTemplateMid'] as String?)?.trim().isNotEmpty == true
          ? data['replyTemplateMid'] as String
          : d.replyTemplateMid,
      replyTemplateLow: (data['replyTemplateLow'] as String?)?.trim().isNotEmpty == true
          ? data['replyTemplateLow'] as String
          : d.replyTemplateLow,
      autoVideoCommentReply:
          data['autoVideoCommentReply'] as bool? ?? d.autoVideoCommentReply,
      templateVideoCommentReply:
          (data['templateVideoCommentReply'] as String?)?.trim().isNotEmpty == true
              ? data['templateVideoCommentReply'] as String
              : d.templateVideoCommentReply,
      autoVideoSimilarPush:
          data['autoVideoSimilarPush'] as bool? ?? d.autoVideoSimilarPush,
      templateVideoSimilarPush:
          (data['templateVideoSimilarPush'] as String?)?.trim().isNotEmpty == true
              ? data['templateVideoSimilarPush'] as String
              : d.templateVideoSimilarPush,
      autoReturnReply: data['autoReturnReply'] as bool? ?? d.autoReturnReply,
      templateReturnReply:
          (data['templateReturnReply'] as String?)?.trim().isNotEmpty == true
              ? data['templateReturnReply'] as String
              : d.templateReturnReply,
      autoChatOnOrderStatus:
          data['autoChatOnOrderStatus'] as bool? ?? d.autoChatOnOrderStatus,
      templateChatOrderStatus:
          (data['templateChatOrderStatus'] as String?)?.trim().isNotEmpty == true
              ? data['templateChatOrderStatus'] as String
              : d.templateChatOrderStatus,
      autoChatOnNewProduct:
          data['autoChatOnNewProduct'] as bool? ?? d.autoChatOnNewProduct,
      templateChatNewProduct:
          (data['templateChatNewProduct'] as String?)?.trim().isNotEmpty == true
              ? data['templateChatNewProduct'] as String
              : d.templateChatNewProduct,
    );
  }
}

class OrderFinancialBreakdown {
  const OrderFinancialBreakdown({
    required this.record,
    required this.grossSubtotal,
    required this.discount,
    required this.netRevenue,
    required this.tax,
    required this.cogs,
    required this.shipping,
    required this.netProfit,
  });

  final AdminOrderRecord record;
  final double grossSubtotal;
  final double discount;
  final double netRevenue;
  final double tax;
  final double cogs;
  final double shipping;
  final double netProfit;

  bool get isLoss => netProfit < 0;
}

class FinancePeriodPoint {
  const FinancePeriodPoint({
    required this.label,
    required this.revenue,
    required this.costAndTax,
    required this.tax,
    required this.profit,
    required this.orderCount,
  });

  final String label;
  final double revenue;
  final double costAndTax;
  final double tax;
  final double profit;
  final int orderCount;
}

class AdminVoucherRecord {
  const AdminVoucherRecord({
    required this.code,
    required this.title,
    required this.expires,
    this.percent = 0,
    this.maxUsd = 0,
    this.minUsd = 0,
    this.shipping = false,
    this.active = true,
    this.targetAudience = 'all', // 'all' | 'newMember' | 'loyal' | 'vip' | 'specific'
    this.targetUserIds = const [],
    this.excludeBomHang = true,
    this.autoTag = '', // '' | 'new_member' | 'holiday' | 'vip'
    this.createdAt,
  });

  final String code;
  final String title;
  final DateTime expires;
  final int percent;
  final double maxUsd;
  final double minUsd;
  final bool shipping;
  final bool active;
  final String targetAudience;
  final List<String> targetUserIds;
  final bool excludeBomHang;
  final String autoTag;
  final DateTime? createdAt;

  bool get isExpired => !DateTime.now().isBefore(expires);

  String get audienceSummary {
    switch (targetAudience) {
      case 'newMember':
        return 'Thành viên mới';
      case 'loyal':
        return 'Khách lâu năm';
      case 'vip':
        return 'Khách VIP';
      case 'specific':
        return 'Chọn riêng (${targetUserIds.length} khách)';
      default:
        return excludeBomHang ? 'Tất cả (trừ bom hàng)' : 'Tất cả khách hàng';
    }
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) => {
        'code': code.trim().toUpperCase(),
        'title': title.trim(),
        'percent': shipping ? 0 : percent,
        'maxUsd': shipping ? 0.0 : maxUsd,
        'minUsd': minUsd,
        'shipping': shipping,
        'active': active,
        'targetAudience': targetAudience,
        'targetUserIds': targetUserIds,
        'excludeBomHang': excludeBomHang,
        'autoTag': autoTag,
        'expires': Timestamp.fromDate(expires),
        if (isNew) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory AdminVoucherRecord.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawExpires = data['expires'];
    DateTime expires = DateTime.now().add(const Duration(days: 7));
    if (rawExpires is Timestamp) {
      expires = rawExpires.toDate();
    } else if (rawExpires is String) {
      expires = DateTime.tryParse(rawExpires) ?? expires;
    }
    final rawIds = data['targetUserIds'];
    final ids = rawIds is List
        ? rawIds.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : const <String>[];
    return AdminVoucherRecord(
      code: ((data['code'] ?? doc.id) as String).trim().toUpperCase(),
      title: (data['title'] ?? '') as String,
      expires: expires,
      percent: (data['percent'] as num? ?? 0).toInt(),
      maxUsd: (data['maxUsd'] as num? ?? 0).toDouble(),
      minUsd: (data['minUsd'] as num? ?? 0).toDouble(),
      shipping: data['shipping'] == true,
      active: data['active'] != false,
      targetAudience: (data['targetAudience'] ?? 'all').toString(),
      targetUserIds: ids,
      excludeBomHang: data['excludeBomHang'] != false,
      autoTag: (data['autoTag'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class AdminOrderRecord {
  const AdminOrderRecord({
    required this.docId,
    required this.userId,
    required this.order,
    this.customer,
  });

  final String docId;
  final String userId;
  final OrderModel order;
  final UserModel? customer;

  String get customerName {
    final name = customer?.fullName.trim() ?? '';
    if (name.isNotEmpty) return name;
    final addrName = order.address?.name.trim() ?? '';
    if (addrName.isNotEmpty) return addrName;
    return customer?.email ?? userId;
  }

  String get customerEmail => customer?.email ?? '';
}

class AdminBannerRecord {
  const AdminBannerRecord({
    required this.docId,
    required this.banner,
  });

  final String docId;
  final BannerModel banner;
}

class AdminReviewRecord {
  const AdminReviewRecord({
    required this.productId,
    required this.productTitle,
    required this.productThumbnail,
    required this.review,
    this.purchaseOrderId = '',
  });

  final String productId;
  final String productTitle;
  final String productThumbnail;
  final ProductReviewEntry review;
  final String purchaseOrderId;
}

class AdminVideoCommentRecord {
  const AdminVideoCommentRecord({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productThumbnail,
    this.categoryId = '',
    this.categoryName = '',
    this.userId = '',
    required this.authorName,
    required this.text,
    this.videoUrl = '',
    this.createdAt,
    this.adminReply,
    this.adminReplyAt,
  });

  final String id;
  final String productId;
  final String productTitle;
  final String productThumbnail;
  final String categoryId;
  final String categoryName;
  final String userId;
  final String authorName;
  final String text;
  final String videoUrl;
  final DateTime? createdAt;
  final String? adminReply;
  final DateTime? adminReplyAt;

  bool get hasAdminReply => adminReply != null && adminReply!.trim().isNotEmpty;
}

class AdminNotificationCampaign {
  const AdminNotificationCampaign({
    required this.id,
    required this.titleVi,
    required this.bodyVi,
    required this.titleEn,
    required this.bodyEn,
    required this.kind,
    required this.targetId,
    required this.audienceLabel,
    required this.recipientCount,
    this.createdAt,
  });

  final String id;
  final String titleVi;
  final String bodyVi;
  final String titleEn;
  final String bodyEn;
  final String kind;
  final String targetId;
  final String audienceLabel;
  final int recipientCount;
  final DateTime? createdAt;

  factory AdminNotificationCampaign.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AdminNotificationCampaign(
      id: doc.id,
      titleVi: (data['titleVi'] ?? '') as String,
      bodyVi: (data['bodyVi'] ?? '') as String,
      titleEn: (data['titleEn'] ?? '') as String,
      bodyEn: (data['bodyEn'] ?? '') as String,
      kind: (data['kind'] ?? 'promo') as String,
      targetId: (data['targetId'] ?? '') as String,
      audienceLabel: (data['audienceLabel'] ?? 'Tất cả khách hàng') as String,
      recipientCount: (data['recipientCount'] as num? ?? 0).toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class AdminUserInterest {
  const AdminUserInterest({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.lastQuery,
    this.lastSource = 'ai',
    this.lastProductId = '',
    this.lastProductTitle = '',
    this.recentQueries = const [],
    this.interestedBrands = const [],
    this.interestedCategories = const [],
    this.interestedCategoryIds = const [],
    this.interestedColors = const [],
    this.queryCount = 0,
    this.updatedAt,
  });

  final String userId;
  final String userName;
  final String userEmail;
  final String lastQuery;
  final String lastSource;
  final String lastProductId;
  final String lastProductTitle;
  final List<String> recentQueries;
  final List<String> interestedBrands;
  final List<String> interestedCategories;
  final List<String> interestedCategoryIds;
  final List<String> interestedColors;
  final int queryCount;
  final DateTime? updatedAt;

  factory AdminUserInterest.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    List<String> strList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() : const [];
    return AdminUserInterest(
      userId: (data['userId'] ?? doc.id).toString(),
      userName: (data['userName'] ?? 'Khách hàng').toString(),
      userEmail: (data['userEmail'] ?? '').toString(),
      lastQuery: (data['lastQuery'] ?? '').toString(),
      lastSource: (data['lastSource'] ?? 'ai').toString(),
      lastProductId: (data['lastProductId'] ?? '').toString(),
      lastProductTitle: (data['lastProductTitle'] ?? '').toString(),
      recentQueries: strList(data['recentQueries']),
      interestedBrands: strList(data['interestedBrands']),
      interestedCategories: strList(data['interestedCategories']),
      interestedCategoryIds: strList(data['interestedCategoryIds']),
      interestedColors: strList(data['interestedColors']),
      queryCount: (data['queryCount'] as num? ?? 0).toInt(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
