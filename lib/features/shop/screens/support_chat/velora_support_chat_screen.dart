import 'package:fashion_business_app/common/widgets/chat/shop_chat_background.dart';
import 'package:fashion_business_app/common/widgets/chat/shop_chat_send_button.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/data/services/image_storage_service.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/product_availability_helper.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/models/return_request_model.dart';
import 'package:fashion_business_app/features/shop/models/support_chat_model.dart';
import 'package:fashion_business_app/features/shop/screens/product_details/product_details.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class VeloraSupportChatScreen extends StatefulWidget {
  const VeloraSupportChatScreen({
    super.key,
    this.initialOrder,
    this.initialReturnRequest,
    this.initialProduct,
    this.initialDraftText,
    this.embeddedInNav = false,
  });

  final OrderModel? initialOrder;
  final ReturnRequestModel? initialReturnRequest;
  final ProductModel? initialProduct;
  final String? initialDraftText;
  final bool embeddedInNav;

  @override
  State<VeloraSupportChatScreen> createState() =>
      _VeloraSupportChatScreenState();
}

class _VeloraSupportChatScreenState extends State<VeloraSupportChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  final _storage = ImageStorageService(
    cloudName: 'lbbgn51d',
    uploadPreset: 'fashion_shop',
  );

  Stream<QuerySnapshot<Map<String, dynamic>>>? _messagesStream;
  bool _sending = false;
  bool _uploadingMedia = false;
  String _uploadingLabel = '';
  bool _contextAttached = true;
  bool _showScrollToLatest = false;

  OrderModel? get _order => widget.initialOrder;
  ReturnRequestModel? get _returnReq => widget.initialReturnRequest;
  ProductModel? get _product => widget.initialProduct;

  bool get _hasActiveContext =>
      _contextAttached &&
      (_order != null || _returnReq != null || _product != null);

  String get _contextProductTitle {
    if (_returnReq != null) return _returnReq!.productTitle;
    if (_order != null && _order!.items.isNotEmpty) {
      return _order!.itemsSummary();
    }
    if (_product != null) return _product!.title;
    return '';
  }

  String get _contextThumbnail {
    if (_returnReq != null) return _returnReq!.productThumbnail;
    if (_order != null && _order!.items.isNotEmpty) {
      return _order!.items.first.image ?? '';
    }
    if (_product != null) return _product!.thumbnail;
    return '';
  }

  String get _contextSummary {
    if (_returnReq != null) {
      return '${_returnReq!.typeLabel()} • ${_returnReq!.requestedSizeOrColor}'
          '${_returnReq!.pickupAddress.isNotEmpty ? ' • Địa chỉ đổi mới: ${_returnReq!.pickupAddress}' : ''}';
    }
    if (_order != null) {
      return 'Trạng thái: ${_order!.orderStatusLabel()}'
          '${_order!.address != null ? ' • Giao tới: ${_order!.address.toString()}' : ''}';
    }
    if (_product != null) {
      final p = _product!;
      final eff = (p.salePrice > 0 && p.salePrice < p.price) ? p.salePrice : p.price;
      return '${p.categoryName} • ${formatShopMoney(eff, language: 'vi')}';
    }
    return '';
  }

  List<String> get _quickChips {
    if (_returnReq != null) {
      return [
        'Mình muốn hỏi tiến trình đổi mới cho đôi ${_returnReq!.productTitle}',
        'Nhờ VELORA gửi đôi đổi mới về địa chỉ: ${_returnReq!.pickupAddress}',
        'Mình gửi thêm ảnh/video thực tế đôi giày cần đổi nhé',
        'Khi nào VELORA gửi đôi mới cho mình vậy ạ?',
      ];
    }
    if (_order != null) {
      return [
        'Mình muốn trao đổi về đơn hàng ${_order!.itemsSummary()}',
        'Mình muốn đổi size / đổi mẫu cho đơn hàng này',
        'Nhờ shop kiểm tra giúp mình bao giờ đơn giao tới nơi nhé',
        'Mình muốn cập nhật địa chỉ nhận hàng cho đơn này',
      ];
    }
    if (_product != null) {
      return [
        'Đôi ${_product!.title} này còn đủ size EU 38–44 không shop?',
        'Nhờ shop tư vấn chọn size cho mẫu ${_product!.title} này nhé',
        'Mẫu ${_product!.title} có ảnh/video thực tế không ạ?',
      ];
    }
    return const [
      'Mình cần hỗ trợ đổi size / đổi trả đôi giày đã nhận',
      'Nhờ VELORA kiểm tra tiến trình đơn hàng giúp mình',
      'Tư vấn giúp mình chọn size giày chuẩn với ạ',
      'Mình muốn cập nhật địa chỉ nhận giày đổi mới',
    ];
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialDraftText != null &&
        widget.initialDraftText!.trim().isNotEmpty) {
      _input.text = widget.initialDraftText!.trim();
    }
    final user =
        Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;
    if (user != null) {
      _messagesStream = FirebaseFirestore.instance
          .collection('SupportChats')
          .doc(user.uid)
          .collection('Messages')
          .orderBy('createdAt', descending: false)
          .snapshots();
    }
    _scroll.addListener(_onScrollChanged);
    _markCustomerRead();
  }

  void _onScrollChanged() {
    if (!_scroll.hasClients) return;
    final shouldShow = _scroll.offset > 60;
    if (shouldShow != _showScrollToLatest) {
      setState(() => _showScrollToLatest = shouldShow);
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScrollChanged);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _markCustomerRead() async {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('SupportChats')
          .doc(user.uid)
          .set({'unreadByCustomer': 0}, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _sendMessage({
    String? presetText,
    String imageUrl = '',
    String videoUrl = '',
  }) async {
    final text = (presetText ?? _input.text).trim();
    if (text.isEmpty && imageUrl.isEmpty && videoUrl.isEmpty) return;
    if (_sending) return;

    final user =
        Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;
    if (user == null) return;

    setState(() => _sending = true);
    if (presetText == null) _input.clear();

    final customerName = Get.isRegistered<UserController>() &&
            UserController.instance.user.value.fullName.trim().isNotEmpty
        ? UserController.instance.user.value.fullName.trim()
        : (user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : (user.email?.split('@').first ?? 'Khách hàng VELORA'));

    final db = FirebaseFirestore.instance;
    final threadRef = db.collection('SupportChats').doc(user.uid);
    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';

    final attachOrder =
        _hasActiveContext ? (_order?.id ?? _returnReq?.orderId ?? '') : '';
    final attachReturn = _hasActiveContext ? (_returnReq?.id ?? '') : '';
    final attachProductId = _hasActiveContext
        ? (_product?.id ??
            _returnReq?.productId ??
            (_order != null && _order!.items.isNotEmpty
                ? _order!.items.first.productId
                : ''))
        : '';
    final attachTitle = _hasActiveContext ? _contextProductTitle : '';
    final attachThumb = _hasActiveContext ? _contextThumbnail : '';
    final attachSummary = _hasActiveContext ? _contextSummary : '';

    final msg = SupportChatMessageModel(
      id: msgId,
      sender: 'customer',
      senderName: customerName,
      text: text.isNotEmpty
          ? text
          : (videoUrl.isNotEmpty
              ? '🎬 Đã gửi video thực tế đính kèm'
              : '📷 Đã gửi hình ảnh đính kèm'),
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      orderId: attachOrder,
      returnRequestId: attachReturn,
      productId: attachProductId,
      productTitle: attachTitle,
      productThumbnail: attachThumb,
      contextSummary: attachSummary,
      createdAt: DateTime.now(),
    );

    try {
      await threadRef.collection('Messages').doc(msgId).set(msg.toMap());
      await threadRef.set({
        'userId': user.uid,
        'customerName': customerName,
        'customerEmail': user.email ?? '',
        'lastMessage': msg.text,
        'lastSender': 'customer',
        'unreadByAdmin': FieldValue.increment(1),
        'unreadByCustomer': 0,
        if (attachOrder.isNotEmpty) 'activeOrderId': attachOrder,
        if (attachReturn.isNotEmpty) 'activeReturnId': attachReturn,
        if (attachTitle.isNotEmpty) 'activeProductTitle': attachTitle,
        if (attachThumb.isNotEmpty) 'activeProductThumbnail': attachThumb,
        if (attachSummary.isNotEmpty) 'activeContextSummary': attachSummary,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (_contextAttached) {
        setState(() => _contextAttached = false);
      }
      _scrollToBottom();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_uploadingMedia) return;
    setState(() {
      _uploadingMedia = true;
      _uploadingLabel = 'Đang tải hình ảnh lên...';
    });
    try {
      XFile? file;
      try {
        file = await _picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1600,
        );
      } catch (_) {
        if (source == ImageSource.camera) {
          file = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
            maxWidth: 1600,
          );
        }
      }
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final url = await _storage.uploadImageData(
        'SupportChats/Images',
        bytes,
        file.name.isNotEmpty
            ? file.name
            : 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await _sendMessage(
        presetText: _input.text.trim(),
        imageUrl: url,
      );
      _input.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingMedia = false;
          _uploadingLabel = '';
        });
      }
    }
  }

  Future<void> _pickAndSendVideo(ImageSource source) async {
    if (_uploadingMedia) return;
    setState(() {
      _uploadingMedia = true;
      _uploadingLabel = 'Đang tải video (.mp4) lên...';
    });
    try {
      XFile? file;
      try {
        file = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 45),
        );
      } catch (_) {
        if (source == ImageSource.camera) {
          file = await _picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(seconds: 45),
          );
        }
      }
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final url = await _storage.uploadVideoData(
        'SupportChats/Videos',
        bytes,
        file.name.isNotEmpty
            ? file.name
            : 'chat_vid_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await _sendMessage(
        presetText: _input.text.trim(),
        videoUrl: url,
      );
      _input.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi video: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingMedia = false;
          _uploadingLabel = '';
        });
      }
    }
  }

  void _openMediaPickerSheet() {
    showShopBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gửi Hình ảnh hoặc Video thực tế cho VELORA',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Iconsax.gallery, color: Color(0xFF173E32)),
                title: const Text('Chọn hình ảnh từ Thư viện'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.camera, color: Color(0xFF173E32)),
                title: const Text('Chụp ảnh trực tiếp'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    const Icon(Iconsax.video_play, color: Color(0xFF0284C7)),
                title: const Text('Chọn Video từ Thư viện'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickAndSendVideo(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.video, color: Color(0xFF0284C7)),
                title: const Text('Quay Video trực tiếp'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickAndSendVideo(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openImageViewer(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: ShopGlassIconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: Icons.close_rounded,
                iconColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVideoPlayer(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => _ChatVideoPlayerDialog(videoUrl: url),
    );
  }

  Future<void> _openProductFromMessage(SupportChatMessageModel msg) async {
    if (Firebase.apps.isEmpty) return;
    final db = FirebaseFirestore.instance;
    ProductModel? found;
    try {
      if (msg.productId.trim().isNotEmpty) {
        final doc =
            await db.collection('Products').doc(msg.productId.trim()).get();
        if (doc.exists && doc.data() != null) {
          found = ProductModel.fromSnapshot(doc);
        }
      }
      if (found == null && msg.productTitle.trim().isNotEmpty) {
        final q = await db
            .collection('Products')
            .where('Title', isEqualTo: msg.productTitle.trim())
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          found = ProductModel.fromSnapshot(q.docs.first);
        } else {
          // Fallback partial match (e.g. "VELORA AeroPulse R1 và 1 sản phẩm khác")
          final allSnap = await db.collection('Products').limit(120).get();
          final tLower = msg.productTitle.trim().toLowerCase();
          for (final d in allSnap.docs) {
            final p = ProductModel.fromSnapshot(d);
            final pLower = p.title.trim().toLowerCase();
            if (pLower.isNotEmpty &&
                (tLower.contains(pLower) || pLower.contains(tLower))) {
              found = p;
              break;
            }
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    if (found == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin sản phẩm này trong kho.'),
        ),
      );
      return;
    }
    if (found.isDiscontinued) {
      ProductAvailabilityHelper.showDiscontinuedSheet(context, found.title);
      return;
    }
    Get.to(() => ProductDetail(product: found!));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0.0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final user =
        Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;

    final contextBanner = _hasActiveContext ? Container(
                      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                      padding: const EdgeInsets.all(12),
                      decoration: ShopGlassDecoration(
                        color: dark
                            ? const Color(0xFF1A2D24)
                            : const Color(0xFFEFF6F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF173E32).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_contextThumbnail.isNotEmpty) ...[
                            TRoundedImage(
                              imageUrl: _contextThumbnail,
                              width: 48,
                              height: 48,
                              isNetworkImage: true,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _returnReq != null
                                      ? 'Đang trao đổi về Yêu cầu Đổi / Trả:'
                                      : (_order != null
                                          ? 'Đang trao đổi về Đơn hàng:'
                                          : 'Đang hỏi tư vấn mẫu giày:'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _contextProductTitle,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (_contextSummary.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _contextSummary,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: dark
                                          ? Colors.white70
                                          : const Color(0xFF475569),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                setState(() => _contextAttached = false),
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                        ],
                      ),
                    ) : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ShopChatBackground(child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: TAppbar(
          showBackArrow: !widget.embeddedInNav,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chat trực tiếp với VELORA',
                style: shopAppbarTitleStyle,
              ),
            ],
          ),
        ),
        body: user == null || _messagesStream == null
            ? const Center(
                child: Text('Vui lòng đăng nhập để nhắn tin với VELORA.'),
              )
            : Column(
                children: [


                  Expanded(
                    child: Stack(
                      children: [
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _messagesStream,
                          builder: (context, snapshot) {
                            final docs = snapshot.data?.docs ?? const [];
                            final messages = docs
                                .map(SupportChatMessageModel.fromSnapshot)
                                .toList();

                            if (messages.isNotEmpty && messages.last.isAdmin) {
                              _markCustomerRead();
                            }

                            final reversed = messages.reversed.toList();
                            return ListView.builder(
                              controller: _scroll,
                              reverse: true,
                              physics: const ClampingScrollPhysics(),
                              padding: shopAppbarContentPadding(context, const EdgeInsets.fromLTRB(16, 14, 16, 18)),
                              itemCount: reversed.length + 1 + (contextBanner == null ? 0 : 1),
                              itemBuilder: (_, index) {
                                if (index > reversed.length) return contextBanner!;
                                if (index == reversed.length) {
                                  return _buildAdminWelcomeCard(dark);
                                }
                                return _buildMessageBubble(
                                  reversed[index],
                                  dark,
                                );
                              },
                            );
                          },
                        ),
                        // Floating Scroll-to-Latest Button at bottom-right
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: AnimatedScale(
                            scale: _showScrollToLatest ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutBack,
                            child: AnimatedOpacity(
                              opacity: _showScrollToLatest ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 160),
                              child: Material(
                                color: dark
                                    ? const Color(0xFF1F3B30)
                                    : const Color(0xFF173E32),
                                elevation: 5,
                                shadowColor:
                                    Colors.black.withValues(alpha: 0.28),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _scrollToBottom,
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFDDEABB)
                                            .withValues(alpha: 0.45),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFFDDEABB),
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    height: 44,
                    decoration: ShopGlassDecoration(
                      color: dark
                          ? const Color(0xFF15241D)
                          : const Color(0xFFF0F4F1),
                      border: Border(
                        top: BorderSide(
                          color: dark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      itemCount: _quickChips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final chip = _quickChips[i];
                        return ActionChip(
                          onPressed: () => _sendMessage(presetText: chip),
                          backgroundColor:
                              dark ? const Color(0xFF1E3229) : Colors.white,
                          side: BorderSide(
                            color: const Color(0xFF173E32)
                                .withValues(alpha: 0.25),
                          ),
                          label: Text(
                            chip,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? const Color(0xFFDDEABB)
                                  : const Color(0xFF173E32),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (_uploadingMedia) ...[
                    const LinearProgressIndicator(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _uploadingLabel,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF173E32),
                        ),
                      ),
                    ),
                  ],

                  SafeArea(
                    top: false,
                    bottom: !widget.embeddedInNav,
                    child: ShopGlass(
                      radius: 26,
                      margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                      padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Gửi Ảnh hoặc Video',
                            onPressed: _uploadingMedia
                                ? null
                                : _openMediaPickerSheet,
                            icon: const Icon(
                              Iconsax.gallery_add,
                              color: Color(0xFF173E32),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Gửi Video',
                            onPressed: _uploadingMedia
                                ? null
                                : () => _pickAndSendVideo(ImageSource.gallery),
                            icon: const Icon(
                              Iconsax.video_play,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _input,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              maxLines: 3,
                              minLines: 1,
                              decoration: const InputDecoration(
                                hintText: 'Nhắn tin cho VELORA',
                                hintStyle: TextStyle(fontSize: 12.5),
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ShopChatSendButton(onPressed: _sending ? null : () => _sendMessage()),
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

  Widget _buildAdminWelcomeCard(bool dark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: ShopGlassDecoration(
        color: dark ? const Color(0xFF1A2821) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF173E32).withValues(alpha: 0.2),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_rounded,
                size: 16,
                color: Color(0xFF173E32),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Kênh Chat riêng 1-1 với Quản trị viên VELORA',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF173E32),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Bạn có thể nhắn tin, gửi hình ảnh hoặc video thực tế đôi giày để trao đổi với VELORA về đơn hàng, đổi size (trong 7 ngày) hoặc cập nhật địa chỉ đổi mới.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(SupportChatMessageModel msg, bool dark) {
    final isCustomer = msg.isCustomer;
    final timeStr = DateFormat('dd/MM HH:mm').format(msg.createdAt);

    return Align(
      key: ValueKey(msg.id),
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: isCustomer
            ? BoxDecoration(
                color: const Color(0xFF173E32),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : ShopGlassDecoration(
                color: dark ? const Color(0xFF1D2F27) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: const Color(0xFF173E32).withValues(alpha: 0.22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCustomer) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF173E32),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'VELORA CSKH',
                      style: TextStyle(
                        color: Color(0xFFDDEABB),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            if (msg.hasContext) ...[
              InkWell(
                onTap: () => _openProductFromMessage(msg),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(9),
                  decoration: ShopGlassDecoration(
                    color: isCustomer
                        ? Colors.white.withValues(alpha: 0.14)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCustomer
                          ? Colors.white.withValues(alpha: 0.25)
                          : const Color(0xFF173E32).withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (msg.productThumbnail.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: CachedNetworkImage(
                            imageUrl: msg.productThumbnail,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 9),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.productTitle,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: isCustomer
                                    ? const Color(0xFFDDEABB)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            if (msg.contextSummary.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                msg.contextSummary,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.3,
                                  color: isCustomer
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Xem chi tiết sản phẩm',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isCustomer
                                        ? const Color(0xFFDDEABB)
                                        : const Color(0xFF173E32),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: isCustomer
                                      ? const Color(0xFFDDEABB)
                                      : const Color(0xFF173E32),
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
            ],
            if (msg.hasImage) ...[
              GestureDetector(
                onTap: () => _openImageViewer(msg.imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: msg.imageUrl,
                    width: 220,
                    height: 165,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            if (msg.hasVideo) ...[
              GestureDetector(
                onTap: () => _openVideoPlayer(msg.videoUrl),
                child: Container(
                  width: 220,
                  height: 135,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2920),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFDDEABB).withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: Color(0xFFDDEABB),
                        size: 46,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Bấm để xem Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              msg.text,
              style: TextStyle(
                color: isCustomer
                    ? Colors.white
                    : (dark ? Colors.white : const Color(0xFF0F172A)),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            if (isCustomer) ...[
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatVideoPlayerDialog extends StatefulWidget {
  const _ChatVideoPlayerDialog({required this.videoUrl});
  final String videoUrl;

  @override
  State<_ChatVideoPlayerDialog> createState() => _ChatVideoPlayerDialogState();
}

class _ChatVideoPlayerDialogState extends State<_ChatVideoPlayerDialog> {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final ctrl =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _ctrl = ctrl;
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.play();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Không thể phát video: $e');
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                ),
              )
            else if (_ready && _ctrl != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_ctrl!.value.isPlaying) {
                      _ctrl!.pause();
                    } else {
                      _ctrl!.play();
                    }
                  });
                },
                child: AspectRatio(
                  aspectRatio: _ctrl!.value.aspectRatio > 0
                      ? _ctrl!.value.aspectRatio
                      : 9 / 16,
                  child: VideoPlayer(_ctrl!),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Color(0xFFDDEABB)),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: ShopGlassIconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icons.close_rounded,
                iconColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
