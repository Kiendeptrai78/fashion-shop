import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/models/return_request_model.dart';
import 'package:fashion_business_app/features/shop/models/support_chat_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class AdminSupportChatView extends StatefulWidget {
  const AdminSupportChatView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminSupportChatView> createState() => _AdminSupportChatViewState();
}

class _AdminSupportChatViewState extends State<AdminSupportChatView> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _search = '';
  String _listMode = 'chats'; // 'chats' | 'unread' | 'all_users'
  String? _selectedUserId;
  String _selectedCustomerName = '';
  String _selectedCustomerEmail = '';
  bool _sending = false;
  bool _uploadingMedia = false;
  String _uploadingStatus = '';

  static const List<String> _adminQuickTemplates = [
    'Chào bạn! VELORA đã tiếp nhận thông tin đổi mới của bạn và đang chuẩn bị xuất đôi mới từ Tổng Kho Hà Nội về đúng địa chỉ đổi mới bạn cung cấp nhé!',
    'Đôi giày đổi mới của bạn đã được đóng gói & bàn giao vận chuyển từ Kho Hà Nội. Dự kiến bạn sẽ nhận được trong 1–2 ngày tới!',
    'VELORA đã hoàn tất xử lý yêu cầu Đổi trả / Hoàn tiền 100% cho bạn. Nếu cần hỗ trợ thêm, bạn cứ nhắn trực tiếp cho VELORA tại đây nhé ❤️',
    'Chào bạn, bạn vui lòng xác nhận lại kích cỡ EU và địa chỉ đổi mới giúp VELORA để kho gửi đôi mới đi ngay trong hôm nay nhé!',
  ];

  @override
  void initState() {
    super.initState();
    _consumePreselected();
  }

  void _consumePreselected() {
    final preId = widget.controller.preselectedChatUserId.value;
    if (preId != null && preId.isNotEmpty) {
      _selectedUserId = preId;
      _selectedCustomerName =
          widget.controller.preselectedChatCustomerName.value;
      _selectedCustomerEmail =
          widget.controller.preselectedChatCustomerEmail.value;
      final draft = widget.controller.preselectedChatDraft.value;
      if (draft.isNotEmpty && _msgCtrl.text.trim().isEmpty) {
        _msgCtrl.text = draft;
      }
      widget.controller.repository.markSupportChatReadByAdmin(preId);
      // Consume once so clicking another user in the sidebar always works!
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.controller.preselectedChatUserId.value == preId) {
          widget.controller.preselectedChatUserId.value = null;
        }
      });
    }
  }

  void _selectCustomer(
    String userId, {
    String name = '',
    String email = '',
  }) {
    widget.controller.preselectedChatUserId.value = null;
    setState(() {
      _selectedUserId = userId;
      _selectedCustomerName = name;
      _selectedCustomerEmail = email;
    });
    widget.controller.repository.markSupportChatReadByAdmin(userId);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({
    required String userId,
    required String customerName,
    required String customerEmail,
    String imageUrl = '',
    String videoUrl = '',
  }) async {
    final text = _msgCtrl.text.trim();
    if ((text.isEmpty && imageUrl.isEmpty && videoUrl.isEmpty) || _sending) {
      return;
    }
    setState(() => _sending = true);

    final c = widget.controller;
    final usePreContext = c.preselectedChatUserId.value == userId;
    final ok = await c.sendAdminSupportMessage(
      userId: userId,
      customerName: customerName,
      customerEmail: customerEmail,
      text: text,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      orderId: usePreContext ? c.preselectedChatOrderId.value : '',
      returnRequestId: usePreContext ? c.preselectedChatReturnId.value : '',
      productTitle: usePreContext ? c.preselectedChatProductTitle.value : '',
      productThumbnail: usePreContext ? c.preselectedChatProductThumb.value : '',
      contextSummary: usePreContext ? c.preselectedChatContextSummary.value : '',
    );

    if (ok) {
      _msgCtrl.clear();
      if (usePreContext) {
        c.preselectedChatDraft.value = '';
        c.preselectedChatOrderId.value = '';
        c.preselectedChatReturnId.value = '';
        c.preselectedChatProductTitle.value = '';
        c.preselectedChatProductThumb.value = '';
        c.preselectedChatContextSummary.value = '';
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _pickAndSendAdminImage({
    required String userId,
    required String customerName,
    required String customerEmail,
  }) async {
    if (_uploadingMedia) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty || picked.files.first.bytes == null) {
      return;
    }
    setState(() {
      _uploadingMedia = true;
      _uploadingStatus = 'Đang tải hình ảnh lên Cloudinary...';
    });
    try {
      final f = picked.files.first;
      final url = await widget.controller.uploadImage(
        f.bytes!,
        f.name.isNotEmpty
            ? f.name
            : 'admin_chat_${DateTime.now().millisecondsSinceEpoch}.jpg',
        'SupportChats/Images',
      );
      await _sendMessage(
        userId: userId,
        customerName: customerName,
        customerEmail: customerEmail,
        imageUrl: url,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingMedia = false;
          _uploadingStatus = '';
        });
      }
    }
  }

  Future<void> _pickAndSendAdminVideo({
    required String userId,
    required String customerName,
    required String customerEmail,
  }) async {
    if (_uploadingMedia) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty || picked.files.first.bytes == null) {
      return;
    }
    setState(() {
      _uploadingMedia = true;
      _uploadingStatus = 'Đang tải video (.mp4) lên Cloudinary...';
    });
    try {
      final f = picked.files.first;
      final url = await widget.controller.uploadVideo(
        f.bytes!,
        f.name.isNotEmpty
            ? f.name
            : 'admin_chat_vid_${DateTime.now().millisecondsSinceEpoch}.mp4',
        'SupportChats/Videos',
      );
      await _sendMessage(
        userId: userId,
        customerName: customerName,
        customerEmail: customerEmail,
        videoUrl: url,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải video: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingMedia = false;
          _uploadingStatus = '';
        });
      }
    }
  }

  void _openAdminImageZoom(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
          child: Stack(
            children: [
              InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAdminVideoPlayer(String videoUrl) {
    showDialog<void>(
      context: context,
      builder: (_) => _AdminChatVideoDialog(videoUrl: videoUrl),
    );
  }

  Future<void> _pickNewCustomerToChat() async {
    final clients = widget.controller.clientUsers;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chọn khách hàng để nhắn tin riêng 1-1',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AdminColors.border),
              Expanded(
                child: clients.isEmpty
                    ? const Center(
                        child: Text('Chưa có khách hàng nào trong hệ thống.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: clients.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AdminColors.border),
                        itemBuilder: (_, i) {
                          final u = clients[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AdminColors.sageSoft,
                              child: Text(
                                u.fullName.isNotEmpty
                                    ? u.fullName[0].toUpperCase()
                                    : 'K',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AdminColors.forest,
                                ),
                              ),
                            ),
                            title: Text(
                              u.fullName.isNotEmpty ? u.fullName : u.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            subtitle: Text(
                              u.email,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(
                              Iconsax.message_text_1,
                              color: AdminColors.forest,
                              size: 18,
                            ),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _selectCustomer(
                                u.id,
                                name: u.fullName.isNotEmpty
                                    ? u.fullName
                                    : u.email,
                                email: u.email,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAutoChatSettingsDialog() async {
    final c = widget.controller;
    final cfg = c.automation.value;
    final defaults = AdminAutomationSettings.defaults();
    var autoOrder = cfg.autoChatOnOrderStatus;
    var autoNewProduct = cfg.autoChatOnNewProduct;
    final orderTplCtrl = TextEditingController(text: cfg.templateChatOrderStatus);
    final productTplCtrl = TextEditingController(text: cfg.templateChatNewProduct);

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => Dialog(
          backgroundColor: AdminColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminColors.sageSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.flash_1,
                          color: AdminColors.forest,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cài đặt Auto Chat 1-1 với Khách hàng',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AdminColors.ink,
                              ),
                            ),
                            Text(
                              'Tự động nhắn tin riêng khi Đơn hàng đổi trạng thái hoặc khi lên kệ Sản phẩm mới.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AdminColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AdminColors.border),

                  // 1. Auto Chat on Order Status Change
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AdminColors.forest,
                    value: autoOrder,
                    onChanged: (v) => setModalState(() => autoOrder = v),
                    title: const Text(
                      'Tự động nhắn tin 1-1 khi Đơn hàng thay đổi trạng thái',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    subtitle: const Text(
                      'Tự động nhắn riêng cho khách khi đơn chuyển sang Đang đóng gói, Đang vận chuyển, Giao thành công hoặc Đã hủy.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mẫu tin nhắn Đơn hàng ({name}, {items}, {status}, {eta}):',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.inkSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            orderTplCtrl.text = defaults.templateChatOrderStatus,
                        child: const Text('Khôi phục mặc định',
                            style: TextStyle(fontSize: 11.5)),
                      ),
                    ],
                  ),
                  TextField(
                    controller: orderTplCtrl,
                    maxLines: 3,
                    decoration: adminInputDecoration(
                      label: 'Nội dung mẫu Auto Chat đơn hàng',
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Auto Chat on New Product Launch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AdminColors.forest,
                    value: autoNewProduct,
                    onChanged: (v) => setModalState(() => autoNewProduct = v),
                    title: const Text(
                      'Tự động nhắn tin giới thiệu khi thêm Sản phẩm mới',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    subtitle: const Text(
                      'Mỗi khi Admin thêm 1 mẫu giày mới vào kho, tự động nhắn tin 1-1 kèm ảnh giày tới khách hàng.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mẫu tin nhắn Sản phẩm mới ({name}, {product}, {category}, {price}):',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.inkSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            productTplCtrl.text = defaults.templateChatNewProduct,
                        child: const Text('Khôi phục mặc định',
                            style: TextStyle(fontSize: 11.5)),
                      ),
                    ],
                  ),
                  TextField(
                    controller: productTplCtrl,
                    maxLines: 3,
                    decoration: adminInputDecoration(
                      label: 'Nội dung mẫu Auto Chat sản phẩm mới',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 8),
                      AdminPrimaryButton(
                        label: 'Lưu cấu hình Auto Chat',
                        icon: Iconsax.tick_circle,
                        onPressed: () async {
                          final ok = await c.saveAutomationSettings(
                            cfg.copyWith(
                              autoChatOnOrderStatus: autoOrder,
                              templateChatOrderStatus: orderTplCtrl.text.trim(),
                              autoChatOnNewProduct: autoNewProduct,
                              templateChatNewProduct: productTplCtrl.text.trim(),
                            ),
                          );
                          if (ok && dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    orderTplCtrl.dispose();
    productTplCtrl.dispose();
  }

  Future<void> _openNewProductChatDialog() async {
    final c = widget.controller;
    final activeProducts =
        c.products.where((p) => !p.isDiscontinued).toList();
    if (activeProducts.isEmpty) return;

    ProductModel selectedProduct = activeProducts.first;
    String audience = _selectedUserId != null
        ? 'current'
        : 'all'; // 'current' | 'category' | 'all'
    final msgCtrl = TextEditingController(
      text: c.automation.value.templateChatNewProduct,
    );
    bool sending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => Dialog(
          backgroundColor: AdminColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminColors.skyBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.box,
                          color: AdminColors.sky,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gửi tin nhắn 1-1 giới thiệu Sản phẩm mới',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: AdminColors.ink,
                              ),
                            ),
                            Text(
                              'Tự động đính kèm ảnh đôi giày, giá bán và bắn thông báo tới điện thoại khách hàng.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AdminColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const Divider(height: 22, color: AdminColors.border),
                  DropdownButtonFormField<String>(
                    value: selectedProduct.id,
                    isExpanded: true,
                    decoration: adminInputDecoration(
                      label: 'Chọn mẫu giày cần giới thiệu tới khách',
                    ),
                    items: activeProducts
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p.id,
                            child: Text(
                              '${p.title} (${c.localizeCategory(p.categoryName)}) — ${c.formatMoney(p.salePrice > 0 && p.salePrice < p.price ? p.salePrice : p.price)}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      final found =
                          activeProducts.firstWhere((p) => p.id == id);
                      setModalState(() => selectedProduct = found);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Đối tượng khách nhận tin nhắn:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_selectedUserId != null)
                        ChoiceChip(
                          label: const Text('Chỉ khách đang chat'),
                          selected: audience == 'current',
                          onSelected: (_) =>
                              setModalState(() => audience = 'current'),
                        ),
                      ChoiceChip(
                        label: const Text('Khách quan tâm cùng danh mục'),
                        selected: audience == 'category',
                        onSelected: (_) =>
                            setModalState(() => audience = 'category'),
                      ),
                      ChoiceChip(
                        label: Text(
                          'Tất cả khách hàng (${c.clientUsers.length})',
                        ),
                        selected: audience == 'all',
                        onSelected: (_) =>
                            setModalState(() => audience = 'all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 4,
                    decoration: adminInputDecoration(
                      label:
                          'Nội dung tin nhắn (hỗ trợ {name}, {product}, {category}, {price})',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 8),
                      AdminPrimaryButton(
                        label: 'Gửi tin nhắn giới thiệu ngay',
                        icon: Iconsax.send_1,
                        loading: sending,
                        onPressed: () async {
                          setModalState(() => sending = true);
                          await c.broadcastNewProductChat(
                            product: selectedProduct,
                            customTemplate: msgCtrl.text.trim(),
                            singleUserId: audience == 'current'
                                ? _selectedUserId
                                : null,
                            onlyMatchingCategory: audience == 'category',
                          );
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    msgCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasFirebase = Firebase.apps.isNotEmpty;
      final preId = widget.controller.preselectedChatUserId.value;
      if (preId != null && preId.isNotEmpty) {
        _selectedUserId = preId;
        _selectedCustomerName =
            widget.controller.preselectedChatCustomerName.value;
        _selectedCustomerEmail =
            widget.controller.preselectedChatCustomerEmail.value;
        final draft = widget.controller.preselectedChatDraft.value;
        if (draft.isNotEmpty && _msgCtrl.text.trim().isEmpty) {
          _msgCtrl.text = draft;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.controller.preselectedChatUserId.value == preId) {
            widget.controller.preselectedChatUserId.value = null;
          }
        });
      }

      final baseThreads = widget.controller.supportChats.toList();
      final autoCfg = widget.controller.automation.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionToolbar(
              title: 'Tin nhắn Khách hàng (Chat 1-1)',
              subtitle:
                  'Trao đổi trực tiếp với khách hàng về đơn hàng, đổi trả trong 7 ngày & tự động nhắn tin khi đơn đổi trạng thái hoặc lên kệ mẫu mới.',
              actions: [
                OutlinedButton.icon(
                  onPressed: _openAutoChatSettingsDialog,
                  icon: Icon(
                    Iconsax.flash_1,
                    size: 16,
                    color: autoCfg.autoChatOnOrderStatus
                        ? AdminColors.emerald
                        : AdminColors.inkSecondary,
                  ),
                  label: Text(
                    autoCfg.autoChatOnOrderStatus
                        ? 'Auto Chat: Đang BẬT'
                        : 'Cài đặt Auto Chat',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: autoCfg.autoChatOnOrderStatus
                          ? AdminColors.forest
                          : AdminColors.ink,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AdminColors.borderStrong),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openNewProductChatDialog,
                  icon: const Icon(
                    Iconsax.box,
                    size: 16,
                    color: AdminColors.sky,
                  ),
                  label: const Text(
                    'Nhắn giới thiệu SP mới',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AdminColors.sky,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AdminColors.sky.withValues(alpha: 0.45),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
                AdminPrimaryButton(
                  label: '+ Nhắn tin khách hàng mới',
                  icon: Iconsax.message_add,
                  onPressed: _pickNewCustomerToChat,
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 680,
              child: hasFirebase
                  ? StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('SupportChats')
                          .snapshots(),
                      builder: (context, snap) {
                        final liveThreads = (snap.data?.docs ?? const [])
                            .map(SupportChatThreadModel.fromSnapshot)
                            .toList()
                          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                        return _buildChatSplitLayout(
                          liveThreads.isNotEmpty ? liveThreads : baseThreads,
                          hasFirebase: true,
                        );
                      },
                    )
                  : _buildChatSplitLayout(baseThreads, hasFirebase: false),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildChatSplitLayout(
    List<SupportChatThreadModel> threads, {
    required bool hasFirebase,
  }) {
    final q = _search.trim().toLowerCase();
    final clients = widget.controller.clientUsers;
    final filteredThreads = threads.where((t) {
      if (_listMode == 'unread' && t.unreadByAdmin <= 0) return false;
      if (q.isEmpty) return true;
      return t.customerName.toLowerCase().contains(q) ||
          t.customerEmail.toLowerCase().contains(q) ||
          t.activeProductTitle.toLowerCase().contains(q) ||
          t.lastMessage.toLowerCase().contains(q);
    }).toList();

    final filteredUsers = clients.where((u) {
      if (q.isEmpty) return true;
      return u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phoneNumber.toLowerCase().contains(q);
    }).toList();

    final activeUserId = _selectedUserId ??
        (filteredThreads.isNotEmpty
            ? filteredThreads.first.userId
            : (filteredUsers.isNotEmpty ? filteredUsers.first.id : null));

    SupportChatThreadModel? selectedThread;
    if (activeUserId != null) {
      for (final t in threads) {
        if (t.userId == activeUserId) {
          selectedThread = t;
          break;
        }
      }
    }

    // Latest return request for this customer (powers 1-click "Xác nhận địa chỉ đổi trả")
    ReturnRequestModel? latestCustomerReturn;
    if (activeUserId != null) {
      for (final r in widget.controller.returnRequests) {
        if (r.userId == activeUserId) {
          latestCustomerReturn = r;
          break;
        }
      }
    }

    // Resolve customer name/email cleanly for any selected user
    String activeName = selectedThread?.customerName ?? _selectedCustomerName;
    String activeEmail = selectedThread?.customerEmail ?? _selectedCustomerEmail;
    if (activeUserId != null && (activeName.isEmpty || activeEmail.isEmpty)) {
      for (final u in widget.controller.users) {
        if (u.id == activeUserId) {
          if (activeName.isEmpty) {
            activeName = u.fullName.isNotEmpty ? u.fullName : u.email;
          }
          if (activeEmail.isEmpty) activeEmail = u.email;
          break;
        }
      }
    }
    if (activeName.isEmpty) activeName = 'Khách hàng VELORA';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT COLUMN: Conversations List
        SizedBox(
          width: 340,
          child: AdminCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm tên khách, email, sản phẩm...',
                    prefixIcon: const Icon(Iconsax.search_normal, size: 17),
                    filled: true,
                    fillColor: AdminColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _listMode = 'chats'),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _listMode == 'chats'
                                ? AdminColors.forest
                                : AdminColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            'Đang chat (${threads.length})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _listMode == 'chats'
                                  ? Colors.white
                                  : AdminColors.inkSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _listMode = 'unread'),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _listMode == 'unread'
                                ? AdminColors.rose
                                : AdminColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            'Chưa đọc (${threads.where((t) => t.unreadByAdmin > 0).length})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _listMode == 'unread'
                                  ? Colors.white
                                  : AdminColors.inkSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _listMode = 'all_users'),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _listMode == 'all_users'
                                ? AdminColors.sky
                                : AdminColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            'Tất cả KH (${clients.length})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _listMode == 'all_users'
                                  ? Colors.white
                                  : AdminColors.inkSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AdminColors.border),
                const SizedBox(height: 8),
                Expanded(
                  child: _listMode == 'all_users'
                      ? (filteredUsers.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy khách hàng phù hợp.',
                                style: TextStyle(color: AdminColors.inkMuted),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredUsers.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (_, i) {
                                final u = filteredUsers[i];
                                final selected = u.id == activeUserId;
                                final uName = u.fullName.isNotEmpty
                                    ? u.fullName
                                    : u.email;
                                return InkWell(
                                  onTap: () => _selectCustomer(
                                    u.id,
                                    name: uName,
                                    email: u.email,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AdminColors.sageSoft
                                          : AdminColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? AdminColors.forest
                                            : AdminColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: selected
                                              ? AdminColors.forest
                                              : AdminColors.surfaceMuted,
                                          child: Text(
                                            uName.isNotEmpty
                                                ? uName[0].toUpperCase()
                                                : 'K',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: selected
                                                  ? Colors.white
                                                  : AdminColors.forest,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                uName,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: AdminColors.ink,
                                                ),
                                              ),
                                              Text(
                                                u.email,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AdminColors.inkMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ))
                      : (filteredThreads.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Chưa có cuộc hội thoại nào. Bạn có thể bấm tab "Tất cả KH" hoặc "+ Nhắn tin khách hàng mới" để bắt đầu nhắn tin riêng.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AdminColors.inkMuted,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredThreads.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (_, i) {
                                final t = filteredThreads[i];
                                final selected = t.userId == activeUserId;
                                return InkWell(
                                  onTap: () => _selectCustomer(
                                    t.userId,
                                    name: t.customerName,
                                    email: t.customerEmail,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AdminColors.sageSoft
                                          : AdminColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? AdminColors.forest
                                            : AdminColors.border,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: selected
                                                  ? AdminColors.forest
                                                  : AdminColors.surfaceMuted,
                                              child: Text(
                                                t.customerName.isNotEmpty
                                                    ? t.customerName[0]
                                                        .toUpperCase()
                                                    : 'K',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: selected
                                                      ? Colors.white
                                                      : AdminColors.forest,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 9),
                                            Expanded(
                                              child: Text(
                                                t.customerName,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: AdminColors.ink,
                                                ),
                                              ),
                                            ),
                                            if (t.unreadByAdmin > 0)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AdminColors.rose,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                                child: Text(
                                                  '${t.unreadByAdmin}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (t.activeProductTitle
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AdminColors.skyBg,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              t.activeReturnId.isNotEmpty
                                                  ? 'Đổi trả: ${t.activeProductTitle}'
                                                  : 'Đơn hàng: ${t.activeProductTitle}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AdminColors.sky,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 5),
                                        Text(
                                          t.lastMessage,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AdminColors.inkSecondary,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd/MM/yyyy HH:mm')
                                              .format(t.updatedAt),
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: AdminColors.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // RIGHT COLUMN: Live 1-1 Chat Panel
        Expanded(
          child: AdminCard(
            padding: EdgeInsets.zero,
            child: activeUserId == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.message_text_1,
                            size: 46,
                            color: AdminColors.inkMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Chọn một khách hàng ở cột bên trái để bắt đầu nhắn tin riêng 1-1',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.ink,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Tin nhắn bạn gửi sẽ xuất hiện ngay trong mục "Chat trực tiếp với VELORA" và bắn thông báo tới điện thoại khách hàng.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AdminColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Chat Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AdminColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AdminColors.forest,
                              child: Text(
                                activeName.isNotEmpty
                                    ? activeName[0].toUpperCase()
                                    : 'K',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeName,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: AdminColors.ink,
                                    ),
                                  ),
                                  if (activeEmail.isNotEmpty)
                                    Text(
                                      activeEmail,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AdminColors.inkSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if ((selectedThread?.activeProductTitle ??
                                    widget.controller
                                        .preselectedChatProductTitle.value)
                                .isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AdminColors.skyBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  selectedThread?.activeProductTitle.isNotEmpty ==
                                          true
                                      ? selectedThread!.activeProductTitle
                                      : widget.controller
                                          .preselectedChatProductTitle.value,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.sky,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Messages Stream
                      Expanded(
                        child: hasFirebase
                            ? StreamBuilder<
                                QuerySnapshot<Map<String, dynamic>>>(
                                stream: FirebaseFirestore.instance
                                    .collection('SupportChats')
                                    .doc(activeUserId)
                                    .collection('Messages')
                                    .orderBy('createdAt', descending: false)
                                    .snapshots(),
                                builder: (context, msgSnap) {
                                  final msgs = (msgSnap.data?.docs ?? const [])
                                      .map(SupportChatMessageModel.fromSnapshot)
                                      .toList();
                                  if (msgs.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        'Chưa có tin nhắn nào với khách hàng này. Hãy gửi lời nhắn đầu tiên bên dưới!',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AdminColors.inkMuted,
                                        ),
                                      ),
                                    );
                                  }
                                  return ListView.builder(
                                    controller: _scrollCtrl,
                                    padding: const EdgeInsets.all(20),
                                    itemCount: msgs.length,
                                    itemBuilder: (_, idx) =>
                                        _buildAdminChatBubble(msgs[idx]),
                                  );
                                },
                              )
                            : const Center(
                                child: Text(
                                  'Khung tin nhắn 1-1 thời gian thực sẵn sàng.',
                                  style: TextStyle(color: AdminColors.inkMuted),
                                ),
                              ),
                      ),

                      // Quick Reply Templates for Admin
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        decoration: const BoxDecoration(
                          color: AdminColors.surfaceMuted,
                          border: Border(
                            top: BorderSide(color: AdminColors.border),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mẫu tin nhắn nhanh cho Admin (bấm để chèn & chỉnh sửa trước khi gửi):',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AdminColors.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                ActionChip(
                                  onPressed: () {
                                    final ret = latestCustomerReturn;
                                    final confirmText = ret != null
                                        ? 'Chào $activeName, VELORA xác nhận địa chỉ đổi trả cho mẫu ${ret.productTitle} (${ret.typeLabel()}${ret.requestedSizeOrColor.isNotEmpty && ret.requestedSizeOrColor != ret.typeLabel() ? ' • ${ret.requestedSizeOrColor}' : ''}) là: ${ret.pickupAddress}. Bạn kiểm tra lại xem địa chỉ đổi mới này đã chính xác chưa để Tổng Kho Hà Nội xử lý gửi hàng ngay cho bạn nhé!'
                                        : 'Chào $activeName, VELORA xác nhận thông tin đổi trả của bạn. Bạn vui lòng xác nhận lại Địa chỉ đổi mới chính xác để Tổng Kho Hà Nội gửi đôi mới ngay cho bạn nhé!';
                                    setState(() {
                                      _msgCtrl.text = confirmText;
                                    });
                                  },
                                  backgroundColor: AdminColors.skyBg,
                                  side: BorderSide(
                                    color:
                                        AdminColors.sky.withValues(alpha: 0.45),
                                  ),
                                  label: Text(
                                    latestCustomerReturn != null
                                        ? '📍 Xác nhận địa chỉ đổi trả (${latestCustomerReturn.pickupAddress})'
                                        : '📍 Xác nhận địa chỉ đổi trả',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: AdminColors.sky,
                                    ),
                                  ),
                                ),
                                for (var i = 0;
                                    i < _adminQuickTemplates.length;
                                    i++)
                                  ActionChip(
                                    onPressed: () {
                                      setState(() {
                                        _msgCtrl.text =
                                            _adminQuickTemplates[i];
                                      });
                                    },
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: AdminColors.borderStrong,
                                    ),
                                    label: Text(
                                      i == 0
                                          ? '✅ Duyệt đổi mới về địa chỉ mới'
                                          : i == 1
                                              ? '🚚 Đôi mới đã xuất Kho Hà Nội'
                                              : i == 2
                                                  ? '💰 Hoàn tất đổi trả / hoàn tiền'
                                                  : '📏 Hỏi xác nhận lại Size EU',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AdminColors.forest,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (_uploadingMedia) ...[
                        const LinearProgressIndicator(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _uploadingStatus,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.forest,
                            ),
                          ),
                        ),
                      ],

                      // Message Composer (Text + Image + Video)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: AdminColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _uploadingMedia
                                  ? null
                                  : () => _pickAndSendAdminImage(
                                        userId: activeUserId,
                                        customerName: activeName,
                                        customerEmail: activeEmail,
                                      ),
                              icon: const Icon(
                                Iconsax.gallery,
                                size: 16,
                                color: AdminColors.forest,
                              ),
                              label: const Text(
                                'Ảnh',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AdminColors.forest,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 12,
                                ),
                                side: const BorderSide(
                                  color: AdminColors.borderStrong,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton.icon(
                              onPressed: _uploadingMedia
                                  ? null
                                  : () => _pickAndSendAdminVideo(
                                        userId: activeUserId,
                                        customerName: activeName,
                                        customerEmail: activeEmail,
                                      ),
                              icon: const Icon(
                                Iconsax.video_play,
                                size: 16,
                                color: AdminColors.sky,
                              ),
                              label: const Text(
                                'Video',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AdminColors.sky,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 12,
                                ),
                                side: BorderSide(
                                  color: AdminColors.sky.withValues(alpha: 0.45),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _msgCtrl,
                                minLines: 1,
                                maxLines: 3,
                                onSubmitted: (_) => _sendMessage(
                                  userId: activeUserId,
                                  customerName: activeName,
                                  customerEmail: activeEmail,
                                ),
                                decoration: adminInputDecoration(
                                  label:
                                      'Nhập tin nhắn riêng gửi tới $activeName...',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            AdminPrimaryButton(
                              label: 'Gửi tin nhắn',
                              icon: Iconsax.send_1,
                              loading: _sending,
                              onPressed: () => _sendMessage(
                                userId: activeUserId,
                                customerName: activeName,
                                customerEmail: activeEmail,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminChatBubble(SupportChatMessageModel msg) {
    final isAdmin = msg.isAdmin;
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isAdmin ? AdminColors.forest : AdminColors.surfaceMuted,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isAdmin ? 14 : 4),
            bottomRight: Radius.circular(isAdmin ? 4 : 14),
          ),
          border: isAdmin
              ? null
              : Border.all(color: AdminColors.borderStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAdmin ? 'VELORA CSKH (Bạn)' : msg.senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isAdmin
                        ? const Color(0xFFDDEABB)
                        : AdminColors.forest,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM HH:mm').format(msg.createdAt),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isAdmin ? Colors.white60 : AdminColors.inkMuted,
                  ),
                ),
              ],
            ),
            if (msg.hasContext) ...[
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (msg.productThumbnail.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: msg.productThumbnail,
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.productTitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isAdmin ? Colors.white : AdminColors.ink,
                            ),
                          ),
                          if (msg.contextSummary.isNotEmpty)
                            Text(
                              msg.contextSummary,
                              style: TextStyle(
                                fontSize: 11,
                                color: isAdmin
                                    ? Colors.white70
                                    : AdminColors.inkSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (msg.hasImage) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _openAdminImageZoom(msg.imageUrl),
                borderRadius: BorderRadius.circular(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: msg.imageUrl,
                    width: 240,
                    height: 170,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            if (msg.hasVideo) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _openAdminVideoPlayer(msg.videoUrl),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 240,
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
                        size: 44,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Bấm để phát Video đính kèm',
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
            ],
            const SizedBox(height: 6),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: isAdmin ? Colors.white : AdminColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminChatVideoDialog extends StatefulWidget {
  const _AdminChatVideoDialog({required this.videoUrl});
  final String videoUrl;

  @override
  State<_AdminChatVideoDialog> createState() => _AdminChatVideoDialogState();
}

class _AdminChatVideoDialogState extends State<_AdminChatVideoDialog> {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 580),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: const TextStyle(color: Colors.white)),
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
                      : 16 / 9,
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
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
