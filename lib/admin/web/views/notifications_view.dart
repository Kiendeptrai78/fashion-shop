import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class AdminNotificationsView extends StatefulWidget {
  const AdminNotificationsView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminNotificationsView> createState() => _AdminNotificationsViewState();
}

class _AdminNotificationsViewState extends State<AdminNotificationsView> {
  final _formKey = GlobalKey<FormState>();
  final _titleViCtrl = TextEditingController();
  final _bodyViCtrl = TextEditingController();
  final _titleEnCtrl = TextEditingController();
  final _bodyEnCtrl = TextEditingController();

  String _audienceMode = 'all'; // 'all' | 'user'
  String? _selectedUserId;
  String _kind = 'promo'; // 'promo' | 'product' | 'order'
  String _selectedProductId = '';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final preselected = widget.controller.preselectedNotificationUserId.value;
    if (preselected != null && preselected.isNotEmpty) {
      _audienceMode = 'user';
      _selectedUserId = preselected;
      widget.controller.preselectedNotificationUserId.value = null;
    }
  }

  @override
  void dispose() {
    _titleViCtrl.dispose();
    _bodyViCtrl.dispose();
    _titleEnCtrl.dispose();
    _bodyEnCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audienceMode == 'user' && (_selectedUserId == null || _selectedUserId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khách hàng nhận thông báo.')),
      );
      return;
    }
    setState(() => _sending = true);
    final ok = await widget.controller.sendNotification(
      titleVi: _titleViCtrl.text.trim(),
      bodyVi: _bodyViCtrl.text.trim(),
      titleEn: _titleEnCtrl.text.trim(),
      bodyEn: _bodyEnCtrl.text.trim(),
      kind: _kind,
      targetId: _kind == 'product' ? _selectedProductId : '',
      specificUserId: _audienceMode == 'user' ? _selectedUserId : null,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _titleViCtrl.clear();
      _bodyViCtrl.clear();
      _titleEnCtrl.clear();
      _bodyEnCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1060;

    return Obx(() {
      final clients = widget.controller.clientUsers;
      final products = widget.controller.products;
      final campaigns = widget.controller.campaigns;

      final composerCard = AdminCard(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Iconsax.send_2, size: 20, color: AdminColors.forest),
                  SizedBox(width: 10),
                  Text(
                    'Soạn & Gửi thông báo mới',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Thông báo được gửi thẳng vào hộp thư Thông báo (Notifications) của từng khách hàng trên ứng dụng.',
                style: TextStyle(fontSize: 12.5, color: AdminColors.inkSecondary),
              ),
              const SizedBox(height: 20),

              // Audience
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _audienceMode,
                      isExpanded: true,
                      decoration: adminInputDecoration(label: 'Đối tượng nhận'),
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('Tất cả khách hàng (${clients.length})'),
                        ),
                        const DropdownMenuItem(
                          value: 'user',
                          child: Text('Một khách hàng cụ thể'),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        _audienceMode = v ?? 'all';
                        if (_audienceMode == 'user' &&
                            _selectedUserId == null &&
                            clients.isNotEmpty) {
                          _selectedUserId = clients.first.id;
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _kind,
                      isExpanded: true,
                      decoration: adminInputDecoration(label: 'Loại thông báo'),
                      items: const [
                        DropdownMenuItem(value: 'promo', child: Text('Khuyến mãi / Tin tức')),
                        DropdownMenuItem(
                            value: 'product', child: Text('Sản phẩm mới (Mở trang SP)')),
                        DropdownMenuItem(value: 'order', child: Text('Cập nhật đơn hàng')),
                      ],
                      onChanged: (v) => setState(() => _kind = v ?? 'promo'),
                    ),
                  ),
                ],
              ),

              if (_audienceMode == 'user') ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: clients.any((c) => c.id == _selectedUserId)
                      ? _selectedUserId
                      : null,
                  isExpanded: true,
                  decoration: adminInputDecoration(label: 'Chọn khách hàng'),
                  items: clients
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.fullName.trim().isNotEmpty ? c.fullName : c.username} (${c.email})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedUserId = v),
                ),
              ],

              if (_kind == 'product') ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: products.any((p) => p.id == _selectedProductId)
                      ? _selectedProductId
                      : '',
                  isExpanded: true,
                  decoration: adminInputDecoration(
                    label: 'Liên kết tới sản phẩm (khi khách nhấn vào thông báo)',
                  ),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('— Chọn sản phẩm —')),
                    ...products.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.title, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedProductId = v ?? ''),
                ),
              ],

              const SizedBox(height: 14),
              TextFormField(
                controller: _titleViCtrl,
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tiêu đề tiếng Việt' : null,
                decoration: adminInputDecoration(
                  label: 'Tiêu đề (Tiếng Việt) *',
                  hint: 'Ví dụ: Flash Sale cuối tuần — Giảm 20% toàn bộ Nike',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyViCtrl,
                onChanged: (_) => setState(() {}),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Vui lòng nhập nội dung thông báo' : null,
                decoration: adminInputDecoration(
                  label: 'Nội dung (Tiếng Việt) *',
                  hint: 'Nhập nội dung chi tiết muốn gửi tới khách hàng...',
                ),
              ),
              const SizedBox(height: 14),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  'Bản dịch Tiếng Anh (tùy chọn — tự động dùng bản Tiếng Việt nếu bỏ trống)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.inkSecondary,
                  ),
                ),
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleEnCtrl,
                    decoration: adminInputDecoration(
                      label: 'Title (English)',
                      hint: 'Weekend Flash Sale — 20% off all Nike',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _bodyEnCtrl,
                    maxLines: 2,
                    decoration: adminInputDecoration(
                      label: 'Body (English)',
                      hint: 'Shop your favorite pairs before Sunday midnight.',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              const SizedBox(height: 16),

              // Live preview box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AdminColors.forestDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AdminColors.sage.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _kind == 'product'
                            ? Iconsax.shopping_bag
                            : _kind == 'order'
                                ? Iconsax.truck_fast
                                : Iconsax.notification_bing,
                        color: AdminColors.sage,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'XEM TRƯỚC TRÊN APP KHÁCH HÀNG',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.1,
                              color: AdminColors.sage,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _titleViCtrl.text.trim().isNotEmpty
                                ? _titleViCtrl.text.trim()
                                : 'Tiêu đề thông báo sẽ hiện ở đây',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _bodyViCtrl.text.trim().isNotEmpty
                                ? _bodyViCtrl.text.trim()
                                : 'Nội dung chi tiết thông báo...',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: AdminPrimaryButton(
                  label: _audienceMode == 'all'
                      ? 'Gửi tới tất cả khách hàng (${clients.length})'
                      : 'Gửi thông báo ngay',
                  icon: Iconsax.send_2,
                  loading: _sending,
                  onPressed: _send,
                ),
              ),
            ],
          ),
        ),
      );

      final historyCard = Column(
        children: [
          AdminCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AdminColors.sageSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.mobile, color: AdminColors.forest, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.controller.pushDeviceCount.value} thiết bị đăng ký FCM Push',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${clients.length} tài khoản khách hàng nhận thông báo trong hộp thư In-App ngay lập tức.',
                        style: const TextStyle(fontSize: 12, color: AdminColors.inkSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AdminCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lịch sử đã gửi (${campaigns.length})',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                if (campaigns.isEmpty)
                  const AdminEmptyState(
                    icon: Iconsax.notification_bing,
                    title: 'Chưa có chiến dịch nào',
                    subtitle: 'Các thông báo bạn gửi từ trang quản trị sẽ được lưu lịch sử tại đây.',
                  )
                else
                  Column(
                    children: campaigns.map((c) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        c.titleVi,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AdminColors.ink,
                                        ),
                                      ),
                                      AdminBadge(
                                        label: '${c.recipientCount} người nhận',
                                        color: AdminColors.forest,
                                        bgColor: AdminColors.sageSoft,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.bodyVi,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AdminColors.inkSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${c.audienceLabel}'
                                    '${c.createdAt != null ? ' • ${DateFormat('dd/MM/yyyy HH:mm').format(c.createdAt!)}' : ''}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AdminColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Xóa lịch sử',
                              onPressed: () => widget.controller.deleteCampaignLog(c),
                              icon: const Icon(Iconsax.trash,
                                  size: 16, color: AdminColors.inkMuted),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      );

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminSectionToolbar(
                  title: 'Quản lý Thông báo',
                  subtitle:
                      'Gửi thông báo khuyến mãi, giới thiệu sản phẩm mới hoặc nhắc đơn hàng trực tiếp đến khách hàng.',
                ),
                const SizedBox(height: 20),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 11, child: composerCard),
                      const SizedBox(width: 20),
                      Expanded(flex: 10, child: historyCard),
                    ],
                  )
                else ...[
                  composerCard,
                  const SizedBox(height: 18),
                  historyCard,
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
