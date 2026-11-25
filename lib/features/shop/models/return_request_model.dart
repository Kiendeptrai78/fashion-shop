import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

enum ReturnRequestType {
  exchangeSize,
  defectiveExchange,
  returnRefund,
}

enum ReturnRequestStatus {
  pending,
  approvedPickup,
  inspecting,
  completed,
  rejected,
}

class ReturnRequestModel {
  const ReturnRequestModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.customerName,
    this.customerEmail = '',
    this.customerPhone = '',
    this.pickupAddress = '',
    required this.productId,
    required this.productTitle,
    this.productThumbnail = '',
    required this.refundAmountUsd,
    this.quantity = 1,
    this.currentVariation = '',
    this.requestedSizeOrColor = '',
    required this.type,
    required this.reasonCategory,
    required this.description,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.status = ReturnRequestStatus.pending,
    this.adminResponse = '',
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String orderId;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String pickupAddress;
  final String productId;
  final String productTitle;
  final String productThumbnail;
  final double refundAmountUsd;
  final int quantity;
  final String currentVariation;
  final String requestedSizeOrColor;
  final ReturnRequestType type;
  final String reasonCategory;
  final String description;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final ReturnRequestStatus status;
  final String adminResponse;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get hasMedia => imageUrls.isNotEmpty || videoUrls.isNotEmpty;
  bool get hasAdminResponse => adminResponse.trim().isNotEmpty;

  static String typeLabelOf(ReturnRequestType t, {bool english = false}) =>
      switch (t) {
        ReturnRequestType.exchangeSize =>
          english ? 'Exchange Size / Color' : 'Đổi kích cỡ / Màu sắc',
        ReturnRequestType.defectiveExchange =>
          english ? '1-to-1 Defective Replacement' : 'Đổi mới 1-1 (Lỗi / Giao sai)',
        ReturnRequestType.returnRefund =>
          english ? 'Return & 100% Refund' : 'Trả hàng & Hoàn tiền 100%',
      };

  static IconData typeIconOf(ReturnRequestType t) => switch (t) {
        ReturnRequestType.exchangeSize => Iconsax.ruler,
        ReturnRequestType.defectiveExchange => Iconsax.refresh_circle,
        ReturnRequestType.returnRefund => Iconsax.wallet_money,
      };

  static Color typeColorOf(ReturnRequestType t) => switch (t) {
        ReturnRequestType.exchangeSize => const Color(0xFF0284C7),
        ReturnRequestType.defectiveExchange => const Color(0xFF7C3AED),
        ReturnRequestType.returnRefund => const Color(0xFFD97706),
      };

  static String statusLabelOf(ReturnRequestStatus s, {bool english = false}) =>
      switch (s) {
        ReturnRequestStatus.pending =>
          english ? 'Awaiting approval' : 'Chờ duyệt đổi trả',
        ReturnRequestStatus.approvedPickup =>
          english ? 'Approved • Courier picking up' : 'Đã duyệt • Shipper đang lấy hàng',
        ReturnRequestStatus.inspecting =>
          english
              ? 'At Hanoi Hub • Sending replacement'
              : 'Kho HN đã nhận • Đang gửi đôi mới',
        ReturnRequestStatus.completed =>
          english ? 'Exchange / Refund Completed' : 'Hoàn tất đổi trả',
        ReturnRequestStatus.rejected =>
          english ? 'Request Declined' : 'Từ chối đổi trả',
      };

  static String statusSubtitleOf(
    ReturnRequestStatus s,
    ReturnRequestType t, {
    bool english = false,
  }) =>
      switch (s) {
        ReturnRequestStatus.pending => english
            ? 'VELORA CSKH has received your request and is reviewing your photos/videos.'
            : 'Bộ phận Đổi trả & Bảo hành VELORA đã tiếp nhận yêu cầu và đang kiểm tra hình ảnh/video thực tế.',
        ReturnRequestStatus.approvedPickup => english
            ? 'Approved! A VELORA courier will pick up your pair free of charge.'
            : 'Yêu cầu đã được duyệt! Shipper VELORA đang đến địa chỉ của bạn để thu hồi giày miễn phí về Tổng Kho Hà Nội.',
        ReturnRequestStatus.inspecting => t == ReturnRequestType.returnRefund
            ? (english
                ? 'Hanoi Warehouse received the pair and is processing your 100% refund.'
                : 'Tổng Kho Hà Nội đã nhận lại giày, đang kiểm định nhanh để hoàn tiền 100% cho bạn.')
            : (english
                ? 'Hanoi Warehouse received the pair and dispatched your new replacement pair!'
                : 'Tổng Kho Hà Nội đã nhận giày thu hồi và đang xuất kho gửi đôi mới chuẩn size/mẫu tới bạn!'),
        ReturnRequestStatus.completed => t == ReturnRequestType.returnRefund
            ? (english
                ? '100% refund has been completed.'
                : 'Đã hoàn tất trả hàng và hoàn tiền 100% cho bạn.')
            : (english
                ? 'Your replacement pair has been delivered successfully!'
                : 'Đôi giày đổi mới đã hoàn tất bàn giao tới tay bạn. Cảm ơn bạn đã tin chọn VELORA!'),
        ReturnRequestStatus.rejected => english
            ? 'Your return/exchange request could not be approved. Please see VELORA response below.'
            : 'Yêu cầu đổi trả chưa đủ điều kiện duyệt. Vui lòng xem chi tiết phản hồi từ VELORA bên dưới.',
      };

  static Color statusColorOf(ReturnRequestStatus s) => switch (s) {
        ReturnRequestStatus.pending => const Color(0xFFD97706), // Amber
        ReturnRequestStatus.approvedPickup => const Color(0xFF7C3AED), // Violet
        ReturnRequestStatus.inspecting => const Color(0xFF0284C7), // Sky Blue
        ReturnRequestStatus.completed => const Color(0xFF16A34A), // Emerald
        ReturnRequestStatus.rejected => const Color(0xFFDC2626), // Rose Red
      };

  static Color statusBgColorOf(ReturnRequestStatus s) => switch (s) {
        ReturnRequestStatus.pending => const Color(0xFFFEF3C7),
        ReturnRequestStatus.approvedPickup => const Color(0xFFEDE9FE),
        ReturnRequestStatus.inspecting => const Color(0xFFE0F2FE),
        ReturnRequestStatus.completed => const Color(0xFFDCFCE7),
        ReturnRequestStatus.rejected => const Color(0xFFFFE4E6),
      };

  static Color statusBorderColorOf(ReturnRequestStatus s) => switch (s) {
        ReturnRequestStatus.pending => const Color(0xFFF59E0B),
        ReturnRequestStatus.approvedPickup => const Color(0xFFA78BFA),
        ReturnRequestStatus.inspecting => const Color(0xFF38BDF8),
        ReturnRequestStatus.completed => const Color(0xFF4ADE80),
        ReturnRequestStatus.rejected => const Color(0xFFFB7185),
      };

  static IconData statusIconOf(ReturnRequestStatus s) => switch (s) {
        ReturnRequestStatus.pending => Iconsax.clock,
        ReturnRequestStatus.approvedPickup => Iconsax.truck_time,
        ReturnRequestStatus.inspecting => Iconsax.box_search,
        ReturnRequestStatus.completed => Iconsax.tick_circle,
        ReturnRequestStatus.rejected => Iconsax.close_circle,
      };

  String typeLabel({bool english = false}) =>
      typeLabelOf(type, english: english);
  String statusLabel({bool english = false}) =>
      statusLabelOf(status, english: english);
  String statusSubtitle({bool english = false}) =>
      statusSubtitleOf(status, type, english: english);
  Color get statusColor => statusColorOf(status);
  Color get statusBgColor => statusBgColorOf(status);
  Color get statusBorderColor => statusBorderColorOf(status);
  IconData get statusIcon => statusIconOf(status);

  int get stepIndex => switch (status) {
        ReturnRequestStatus.pending => 1,
        ReturnRequestStatus.approvedPickup => 2,
        ReturnRequestStatus.inspecting => 3,
        ReturnRequestStatus.completed => 4,
        ReturnRequestStatus.rejected => 0,
      };

  static ReturnRequestType parseType(String raw) {
    final s = raw.trim();
    for (final v in ReturnRequestType.values) {
      if (v.name == s || v.toString() == s) return v;
    }
    return ReturnRequestType.exchangeSize;
  }

  static ReturnRequestStatus parseStatus(String raw) {
    final s = raw.trim();
    for (final v in ReturnRequestStatus.values) {
      if (v.name == s || v.toString() == s) return v;
    }
    return ReturnRequestStatus.pending;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'userId': userId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'pickupAddress': pickupAddress,
        'productId': productId,
        'productTitle': productTitle,
        'productThumbnail': productThumbnail,
        'refundAmountUsd': refundAmountUsd,
        'quantity': quantity,
        'currentVariation': currentVariation,
        'requestedSizeOrColor': requestedSizeOrColor,
        'type': type.name,
        'reasonCategory': reasonCategory,
        'description': description,
        'imageUrls': imageUrls,
        'videoUrls': videoUrls,
        'status': status.name,
        'adminResponse': adminResponse,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory ReturnRequestModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ReturnRequestModel.fromMap(data, docId: doc.id);
  }

  factory ReturnRequestModel.fromMap(
    Map<String, dynamic> data, {
    String? docId,
  }) {
    final rawCreated = data['createdAt'];
    final created = rawCreated is Timestamp
        ? rawCreated.toDate()
        : (rawCreated is DateTime ? rawCreated : DateTime.now());
    final rawUpdated = data['updatedAt'];
    final updated = rawUpdated is Timestamp
        ? rawUpdated.toDate()
        : (rawUpdated is DateTime ? rawUpdated : null);

    return ReturnRequestModel(
      id: (data['id'] as String?)?.trim().isNotEmpty == true
          ? data['id'] as String
          : (docId ?? ''),
      orderId: (data['orderId'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      customerName: (data['customerName'] ?? 'Khách hàng VELORA').toString(),
      customerEmail: (data['customerEmail'] ?? '').toString(),
      customerPhone: (data['customerPhone'] ?? '').toString(),
      pickupAddress: (data['pickupAddress'] ?? '').toString(),
      productId: (data['productId'] ?? '').toString(),
      productTitle: (data['productTitle'] ?? 'Giày VELORA').toString(),
      productThumbnail: (data['productThumbnail'] ?? '').toString(),
      refundAmountUsd: (data['refundAmountUsd'] as num? ?? 0).toDouble(),
      quantity: (data['quantity'] as num? ?? 1).toInt(),
      currentVariation: (data['currentVariation'] ?? '').toString(),
      requestedSizeOrColor: (data['requestedSizeOrColor'] ?? '').toString(),
      type: parseType((data['type'] ?? '').toString()),
      reasonCategory: (data['reasonCategory'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? const []),
      videoUrls: List<String>.from(data['videoUrls'] as List? ?? const []),
      status: parseStatus((data['status'] ?? '').toString()),
      adminResponse: (data['adminResponse'] ?? '').toString(),
      createdAt: created,
      updatedAt: updated,
    );
  }
}
