import 'package:cloud_firestore/cloud_firestore.dart';

class SupportChatMessageModel {
  const SupportChatMessageModel({
    required this.id,
    required this.sender, // 'customer' | 'admin'
    required this.senderName,
    required this.text,
    this.imageUrl = '',
    this.videoUrl = '',
    this.orderId = '',
    this.returnRequestId = '',
    this.productId = '',
    this.productTitle = '',
    this.productThumbnail = '',
    this.contextSummary = '',
    required this.createdAt,
  });

  final String id;
  final String sender;
  final String senderName;
  final String text;
  final String imageUrl;
  final String videoUrl;
  final String orderId;
  final String returnRequestId;
  final String productId;
  final String productTitle;
  final String productThumbnail;
  final String contextSummary;
  final DateTime createdAt;

  bool get isAdmin => sender == 'admin';
  bool get isCustomer => sender != 'admin';
  bool get hasImage => imageUrl.trim().isNotEmpty;
  bool get hasVideo => videoUrl.trim().isNotEmpty;
  bool get hasContext =>
      orderId.trim().isNotEmpty ||
      returnRequestId.trim().isNotEmpty ||
      productId.trim().isNotEmpty ||
      productTitle.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
        'id': id,
        'sender': sender,
        'senderName': senderName,
        'text': text,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'orderId': orderId,
        'returnRequestId': returnRequestId,
        'productId': productId,
        'productTitle': productTitle,
        'productThumbnail': productThumbnail,
        'contextSummary': contextSummary,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory SupportChatMessageModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SupportChatMessageModel.fromMap(data, fallbackId: doc.id);
  }

  factory SupportChatMessageModel.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    final rawCreated = data['createdAt'];
    final createdAt = rawCreated is Timestamp
        ? rawCreated.toDate()
        : (rawCreated is String
            ? DateTime.tryParse(rawCreated) ?? DateTime.now()
            : DateTime.now());
    return SupportChatMessageModel(
      id: (data['id'] as String?)?.trim().isNotEmpty == true
          ? (data['id'] as String).trim()
          : fallbackId,
      sender: (data['sender'] as String?)?.trim() ?? 'customer',
      senderName: (data['senderName'] as String?)?.trim() ?? 'Khách hàng',
      text: (data['text'] as String?)?.trim() ?? '',
      imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
      videoUrl: (data['videoUrl'] as String?)?.trim() ?? '',
      orderId: (data['orderId'] as String?)?.trim() ?? '',
      returnRequestId: (data['returnRequestId'] as String?)?.trim() ?? '',
      productId: (data['productId'] as String?)?.trim() ?? '',
      productTitle: (data['productTitle'] as String?)?.trim() ?? '',
      productThumbnail: (data['productThumbnail'] as String?)?.trim() ?? '',
      contextSummary: (data['contextSummary'] as String?)?.trim() ?? '',
      createdAt: createdAt,
    );
  }
}

class SupportChatThreadModel {
  const SupportChatThreadModel({
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.lastMessage,
    required this.lastSender,
    required this.unreadByAdmin,
    required this.unreadByCustomer,
    this.activeOrderId = '',
    this.activeReturnId = '',
    this.activeProductTitle = '',
    this.activeProductThumbnail = '',
    this.activeContextSummary = '',
    required this.updatedAt,
  });

  final String userId;
  final String customerName;
  final String customerEmail;
  final String lastMessage;
  final String lastSender;
  final int unreadByAdmin;
  final int unreadByCustomer;
  final String activeOrderId;
  final String activeReturnId;
  final String activeProductTitle;
  final String activeProductThumbnail;
  final String activeContextSummary;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'lastMessage': lastMessage,
        'lastSender': lastSender,
        'unreadByAdmin': unreadByAdmin,
        'unreadByCustomer': unreadByCustomer,
        'activeOrderId': activeOrderId,
        'activeReturnId': activeReturnId,
        'activeProductTitle': activeProductTitle,
        'activeProductThumbnail': activeProductThumbnail,
        'activeContextSummary': activeContextSummary,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory SupportChatThreadModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawUpdated = data['updatedAt'];
    final updatedAt = rawUpdated is Timestamp
        ? rawUpdated.toDate()
        : (rawUpdated is String
            ? DateTime.tryParse(rawUpdated) ?? DateTime.now()
            : DateTime.now());
    return SupportChatThreadModel(
      userId: (data['userId'] as String?)?.trim().isNotEmpty == true
          ? (data['userId'] as String).trim()
          : doc.id,
      customerName:
          (data['customerName'] as String?)?.trim().isNotEmpty == true
              ? (data['customerName'] as String).trim()
              : 'Khách hàng VELORA',
      customerEmail: (data['customerEmail'] as String?)?.trim() ?? '',
      lastMessage: (data['lastMessage'] as String?)?.trim() ?? '',
      lastSender: (data['lastSender'] as String?)?.trim() ?? 'customer',
      unreadByAdmin: (data['unreadByAdmin'] as num?)?.toInt() ?? 0,
      unreadByCustomer: (data['unreadByCustomer'] as num?)?.toInt() ?? 0,
      activeOrderId: (data['activeOrderId'] as String?)?.trim() ?? '',
      activeReturnId: (data['activeReturnId'] as String?)?.trim() ?? '',
      activeProductTitle: (data['activeProductTitle'] as String?)?.trim() ?? '',
      activeProductThumbnail:
          (data['activeProductThumbnail'] as String?)?.trim() ?? '',
      activeContextSummary:
          (data['activeContextSummary'] as String?)?.trim() ?? '',
      updatedAt: updatedAt,
    );
  }
}
