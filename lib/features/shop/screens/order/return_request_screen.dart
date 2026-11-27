import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:fashion_business_app/common/widgets/tabs/shop_tab_body.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/tabs/shop_filter_tab.dart';
import 'package:fashion_business_app/common/widgets/product/badges/shop_status_badge.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/data/repositories/orders/orders_repository.dart';
import 'package:fashion_business_app/data/services/image_storage_service.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/models/return_request_model.dart';
import 'package:fashion_business_app/features/shop/screens/support_chat/velora_support_chat_screen.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// Returns how many days are left in VELORA's 7-day Return & Exchange window (0..7).
/// Returns negative if the 7-day window has expired.
int returnWindowDaysLeft(OrderModel order) {
  final refDate = order.deliveryDate.isAfter(order.orderDate)
      ? order.deliveryDate
      : order.orderDate;
  final daysElapsed = DateTime.now().difference(refDate).inDays;
  return 7 - (daysElapsed < 0 ? 0 : daysElapsed);
}

bool isOrderEligibleForReturn(OrderModel order) {
  if (order.status != OrderStatus.received) return false;
  return returnWindowDaysLeft(order) >= 0;
}

/// Opens the Return / Exchange Request Sheet for a specific item in a delivered order.
Future<bool?> openReturnRequestComposer(
  BuildContext context, {
  required OrderModel order,
  required CartItemModel item,
}) {
  if (!isOrderEligibleForReturn(order)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đơn hàng đã quá thời hạn hỗ trợ Đổi / Trả trong 7 ngày kể từ ngày nhận hàng.',
        ),
      ),
    );
    return Future.value(false);
  }
  return showShopBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ReturnRequestComposerSheet(order: order, item: item),
  );
}

class ReturnRequestComposerSheet extends StatefulWidget {
  const ReturnRequestComposerSheet({
    super.key,
    required this.order,
    required this.item,
  });

  final OrderModel order;
  final CartItemModel item;

  @override
  State<ReturnRequestComposerSheet> createState() =>
      _ReturnRequestComposerSheetState();
}

class _ReturnRequestComposerSheetState
    extends State<ReturnRequestComposerSheet> {
  final _picker = ImagePicker();
  final _storage = ImageStorageService(
    cloudName: 'lbbgn51d',
    uploadPreset: 'fashion_shop',
  );
  final _descCtrl = TextEditingController();
  late final TextEditingController _pickupCtrl;
  late final TextEditingController _phoneCtrl;

  ReturnRequestType _type = ReturnRequestType.exchangeSize;
  String _selectedReason = 'Giao sai kích cỡ (Size EU)';
  String _targetSize = 'EU 41';
  final List<String> _imageUrls = [];
  final List<String> _videoUrls = [];
  bool _uploading = false;
  bool _submitting = false;
  String? _error;

  static const List<String> _reasons = [
    'Giao sai kích cỡ (Size EU)',
    'Mang thực tế bị chật / rộng mũi chân',
    'Lỗi keo đế / đường chỉ / bề mặt da',
    'Giao sai màu hoặc sai mẫu giày',
    'Hộp & giày bị móp méo khi vận chuyển',
  ];

  static const List<String> _euSizes = [
    'EU 38',
    'EU 39',
    'EU 40',
    'EU 41',
    'EU 42',
    'EU 43',
    'EU 44',
  ];

  @override
  void initState() {
    super.initState();
    final addr = widget.order.address;
    _pickupCtrl = TextEditingController(
      text: addr != null && addr.toString().trim().isNotEmpty
          ? addr.toString().trim()
          : 'Cầu Giấy, Hà Nội',
    );
    _phoneCtrl = TextEditingController(
      text: addr?.phoneNumber.trim().isNotEmpty == true
          ? addr!.phoneNumber.trim()
          : (Get.isRegistered<UserController>()
              ? UserController.instance.user.value.phoneNumber
              : '0901234567'),
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _pickupCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() {
      _uploading = true;
      _error = null;
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
        'Returns/Images',
        bytes,
        file.name.isNotEmpty
            ? file.name
            : 'return_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (mounted) setState(() => _imageUrls.add(url));
    } catch (e) {
      if (mounted) setState(() => _error = 'Không thể tải ảnh: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    setState(() {
      _uploading = true;
      _error = null;
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
        'Returns/Videos',
        bytes,
        file.name.isNotEmpty
            ? file.name
            : 'return_vid_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      if (mounted) setState(() => _videoUrls.add(url));
    } catch (e) {
      if (mounted) setState(() => _error = 'Không thể tải video: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting || _uploading) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Vui lòng đăng nhập để gửi yêu cầu đổi trả.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final db = FirebaseFirestore.instance;
      final reqId =
          'RET-${widget.order.id.substring(0, widget.order.id.length.clamp(0, 6)).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      final customerName = Get.isRegistered<UserController>() &&
              UserController.instance.user.value.fullName.trim().isNotEmpty
          ? UserController.instance.user.value.fullName.trim()
          : (widget.order.address?.name.trim().isNotEmpty == true
              ? widget.order.address!.name.trim()
              : (user.displayName ??
                  user.email?.split('@').first ??
                  'Khách hàng VELORA'));
      final currentVar = (widget.item.selectedVariation?.entries ?? const [])
          .map((e) => '${e.key}: ${e.value}')
          .join(' · ');

      String adminResponse = '';
      ReturnRequestStatus initialStatus = ReturnRequestStatus.pending;
      try {
        final autoSnap =
            await db.collection('Settings').doc('AdminAutomation').get();
        final autoData = autoSnap.data() ?? const <String, dynamic>{};
        final autoApprove = autoData['autoReturnReply'] == true;
        final rawTpl = (autoData['templateReturnReply'] as String?)?.trim();
        final tpl = (rawTpl != null && rawTpl.isNotEmpty)
            ? rawTpl
            : 'VELORA CSKH đã tiếp nhận yêu cầu {type} cho mẫu {product} của {name}. Đội ngũ kỹ thuật Kho Hà Nội sẽ ưu tiên xử lý và điều Shipper thu hồi/đổi mới miễn phí tận nơi cho bạn trong 24h!';
        adminResponse = tpl
            .replaceAll('{name}', customerName)
            .replaceAll('{product}', widget.item.title)
            .replaceAll('{type}', ReturnRequestModel.typeLabelOf(_type))
            .replaceAll(
              '{newSize}',
              _type == ReturnRequestType.exchangeSize
                  ? _targetSize
                  : 'đôi mới 1-1',
            );
        if (autoApprove) {
          initialStatus = ReturnRequestStatus.approvedPickup;
        }
      } catch (_) {}

      final request = ReturnRequestModel(
        id: reqId,
        orderId: widget.order.id,
        userId: user.uid,
        customerName: customerName,
        customerEmail: user.email ?? '',
        customerPhone: _phoneCtrl.text.trim(),
        pickupAddress: _pickupCtrl.text.trim(),
        productId: widget.item.productId,
        productTitle: widget.item.title,
        productThumbnail: widget.item.image ?? '',
        refundAmountUsd: widget.item.price * widget.item.quantity,
        quantity: widget.item.quantity,
        currentVariation: currentVar,
        requestedSizeOrColor: _type == ReturnRequestType.exchangeSize
            ? 'Đổi sang $_targetSize'
            : (_type == ReturnRequestType.defectiveExchange
                ? 'Đổi đôi mới 1-1 cùng mẫu'
                : 'Trả hàng & Hoàn tiền 100%'),
        type: _type,
        reasonCategory: _selectedReason,
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : _selectedReason,
        imageUrls: _imageUrls,
        videoUrls: _videoUrls,
        status: initialStatus,
        adminResponse: adminResponse,
        createdAt: DateTime.now(),
      );

      await db.collection('ReturnRequests').doc(reqId).set(request.toMap());

      final notifId = 'return-$reqId';
      await db
          .collection('Users')
          .doc(user.uid)
          .collection('Notifications')
          .doc(notifId)
          .set({
        'id': notifId,
        'kind': 'return',
        'targetId': reqId,
        if ((widget.item.image ?? '').isNotEmpty) 'imageUrl': widget.item.image,
        'titleVi':
            'Đã tiếp nhận yêu cầu ${request.typeLabel()}: ${widget.item.title}',
        'titleEn': 'Return/Exchange request received: ${widget.item.title}',
        'bodyVi': adminResponse.isNotEmpty
            ? adminResponse
            : 'Bộ phận Đổi trả & Bảo hành VELORA đang xử lý yêu cầu của bạn.',
        'bodyEn': 'VELORA Return & Exchange Center is processing your request.',
        'read': false,
        'pushPending': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pop(true);
      Get.snackbar(
        'Đã gửi yêu cầu Đổi / Trả',
        'Đã ghi nhận yêu cầu cho "${widget.item.title}". Bạn có thể theo dõi trong mục Đổi trả.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF111827),
        colorText: Colors.white,
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Không thể gửi yêu cầu: $e');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final isEn = locale == 'en';
    final item = widget.item;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn
                            ? 'Return / Exchange Request'
                            : 'Yêu cầu Đổi / Trả hàng',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: TColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEn
                            ? 'Supported within 7 days of delivery'
                            : 'Áp dụng trong vòng 7 ngày kể từ ngày nhận hàng',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                ShopGlassIconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icons.close_rounded,
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFE5E7EB)),

            // Product summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: ShopGlassDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  TRoundedImage(
                    imageUrl: item.image ?? '',
                    width: 56,
                    height: 56,
                    borderRadius: 8,
                    isNetworkImage: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          softWrap: true,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: TColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'x${item.quantity} · ${formatShopMoney(item.price * item.quantity, language: locale)}'
                          '${(item.selectedVariation?.entries ?? []).isNotEmpty ? ' · ${(item.selectedVariation?.entries ?? []).map((e) => '${e.key}: ${e.value}').join(' · ')}' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. Return / Exchange Type (clean monochrome selection cards)
            const Text(
              'Hình thức hỗ trợ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: TColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            for (final t in ReturnRequestType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _type = t),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: ShopGlassDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _type == t
                            ? TColors.primaryColor
                            : const Color(0xFFE2E8F0),
                        width: _type == t ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ReturnRequestModel.typeLabelOf(
                                  t,
                                  english: isEn,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                  color: TColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t == ReturnRequestType.exchangeSize
                                    ? 'Đổi sang size EU vừa chân hơn miễn phí'
                                    : t == ReturnRequestType.defectiveExchange
                                        ? 'Đổi 1 đôi mới cùng mẫu từ kho Hà Nội'
                                        : 'Hoàn lại ${formatShopMoney(item.price * item.quantity, language: locale)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<ReturnRequestType>(
                          value: t,
                          groupValue: _type,
                          activeColor: TColors.primaryColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) {
                            if (v != null) setState(() => _type = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_type == ReturnRequestType.exchangeSize) ...[
              const SizedBox(height: 8),
              const Text(
                'Size EU muốn đổi sang',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _euSizes.map((sz) {
                  final sel = _targetSize == sz;
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _targetSize = sz),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: ShopGlassDecoration(
                        color: sel ? TColors.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel
                              ? TColors.primaryColor
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        sz,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : TColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),

            // 2. Reason selector
            const Text(
              'Lý do đổi / trả',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: TColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasons.map((r) {
                final sel = _selectedReason == r;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _selectedReason = r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: ShopGlassDecoration(
                      color: sel ? TColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel
                            ? TColors.primaryColor
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      r,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: sel ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Ghi chú chi tiết (tùy chọn)',
                hintText: 'Mô tả thêm về tình trạng giày hoặc size cần đổi...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Photos / Videos
            const Text(
              'Ảnh / Video thực tế',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: TColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _uploading
                      ? null
                      : () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Iconsax.camera, size: 15),
                  label: const Text('Chụp ảnh', style: TextStyle(fontSize: 12)),
                ),
                OutlinedButton.icon(
                  onPressed: _uploading
                      ? null
                      : () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Iconsax.gallery, size: 15),
                  label: const Text('Chọn ảnh', style: TextStyle(fontSize: 12)),
                ),
                OutlinedButton.icon(
                  onPressed: _uploading
                      ? null
                      : () => _pickVideo(ImageSource.camera),
                  icon: const Icon(Iconsax.video, size: 15),
                  label:
                      const Text('Quay video', style: TextStyle(fontSize: 12)),
                ),
                OutlinedButton.icon(
                  onPressed: _uploading
                      ? null
                      : () => _pickVideo(ImageSource.gallery),
                  icon: const Icon(Iconsax.video_play, size: 15),
                  label:
                      const Text('Chọn video', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (_uploading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(color: TColors.textPrimary),
            ],
            if (_imageUrls.isNotEmpty || _videoUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (int i = 0; i < _imageUrls.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: _imageUrls[i],
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _imageUrls.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (int i = 0; i < _videoUrls.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: TColors.textPrimary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _videoUrls.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 4. Address
            const Text(
              'Địa chỉ nhận hàng đổi / thu hồi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: TColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pickupCtrl,
              maxLines: 2,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Nhập địa chỉ nhận đôi giày đổi mới...',
                prefixIcon: const Icon(Iconsax.location, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF173E32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _submitting
                      ? 'Đang gửi yêu cầu...'
                      : 'Gửi yêu cầu ${ReturnRequestModel.typeLabelOf(_type, english: isEn)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Customer screen listing all Return & Exchange requests with clean minimal UI.
class MyReturnRequestsScreen extends StatefulWidget {
  const MyReturnRequestsScreen({super.key, this.highlightRequestId, this.requests});

  final Stream<List<ReturnRequestModel>>? requests;

  final String? highlightRequestId;

  @override
  State<MyReturnRequestsScreen> createState() => _MyReturnRequestsScreenState();
}

class _MyReturnRequestsScreenState extends State<MyReturnRequestsScreen> {
  String _filter = 'all'; // 'all' | 'pending' | 'active' | 'completed'
  Stream<List<ReturnRequestModel>>? _returnsStream;

  @override
  void initState() {
    super.initState();
    if (widget.requests != null) {
      _returnsStream = widget.requests;
      return;
    }
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    if (user != null) {
      _returnsStream = FirebaseFirestore.instance
          .collection('ReturnRequests')
          .where('userId', isEqualTo: user.uid)
          .snapshots().map((snapshot) => snapshot.docs.map(ReturnRequestModel.fromSnapshot).toList());
    }
  }

  Future<void> _openCreateFromOrderPicker() async {
    final orders = await OrderRepository()
        .fetchUserOrders()
        .catchError((_) => <OrderModel>[]);
    final delivered =
        orders.where((o) => o.status == OrderStatus.received).toList();
    if (!mounted) return;
    if (delivered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chỉ các đơn hàng Đã giao thành công trong vòng 7 ngày mới có thể tạo yêu cầu Đổi / Trả.',
          ),
        ),
      );
      return;
    }

    await showShopBottomSheet<void>(
      context: context,

      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          children: [
            const Text(
              'Chọn sản phẩm từ đơn đã nhận',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            for (final ord in delivered)
              for (final item in ord.items)
                Builder(builder: (_) {
                  final daysLeft = returnWindowDaysLeft(ord);
                  final eligible = daysLeft >= 0;
                  return Opacity(
                    opacity: eligible ? 1.0 : 0.5,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: TRoundedImage(
                        imageUrl: item.image ?? '',
                        width: 52,
                        height: 52,
                        isNetworkImage: true,
                      ),
                      title: Text(
                        item.title,
                        softWrap: true,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      subtitle: Text(
                        eligible
                            ? '${DateFormat('dd/MM/yyyy').format(ord.orderDate)} · Còn $daysLeft ngày đổi trả'
                            : '${DateFormat('dd/MM/yyyy').format(ord.orderDate)} · Đã quá hạn 7 ngày',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF64748B),
                      ),
                      onTap: () async {
                        Navigator.of(sheetCtx).pop();
                        await openReturnRequestComposer(
                          context,
                          order: ord,
                          item: item,
                        );
                      },
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isEn = locale == 'en';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: TAppbar(
        showBackArrow: true,
        title: Text(
          isEn ? 'Returns' : 'Đổi trả',
          style: shopAppbarTitleStyle,
        ),
        actions: [
          ShopGlassIconButton(
            tooltip: 'Chat trực tiếp với VELORA',
            onPressed: () => Get.to(() => const VeloraSupportChatScreen()),
            icon: Iconsax.message_text_1,
          ),
          ShopGlassIconButton(
            tooltip: 'Tạo yêu cầu đổi trả mới',
            onPressed: _openCreateFromOrderPicker,
            icon: Iconsax.add,
          ),
        ],
      ),
      body: _returnsStream == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem đổi trả.'))
          : StreamBuilder<List<ReturnRequestModel>>(
              stream: _returnsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TColors.primaryColor,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Padding(padding: const EdgeInsets.all(24),
                    child: Text(isEn ? 'Couldn’t load return requests. Please try again.'
                      : 'Chưa tải được yêu cầu đổi trả. Vui lòng thử lại.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF52635C)))));
                }
                final all = List<ReturnRequestModel>.of(snapshot.data ?? const [])
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                final pendingCount = all
                    .where((e) => e.status == ReturnRequestStatus.pending)
                    .length;
                final activeCount = all
                    .where((e) =>
                        e.status == ReturnRequestStatus.approvedPickup ||
                        e.status == ReturnRequestStatus.inspecting)
                    .length;
                final completedCount = all
                    .where((e) =>
                        e.status == ReturnRequestStatus.completed ||
                        e.status == ReturnRequestStatus.rejected)
                    .length;

                final filtered = all.where((r) {
                  if (_filter == 'pending') {
                    return r.status == ReturnRequestStatus.pending;
                  }
                  if (_filter == 'active') {
                    return r.status == ReturnRequestStatus.approvedPickup ||
                        r.status == ReturnRequestStatus.inspecting;
                  }
                  if (_filter == 'completed') {
                    return r.status == ReturnRequestStatus.completed ||
                        r.status == ReturnRequestStatus.rejected;
                  }
                  return true;
                }).toList();

                final tabs = [
                  ('all', isEn ? 'All' : 'Tất cả', all.length),
                  ('pending', isEn ? 'Pending' : 'Chờ duyệt', pendingCount),
                  ('active', isEn ? 'In progress' : 'Đang xử lý', activeCount),
                  ('completed', isEn ? 'Completed' : 'Hoàn tất', completedCount),
                ];

                return ShopScrollUnderHeader(
            header: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ShopFilterTabs(tabs: tabs.map((tab) {
                          final (key, label, count) = tab;
                          return ShopFilterTab(label: label, count: count,
                            selected: _filter == key,
                            onTap: () => setState(() => _filter = key));
                      }).toList()),
                    )]),
            body: ShopTabBody(index: tabs.indexWhere((tab) => tab.$1 == _filter),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          // Return policy and the action to create a request.
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: ShopGlassDecoration(
                              color: const Color(0xFFF6F8F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEn
                                            ? '7-day Size Exchange & Return'
                                            : 'Đổi size & Trả hàng trong 7 ngày',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: TColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        isEn
                                            ? 'Free size exchange or 100% refund for delivered orders.'
                                            : 'Đổi size EU 38–44, đổi mới 1-1 hoặc hoàn tiền từ đơn đã nhận.',
                                        style: const TextStyle(
                                          fontSize: 13, height: 1.45,
                                          color: Color(0xFF3E4943),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: _openCreateFromOrderPicker,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF173E32),
                                    side: const BorderSide(
                                      color: Color(0xFF4D6A5C),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    isEn ? 'New request' : 'Tạo yêu cầu',
                                    style: const TextStyle(
                                      fontSize: 13, height: 1.45,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 64),
                              child: Column(
                                children: [
                                  Icon(
                                    Iconsax.refresh_circle,
                                    size: 46,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    isEn
                                        ? 'No return requests'
                                        : 'Chưa có yêu cầu đổi trả nào',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: TColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isEn
                                        ? 'Requests from your delivered orders will appear here.'
                                        : 'Bạn có thể tạo yêu cầu đổi size hoặc trả hàng từ đơn đã nhận.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF46524B),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            for (final req in filtered)
                              ReturnRequestTrackingCard(
                                request: req,
                                highlighted:
                                    widget.highlightRequestId == req.id,
                              ),
                        ],
                      )),
          );
              },
            ),
    );
  }
}

/// A return request with its current status and four-step tracking history.
class ReturnRequestTrackingCard extends StatelessWidget {
  const ReturnRequestTrackingCard({
    super.key,
    required this.request,
    this.highlighted = false,
  });

  final ReturnRequestModel request;
  final bool highlighted;

  Widget _singleStatusBadge(bool isEn) => ShopStatusBadge(
    label: switch (request.status) {
      ReturnRequestStatus.pending => isEn ? 'Awaiting review' : 'Chờ duyệt',
      ReturnRequestStatus.approvedPickup => isEn ? 'Awaiting pickup' : 'Chờ lấy hàng',
      ReturnRequestStatus.inspecting => isEn ? 'Inspecting' : 'Đang kiểm tra',
      ReturnRequestStatus.completed => isEn ? 'Completed' : 'Hoàn tất',
      ReturnRequestStatus.rejected => isEn ? 'Declined' : 'Từ chối',
    },
    tone: switch (request.status) {
      ReturnRequestStatus.pending => ShopStatusTone.pending,
      ReturnRequestStatus.completed => ShopStatusTone.success,
      ReturnRequestStatus.rejected => ShopStatusTone.error,
      _ => ShopStatusTone.progress,
    },
  );

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isEn = locale == 'en';
    final rejected = request.status == ReturnRequestStatus.rejected;
    final step = request.stepIndex;

    final stepLabels = isEn
        ? ['Submitted', 'Pickup', 'Inspecting', 'Completed']
        : ['Đã gửi', 'Lấy hàng', 'Kiểm định', 'Hoàn tất'];

    final typeAndDetail = (request.requestedSizeOrColor.trim().isNotEmpty &&
            request.requestedSizeOrColor.trim() !=
                request.typeLabel(english: isEn).trim())
        ? '${request.typeLabel(english: isEn)} · ${request.requestedSizeOrColor}'
        : request.typeLabel(english: isEn);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: ShopGlassDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? TColors.primaryColor
              : const Color(0xFFE5E7EB),
          width: highlighted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: double.infinity, child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12, runSpacing: 10,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(request.id, style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700, color: TColors.textPrimary)),
                const SizedBox(height: 4),
                Text(DateFormat('dd/MM/yyyy · HH:mm').format(request.createdAt),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF46524B))),
              ]),
              _singleStatusBadge(isEn),
            ],
          )),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Product and requested exchange details.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: ShopGlassDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: TRoundedImage(
                  imageUrl: request.productThumbnail,
                  width: 72,
                  height: 72,
                  borderRadius: 8,
                  isNetworkImage: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.productTitle,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 15, height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: TColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      typeAndDetail,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF34413A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!rejected) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: ShopGlassDecoration(color: const Color(0xFFF3F7F4),
                borderRadius: BorderRadius.circular(12)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(4, (i) {
                  final active = (i + 1) <= step;
                  final current = (i + 1) == step;
                  final done = active && (!current || request.status == ReturnRequestStatus.completed);
                  return Expanded(child: Column(children: [
                    Container(width: 26, height: 26,
                      decoration: ShopGlassDecoration(shape: BoxShape.circle,
                        color: active ? const Color(0xFF173E32) : Colors.white,
                        border: Border.all(color: active ? TColors.primaryColor : const Color(0xFFD4DFD7))),
                      alignment: Alignment.center,
                      child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : Text('${i + 1}', style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : const Color(0xFF46524B)))),
                    const SizedBox(height: 7),
                    Text(stepLabels[i], textAlign: TextAlign.center, softWrap: true,
                      style: TextStyle(fontSize: 11.5, height: 1.4,
                        fontWeight: current ? FontWeight.w700 : FontWeight.w600,
                        color: current ? const Color(0xFF173E32) : active ? TColors.textPrimary : const Color(0xFF64736B))),
                  ]));
                }),
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Text(
            '${isEn ? 'Reason' : 'Lý do'}: ${request.reasonCategory}'
            '${request.description.isNotEmpty && request.description != request.reasonCategory ? ' — ${request.description}' : ''}',
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF333333),
              height: 1.5,
            ),
          ),
          if (request.pickupAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${isEn ? 'Pickup address' : 'Địa chỉ nhận đổi'}: ${request.pickupAddress}',
              style: const TextStyle(
                fontSize: 13, height: 1.5,
                color: Color(0xFF46524B),
              ),
            ),
          ],

          if (request.hasMedia) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final img in request.imageUrls)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: img,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  for (var i = 0; i < request.videoUrls.length; i++)
                    Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: TColors.textPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Latest response from customer support.
          if (request.hasAdminResponse) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: ShopGlassDecoration(
                color: const Color(0xFFEAF2ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Reply from VELORA' : 'Phản hồi từ VELORA',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.adminResponse,
                    style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w500,
                      color: TColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Get.to(
                () => VeloraSupportChatScreen(initialReturnRequest: request),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF173E32),
                minimumSize: const Size(0, 44),
                side: const BorderSide(color: Color(0xFF4D6A5C)),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Iconsax.message_text_1, size: 15),
              label: Text(
                isEn
                    ? 'Contact VELORA Support'
                    : 'Liên hệ CSKH về yêu cầu này',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
