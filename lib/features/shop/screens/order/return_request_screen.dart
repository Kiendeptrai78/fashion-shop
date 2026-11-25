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
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
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

      // Check AdminAutomation for auto-response template
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
            .replaceAll(
              '{type}',
              ReturnRequestModel.typeLabelOf(_type),
            )
            .replaceAll(
              '{newSize}',
              _type == ReturnRequestType.exchangeSize ? _targetSize : 'đôi mới 1-1',
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

      // Send confirmation notification to user's Notification inbox
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
        'titleEn':
            'Return/Exchange request received: ${widget.item.title}',
        'bodyVi': adminResponse.isNotEmpty
            ? adminResponse
            : 'Bộ phận Đổi trả & Bảo hành VELORA đang xử lý yêu cầu của bạn.',
        'bodyEn':
            'VELORA Return & Exchange Center is processing your request.',
        'read': false,
        'pushPending': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pop(true);
      Get.snackbar(
        'Đã gửi yêu cầu Đổi / Trả thành công',
        'VELORA CSKH đã tiếp nhận yêu cầu cho "${widget.item.title}". Bạn có thể theo dõi tiến trình ngay trong mục Đổi trả & Bảo hành.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF173E32),
        colorText: Colors.white,
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 4),
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
    final dark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final isEn = locale == 'en';
    final item = widget.item;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.refresh_circle,
                    color: Color(0xFF0284C7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn
                            ? 'Return & Exchange Request'
                            : 'Yêu cầu Đổi trả & Bảo hành',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isEn
                            ? 'Free exchange delivery from VELORA Hanoi Warehouse'
                            : 'Hỗ trợ đổi mới tận nơi & Chat trực tiếp 1-1 với VELORA',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(height: 22),

            // Selected Product summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1A2721) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  TRoundedImage(
                    imageUrl: item.image ?? '',
                    width: 60,
                    height: 60,
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
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'SL: ${item.quantity} • ${formatShopMoney(item.price * item.quantity, language: locale)}'
                          '${(item.selectedVariation?.entries ?? []).isNotEmpty ? ' • ${(item.selectedVariation?.entries ?? []).map((e) => '${e.key}: ${e.value}').join(' · ')}' : ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. Choose Return / Exchange Type
            const Text(
              '1. Chọn hình thức hỗ trợ bạn mong muốn',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            for (final t in ReturnRequestType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _type = t),
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _type == t
                          ? ReturnRequestModel.typeColorOf(t)
                              .withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: _type == t
                            ? ReturnRequestModel.typeColorOf(t)
                            : const Color(0xFFCBD5E1),
                        width: _type == t ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          ReturnRequestModel.typeIconOf(t),
                          color: ReturnRequestModel.typeColorOf(t),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ReturnRequestModel.typeLabelOf(t,
                                    english: isEn),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: _type == t
                                      ? ReturnRequestModel.typeColorOf(t)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t == ReturnRequestType.exchangeSize
                                    ? 'Đổi sang size EU vừa chân hơn hoặc phối màu khác miễn phí'
                                    : t == ReturnRequestType.defectiveExchange
                                        ? 'Đổi ngay 1 đôi mới nguyên hộp từ Tổng Kho Hà Nội'
                                        : 'Hoàn lại 100% số tiền ${formatShopMoney(item.price * item.quantity, language: locale)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Radio<ReturnRequestType>(
                          value: t,
                          groupValue: _type,
                          activeColor: ReturnRequestModel.typeColorOf(t),
                          onChanged: (v) {
                            if (v != null) setState(() => _type = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Target EU Size selector when Exchange Size is selected
            if (_type == ReturnRequestType.exchangeSize) ...[
              const SizedBox(height: 10),
              const Text(
                'Chọn kích cỡ (Size EU) bạn muốn đổi sang:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _euSizes.map((sz) {
                  final sel = _targetSize == sz;
                  return ChoiceChip(
                    label: Text(
                      sz,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    selected: sel,
                    selectedColor: const Color(0xFF0284C7),
                    onSelected: (_) => setState(() => _targetSize = sz),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),

            // 2. Quick Reason Chips
            const Text(
              '2. Lý do đổi / trả sản phẩm',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasons.map((r) {
                final sel = _selectedReason == r;
                return ChoiceChip(
                  label: Text(
                    r,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : null,
                    ),
                  ),
                  selected: sel,
                  selectedColor: const Color(0xFF173E32),
                  onSelected: (_) => setState(() => _selectedReason = r),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Ghi chú chi tiết tình trạng sản phẩm (tùy chọn)',
                hintText:
                    'VD: Shop giao nhầm size 40 trong khi đơn mình đặt size 42, nhờ shop đổi giúp...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Upload Photos / Videos of Defect or Size Tag
            const Text(
              '3. Hình ảnh / Video thực tế (tem size, vết lỗi, hộp giày...)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
                  icon: const Icon(Iconsax.camera, size: 16),
                  label: const Text('Chụp ảnh', style: TextStyle(fontSize: 12)),
                ),
                OutlinedButton.icon(
                  onPressed: _uploading
                      ? null
                      : () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Iconsax.gallery, size: 16),
                  label: const Text('Chọn ảnh', style: TextStyle(fontSize: 12)),
                ),
                OutlinedButton.icon(
                  onPressed: _uploading
                      ? null
                      : () => _pickVideo(ImageSource.camera),
                  icon: const Icon(Iconsax.video, size: 16),
                  label:
                      const Text('Quay video', style: TextStyle(fontSize: 12)),
                ),
                OutlinedButton.icon(
                  onPressed: _uploading
                      ? null
                      : () => _pickVideo(ImageSource.gallery),
                  icon: const Icon(Iconsax.video_play, size: 16),
                  label:
                      const Text('Chọn video', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (_uploading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
            if (_imageUrls.isNotEmpty || _videoUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 76,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (int i = 0; i < _imageUrls.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: _imageUrls[i],
                                width: 76,
                                height: 76,
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
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: const Color(0xFF14352B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Color(0xFFDDEABB),
                                  size: 28,
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

            // 4. Exchange Address Only (No shipper phone needed)
            const Text(
              '4. Địa chỉ đổi mới (nơi nhận sản phẩm đổi mới)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pickupCtrl,
              maxLines: 2,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Địa chỉ đổi mới',
                hintText: 'Nhập địa chỉ nhận đôi giày đổi mới của bạn...',
                prefixIcon: const Icon(Iconsax.location, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Iconsax.message_text_1,
                    size: 16,
                    color: Color(0xFF173E32),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sau khi tiếp nhận yêu cầu, Admin VELORA sẽ nhắn tin riêng trực tiếp với bạn qua mục "Chat với VELORA" để thông báo chi tiết quá trình đổi mới.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF166534),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF173E32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Iconsax.send_2, size: 18),
                label: Text(
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

/// Customer screen listing all Return & Exchange requests + 4-step tracking.
class MyReturnRequestsScreen extends StatefulWidget {
  const MyReturnRequestsScreen({super.key, this.highlightRequestId});

  final String? highlightRequestId;

  @override
  State<MyReturnRequestsScreen> createState() => _MyReturnRequestsScreenState();
}

class _MyReturnRequestsScreenState extends State<MyReturnRequestsScreen> {
  String _filter = 'all'; // 'all' | 'pending' | 'active' | 'completed'
  Stream<QuerySnapshot<Map<String, dynamic>>>? _returnsStream;

  @override
  void initState() {
    super.initState();
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    if (user != null) {
      _returnsStream = FirebaseFirestore.instance
          .collection('ReturnRequests')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
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

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          children: [
            const Text(
              'Chọn sản phẩm từ đơn đã nhận (trong 7 ngày)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final ord in delivered)
              for (final item in ord.items)
                Builder(builder: (_) {
                  final daysLeft = returnWindowDaysLeft(ord);
                  final eligible = daysLeft >= 0;
                  return Opacity(
                    opacity: eligible ? 1.0 : 0.52,
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
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        eligible
                            ? 'Đặt ngày ${DateFormat('dd/MM/yyyy').format(ord.orderDate)} • Còn $daysLeft ngày đổi trả'
                            : 'Đặt ngày ${DateFormat('dd/MM/yyyy').format(ord.orderDate)} • Đã quá hạn đổi trả 7 ngày',
                        style: TextStyle(
                          fontSize: 12,
                          color: eligible
                              ? const Color(0xFF0284C7)
                              : const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        eligible
                            ? Iconsax.refresh_circle
                            : Icons.block_rounded,
                        color: eligible
                            ? const Color(0xFF0284C7)
                            : const Color(0xFFDC2626),
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
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    final locale = Localizations.localeOf(context).languageCode;
    final isEn = locale == 'en';

    return Scaffold(
      appBar: TAppbar(
        showBackArrow: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            isEn ? 'Returns & Exchanges' : 'Đổi trả & Bảo hành',
            style: const TextStyle(fontSize: 18.5, fontWeight: FontWeight.w700),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Chat trực tiếp với VELORA',
            onPressed: () => Get.to(() => const VeloraSupportChatScreen()),
            icon: const Icon(Iconsax.message_text_1),
          ),
          IconButton(
            tooltip: 'Tạo yêu cầu đổi trả mới',
            onPressed: _openCreateFromOrderPicker,
            icon: const Icon(Iconsax.add_circle),
          ),
        ],
      ),
      body: user == null || _returnsStream == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem đổi trả.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _returnsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final all = (snapshot.data?.docs ?? const [])
                    .map(ReturnRequestModel.fromSnapshot)
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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

                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    // Policy & Quick Action Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF102B23), Color(0xFF1A4638)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                color: Color(0xFFDDEABB),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Chính sách Đổi Size & Đổi trả trong 7 ngày VELORA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '• Hỗ trợ Đổi kích cỡ EU 38–44, Đổi mới 1-1 nếu lỗi/giao sai hoặc Hoàn tiền 100% trong vòng 7 ngày kể từ ngày nhận hàng.\n• Sau khi gửi yêu cầu, Admin VELORA sẽ thẩm định (duyệt hoặc từ chối kèm lý do) và nhắn tin trực tiếp với bạn qua mục Chat với VELORA.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _openCreateFromOrderPicker,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFDDEABB),
                                foregroundColor: const Color(0xFF102B23),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                              icon: const Icon(Iconsax.refresh_circle, size: 17),
                              label: const Text(
                                '+ Tạo yêu cầu Đổi Size / Trả hàng từ đơn đã nhận',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill('all', 'Tất cả (${all.length})'),
                          const SizedBox(width: 8),
                          _buildFilterPill(
                            'pending',
                            'Chờ duyệt (${all.where((e) => e.status == ReturnRequestStatus.pending).length})',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterPill(
                            'active',
                            'Đang thu hồi & Đổi mới (${all.where((e) => e.status == ReturnRequestStatus.approvedPickup || e.status == ReturnRequestStatus.inspecting).length})',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterPill(
                            'completed',
                            'Hoàn tất (${all.where((e) => e.status == ReturnRequestStatus.completed || e.status == ReturnRequestStatus.rejected).length})',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            const Icon(
                              Iconsax.refresh_circle,
                              size: 52,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Chưa có yêu cầu đổi trả nào',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Nếu đôi giày bạn nhận bị chật/rộng hoặc có lỗi, hãy bấm nút trên để yêu cầu Shipper đổi mới tận nơi.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                height: 1.4,
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
                );
              },
            ),
    );
  }

  Widget _buildFilterPill(String key, String label) {
    final sel = _filter == key;
    return GestureDetector(
      onTap: () {
        if (_filter != key) setState(() => _filter = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF173E32) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: sel ? const Color(0xFF173E32) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: sel ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

/// Reusable Return / Exchange Tracking Card used in both `MyReturnRequestsScreen` and `OrderDetail`.
class ReturnRequestTrackingCard extends StatelessWidget {
  const ReturnRequestTrackingCard({
    super.key,
    required this.request,
    this.highlighted = false,
  });

  final ReturnRequestModel request;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isEn = locale == 'en';
    final tone = request.statusColor;
    final bgTone = request.statusBgColor;
    final borderTone = request.statusBorderColor;
    final rejected = request.status == ReturnRequestStatus.rejected;
    final step = request.stepIndex;

    const stepColors = [
      Color(0xFFD97706), // 1. Gửi yêu cầu (Cam)
      Color(0xFF7C3AED), // 2. Shipper thu hồi (Tím)
      Color(0xFF0284C7), // 3. Kho HN đổi mới (Xanh dương)
      Color(0xFF16A34A), // 4. Hoàn tất (Xanh lá)
    ];
    final stepLabels = isEn
        ? ['Submitted', 'Pickup', 'Hanoi Hub', 'Completed']
        : ['Gửi yêu cầu', 'Lấy hàng', 'Kho Hà Nội', 'Hoàn tất'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? tone
              : borderTone.withValues(alpha: 0.65),
          width: highlighted ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge + Date (Wrap prevents horizontal overflow on narrow screens)
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: bgTone,
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: borderTone.withValues(alpha: 0.7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(request.statusIcon, size: 14, color: tone),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          request.statusLabel(english: isEn),
                          softWrap: true,
                          style: TextStyle(
                            color: tone,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(request.createdAt),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Product & Type Info
          Row(
            children: [
              TRoundedImage(
                imageUrl: request.productThumbnail,
                width: 60,
                height: 60,
                isNetworkImage: true,
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: ReturnRequestModel.typeColorOf(request.type)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            request.typeLabel(english: isEn),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color:
                                  ReturnRequestModel.typeColorOf(request.type),
                            ),
                          ),
                        ),
                        if (request.requestedSizeOrColor.trim().isNotEmpty &&
                            request.requestedSizeOrColor.trim() !=
                                request.typeLabel(english: isEn).trim())
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              request.requestedSizeOrColor,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.statusSubtitle(english: isEn),
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),

          // 4-Step Visual Return Progress Bar
          if (!rejected) ...[
            const SizedBox(height: 14),
            Row(
              children: List.generate(4, (i) {
                final active = (i + 1) <= step;
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 5,
                        margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: active
                              ? stepColors[i]
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        stepLabels[i],
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              (i + 1) == step ? FontWeight.w800 : FontWeight.w600,
                          color: active
                              ? stepColors[i]
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],

          const Divider(height: 22),
          Text(
            'Lý do: ${request.reasonCategory}'
            '${request.description.isNotEmpty && request.description != request.reasonCategory ? ' — "${request.description}"' : ''}',
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF1E293B),
            ),
          ),
          if (request.pickupAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '📍 Địa chỉ đổi mới: ${request.pickupAddress}',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],

          if (request.hasMedia) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final img in request.imageUrls)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: CachedNetworkImage(
                          imageUrl: img,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  for (var i = 0; i < request.videoUrls.length; i++)
                    Container(
                      width: 64,
                      height: 64,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14352B),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: Color(0xFFDDEABB),
                          size: 26,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Official VELORA CSKH Response
          if (request.hasAdminResponse) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8F5),
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: Color(0xFF173E32), width: 3.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF173E32),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'V',
                          style: TextStyle(
                            color: Color(0xFFDDEABB),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: Text(
                          'Phản hồi từ Trung tâm Đổi trả & Bảo hành VELORA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF173E32),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.adminResponse,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF1E293B),
                      height: 1.45,
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
                side: BorderSide(
                  color: const Color(0xFF173E32).withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Iconsax.message_text_1, size: 16),
              label: Text(
                isEn
                    ? 'Chat directly with VELORA about this exchange'
                    : 'Chat riêng với VELORA về yêu cầu đổi trả này',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
