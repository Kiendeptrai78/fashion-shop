import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/admin/web/views/users_view.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class AdminVouchersView extends StatefulWidget {
  const AdminVouchersView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminVouchersView> createState() => _AdminVouchersViewState();
}

class _AdminVouchersViewState extends State<AdminVouchersView> {
  String _query = '';
  String _audienceFilter = 'all'; // 'all' | 'newMember' | 'loyal' | 'vip' | 'specific'
  bool _autoBusy = false;

  @override
  void initState() {
    super.initState();
    final preselectedUser = widget.controller.preselectedVoucherUserId.value;
    if (preselectedUser != null && preselectedUser.isNotEmpty) {
      widget.controller.preselectedVoucherUserId.value = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openEditor(preselectedUserId: preselectedUser);
      });
    }
  }

  Future<void> _openEditor({AdminVoucherRecord? existing, String? preselectedUserId}) async {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final percentCtrl = TextEditingController(text: (existing?.percent ?? 15).toString());
    final maxUsdCtrl = TextEditingController(text: (existing?.maxUsd ?? 20).toString());
    final minUsdCtrl = TextEditingController(text: (existing?.minUsd ?? 50).toString());
    bool shipping = existing?.shipping ?? false;
    bool active = existing?.active ?? true;
    bool sendNotification = existing == null;
    bool excludeBomHang = existing?.excludeBomHang ?? true;
    String targetAudience = preselectedUserId != null
        ? 'specific'
        : (existing?.targetAudience ?? 'all');
    final selectedUserIds = <String>{
      ...?existing?.targetUserIds,
      if (preselectedUserId != null) preselectedUserId,
    };
    String userSearch = '';
    DateTime expires = existing?.expires ?? DateTime.now().add(const Duration(days: 14));
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final maxUsd = double.tryParse(maxUsdCtrl.text.trim()) ?? 0;
          final minUsd = double.tryParse(minUsdCtrl.text.trim()) ?? 0;
          final clientStats = widget.controller.clientUsers
              .map(widget.controller.customerStatsFor)
              .toList();
          final bomCount =
              clientStats.where((s) => s.segment == CustomerSegment.bomHang).length;
          final matchedUsers = widget.controller.usersMatchingVoucherAudience(
            targetAudience: targetAudience,
            targetUserIds: selectedUserIds.toList(),
            excludeBomHang: excludeBomHang,
          );
          final filteredClients = clientStats.where((st) {
            final q = userSearch.trim().toLowerCase();
            if (q.isEmpty) return true;
            return st.user.fullName.toLowerCase().contains(q) ||
                st.user.email.toLowerCase().contains(q);
          }).toList();

          return Dialog(
            backgroundColor: AdminColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640, maxHeight: 780),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AdminColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            existing == null
                                ? 'Tạo Voucher giảm giá mới'
                                : 'Chỉnh sửa Voucher ${existing.code}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: saving ? null : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: codeCtrl,
                              readOnly: existing != null,
                              textCapitalization: TextCapitalization.characters,
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'Vui lòng nhập mã voucher';
                                if (s.contains(' ')) return 'Mã voucher không được có khoảng trắng';
                                return null;
                              },
                              decoration: adminInputDecoration(
                                label: 'Mã Voucher (CODE) *',
                                hint: 'Ví dụ: VELORA20, VIP30, TET2026',
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: titleCtrl,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Vui lòng nhập mô tả ưu đãi'
                                  : null,
                              decoration: adminInputDecoration(
                                label: 'Tên / Mô tả chương trình *',
                                hint: 'Ví dụ: Tri ân khách VIP cuối tuần',
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Audience targeting section
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AdminColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AdminColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Iconsax.people, size: 17, color: AdminColors.forest),
                                      SizedBox(width: 8),
                                      Text(
                                        'Đối tượng áp dụng & Nhận thông báo',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AdminColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: targetAudience,
                                    isExpanded: true,
                                    decoration: adminInputDecoration(label: 'Chọn phân khúc khách hàng'),
                                    items: const [
                                      DropdownMenuItem(value: 'all', child: Text('Tất cả khách hàng')),
                                      DropdownMenuItem(
                                          value: 'newMember',
                                          child: Text('Chỉ Thành viên mới (chưa mua đơn nào)')),
                                      DropdownMenuItem(
                                          value: 'loyal',
                                          child: Text('Khách lâu năm & VIP (đã mua ≥ 1 đơn)')),
                                      DropdownMenuItem(
                                          value: 'vip',
                                          child: Text('Chỉ Khách VIP thân thiết')),
                                      DropdownMenuItem(
                                          value: 'specific',
                                          child: Text('Chọn đích danh từng thành viên...')),
                                    ],
                                    onChanged: (v) =>
                                        setModalState(() => targetAudience = v ?? 'all'),
                                  ),
                                  if (targetAudience != 'specific') ...[
                                    const SizedBox(height: 6),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      activeColor: AdminColors.forest,
                                      title: Text(
                                        'Tự động loại trừ tài khoản bom hàng ($bomCount tài khoản)',
                                        style: const TextStyle(
                                            fontSize: 12.5, fontWeight: FontWeight.w600),
                                      ),
                                      value: excludeBomHang,
                                      onChanged: (v) =>
                                          setModalState(() => excludeBomHang = v),
                                    ),
                                  ],
                                  if (targetAudience == 'specific') ...[
                                    const SizedBox(height: 10),
                                    TextField(
                                      onChanged: (v) => setModalState(() => userSearch = v),
                                      decoration: adminInputDecoration(
                                        label: 'Tìm thành viên để tích chọn',
                                        hint: 'Nhập tên hoặc email...',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      constraints: const BoxConstraints(maxHeight: 200),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AdminColors.border),
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: filteredClients.length,
                                        itemBuilder: (_, idx) {
                                          final st = filteredClients[idx];
                                          final badge = segmentBadgeMeta(st.segment);
                                          final checked = selectedUserIds.contains(st.user.id);
                                          return CheckboxListTile(
                                            dense: true,
                                            activeColor: AdminColors.forest,
                                            value: checked,
                                            onChanged: (val) => setModalState(() {
                                              if (val == true) {
                                                selectedUserIds.add(st.user.id);
                                              } else {
                                                selectedUserIds.remove(st.user.id);
                                              }
                                            }),
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    st.user.fullName.trim().isNotEmpty
                                                        ? st.user.fullName
                                                        : st.user.email,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                AdminBadge(
                                                  label: badge.label,
                                                  color: badge.color,
                                                  bgColor: badge.bg,
                                                ),
                                              ],
                                            ),
                                            subtitle: Text(
                                              '${st.user.email} • ${st.receivedOrders} nhận / ${st.cancelledOrders} hủy',
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    '→ Sẽ áp dụng & gửi thông báo cho đúng ${matchedUsers.length} khách hàng phù hợp.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AdminColors.forest,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeColor: AdminColors.forest,
                              title: const Text(
                                'Voucher Miễn phí vận chuyển (Free Shipping)',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                              ),
                              value: shipping,
                              onChanged: (v) => setModalState(() => shipping = v),
                            ),
                            if (!shipping) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: percentCtrl,
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        final n = int.tryParse((v ?? '').trim());
                                        if (n == null || n <= 0 || n > 100) return 'Từ 1 đến 100%';
                                        return null;
                                      },
                                      decoration: adminInputDecoration(label: 'Giảm (%) *', hint: '15'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: maxUsdCtrl,
                                      onChanged: (_) => setModalState(() {}),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (v) {
                                        final n = double.tryParse((v ?? '').trim());
                                        if (n == null || n <= 0) return 'Nhập số dương';
                                        return null;
                                      },
                                      decoration: adminInputDecoration(
                                        label: 'Giảm tối đa (USD) *',
                                        hint: '20',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Tối đa quy đổi: ${formatShopMoney(maxUsd, language: 'vi')}',
                                  style: const TextStyle(
                                      fontSize: 11.5, color: AdminColors.forestLight),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: minUsdCtrl,
                                    onChanged: (_) => setModalState(() {}),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: adminInputDecoration(
                                      label: 'Đơn tối thiểu (USD)',
                                      hint: '0 nếu không yêu cầu',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: expires,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setModalState(() {
                                          expires = DateTime(
                                              picked.year, picked.month, picked.day, 23, 59);
                                        });
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                      side: const BorderSide(color: AdminColors.borderStrong),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(11)),
                                    ),
                                    icon: const Icon(Iconsax.calendar, size: 17),
                                    label: Text(
                                      'Hết hạn: ${DateFormat('dd/MM/yyyy').format(expires)}',
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Đơn tối thiểu quy đổi: ${formatShopMoney(minUsd, language: 'vi')}',
                                style: const TextStyle(
                                    fontSize: 11.5, color: AdminColors.inkSecondary),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeColor: AdminColors.forest,
                              title: const Text(
                                'Kích hoạt Voucher ngay',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                              ),
                              value: active,
                              onChanged: (v) => setModalState(() => active = v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeColor: AdminColors.forest,
                              title: Text(
                                'Tự động gửi thông báo tới nhóm đã chọn (${matchedUsers.length} khách)',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                              ),
                              subtitle: const Text(
                                'Khách nhấn vào thông báo sẽ mở thẳng Ví Voucher để áp dụng.',
                                style: TextStyle(fontSize: 11.5, color: AdminColors.inkMuted),
                              ),
                              value: sendNotification,
                              onChanged: (v) => setModalState(() => sendNotification = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AdminColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: saving ? null : () => Navigator.of(context).pop(),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 10),
                        AdminPrimaryButton(
                          label: existing == null ? 'Tạo Voucher' : 'Lưu thay đổi',
                          icon: Iconsax.tick_circle,
                          loading: saving,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            if (targetAudience == 'specific' && selectedUserIds.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng chọn ít nhất 1 khách hàng nhận Voucher.'),
                                ),
                              );
                              return;
                            }
                            setModalState(() => saving = true);
                            final ok = await widget.controller.saveVoucher(
                              AdminVoucherRecord(
                                code: codeCtrl.text.trim().toUpperCase(),
                                title: titleCtrl.text.trim(),
                                percent: int.tryParse(percentCtrl.text.trim()) ?? 0,
                                maxUsd: double.tryParse(maxUsdCtrl.text.trim()) ?? 0,
                                minUsd: double.tryParse(minUsdCtrl.text.trim()) ?? 0,
                                shipping: shipping,
                                active: active,
                                targetAudience: targetAudience,
                                targetUserIds: selectedUserIds.toList(),
                                excludeBomHang: excludeBomHang,
                                autoTag: existing?.autoTag ?? '',
                                expires: expires,
                              ),
                              isNew: existing == null,
                              sendNotification: sendNotification,
                            );
                            if (!context.mounted) return;
                            setModalState(() => saving = false);
                            if (ok) Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    codeCtrl.dispose();
    titleCtrl.dispose();
    percentCtrl.dispose();
    maxUsdCtrl.dispose();
    minUsdCtrl.dispose();
  }

  Widget _autoRuleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required int percent,
    required int targetCount,
    required ValueChanged<bool> onToggle,
    required VoidCallback onIssueNow,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: enabled ? AdminColors.sageSoft.withValues(alpha: 0.45) : AdminColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? AdminColors.forest.withValues(alpha: 0.25) : AdminColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: AdminColors.forest),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
              Switch(
                value: enabled,
                activeColor: AdminColors.forest,
                onChanged: onToggle,
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11.5, color: AdminColors.inkSecondary, height: 1.4),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminBadge(
                label: 'Giảm $percent% • $targetCount khách',
                color: AdminColors.forest,
                bgColor: Colors.white,
              ),
              TextButton.icon(
                onPressed: _autoBusy ? null : onIssueNow,
                icon: const Icon(Iconsax.send_2, size: 15),
                label: const Text('Phát & Báo ngay', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Obx(() {
      final all = widget.controller.vouchers;
      final cfg = widget.controller.automation.value;
      final q = _query.trim().toLowerCase();
      final filtered = all.where((v) {
        if (_audienceFilter != 'all' && v.targetAudience != _audienceFilter) return false;
        if (q.isEmpty) return true;
        return v.code.toLowerCase().contains(q) || v.title.toLowerCase().contains(q);
      }).toList();

      final newCount = widget.controller
          .usersMatchingVoucherAudience(targetAudience: 'newMember', excludeBomHang: true)
          .length;
      final allCleanCount = widget.controller
          .usersMatchingVoucherAudience(targetAudience: 'all', excludeBomHang: true)
          .length;
      final vipCount = widget.controller
          .usersMatchingVoucherAudience(targetAudience: 'vip', excludeBomHang: true)
          .length;

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Quản lý Voucher & Ưu đãi tự động (${all.length})',
                  subtitle:
                      'Phát mã giảm giá theo đúng phân khúc khách hàng (Mới, Lâu năm, VIP, chọn riêng), tự động tránh tài khoản bom hàng và phát dịp Lễ.',
                  actions: [
                    AdminSearchField(
                      hint: 'Tìm mã voucher, tên chương trình...',
                      width: 240,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    AdminPrimaryButton(
                      label: 'Tạo Voucher mới',
                      icon: Iconsax.ticket_discount,
                      onPressed: () => _openEditor(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Auto Voucher Panel
                AdminCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 19, color: AdminColors.forest),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Chế độ Tự động phát Voucher (Ngày lễ · Thành viên mới · Khách VIP)',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AdminColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Bật/tắt tự động hoặc bấm "Phát & Báo ngay" để tự tạo mã, cấp vào Ví Voucher đúng nhóm khách (tự loại bom hàng) và đẩy thông báo tức thì.',
                        style: TextStyle(fontSize: 12, color: AdminColors.inkSecondary),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cols = constraints.maxWidth >= 960 ? 3 : 1;
                          final itemW = (constraints.maxWidth - (cols - 1) * 14) / cols;
                          return Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              SizedBox(
                                width: itemW,
                                child: _autoRuleCard(
                                  icon: Iconsax.user_add,
                                  title: 'Auto Thành viên mới',
                                  subtitle: 'Tự động tặng mã chào mừng cho khách mới đăng ký chưa có đơn.',
                                  enabled: cfg.autoWelcomeVoucher,
                                  percent: cfg.welcomePercent,
                                  targetCount: newCount,
                                  onToggle: (v) => widget.controller.saveAutomationSettings(
                                    cfg.copyWith(autoWelcomeVoucher: v),
                                  ),
                                  onIssueNow: () async {
                                    setState(() => _autoBusy = true);
                                    await widget.controller.issueAutoVoucherNow('new_member');
                                    if (mounted) setState(() => _autoBusy = false);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: itemW,
                                child: _autoRuleCard(
                                  icon: Iconsax.calendar_tick,
                                  title: 'Auto Voucher Ngày lễ',
                                  subtitle: 'Tự động phát dịp Lễ VN (Tết, 8/3, 30/4, 2/9, 20/11, Noel...) trừ bom hàng.',
                                  enabled: cfg.autoHolidayVoucher,
                                  percent: cfg.holidayPercent,
                                  targetCount: allCleanCount,
                                  onToggle: (v) => widget.controller.saveAutomationSettings(
                                    cfg.copyWith(autoHolidayVoucher: v),
                                  ),
                                  onIssueNow: () async {
                                    setState(() => _autoBusy = true);
                                    await widget.controller.issueAutoVoucherNow('holiday');
                                    if (mounted) setState(() => _autoBusy = false);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: itemW,
                                child: _autoRuleCard(
                                  icon: Iconsax.crown_1,
                                  title: 'Auto Tri ân Khách VIP',
                                  subtitle: 'Tặng đặc quyền giảm sâu cho khách VIP đã mua ≥ 3 đơn hoặc chi tiêu cao.',
                                  enabled: cfg.autoVipVoucher,
                                  percent: cfg.vipPercent,
                                  targetCount: vipCount,
                                  onToggle: (v) => widget.controller.saveAutomationSettings(
                                    cfg.copyWith(autoVipVoucher: v),
                                  ),
                                  onIssueNow: () async {
                                    setState(() => _autoBusy = true);
                                    await widget.controller.issueAutoVoucherNow('vip');
                                    if (mounted) setState(() => _autoBusy = false);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Filter chips by target member group
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('Tất cả (${all.length})'),
                      selected: _audienceFilter == 'all',
                      onSelected: (_) => setState(() => _audienceFilter = 'all'),
                    ),
                    ChoiceChip(
                      label: const Text('Thành viên mới'),
                      selected: _audienceFilter == 'newMember',
                      onSelected: (_) => setState(() => _audienceFilter = 'newMember'),
                    ),
                    ChoiceChip(
                      label: const Text('Khách lâu năm'),
                      selected: _audienceFilter == 'loyal',
                      onSelected: (_) => setState(() => _audienceFilter = 'loyal'),
                    ),
                    ChoiceChip(
                      label: const Text('Khách VIP'),
                      selected: _audienceFilter == 'vip',
                      onSelected: (_) => setState(() => _audienceFilter = 'vip'),
                    ),
                    ChoiceChip(
                      label: const Text('Tặng riêng từng khách'),
                      selected: _audienceFilter == 'specific',
                      onSelected: (_) => setState(() => _audienceFilter = 'specific'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                if (filtered.isEmpty)
                  AdminCard(
                    child: AdminEmptyState(
                      icon: Iconsax.ticket_discount,
                      title: 'Chưa có voucher nào ở mục này',
                      subtitle:
                          'Tạo mã giảm giá mới hoặc dùng nút "Phát & Báo ngay" ở khung tự động phía trên.',
                      action: AdminPrimaryButton(
                        label: 'Tạo Voucher mới',
                        icon: Iconsax.ticket_discount,
                        onPressed: () => _openEditor(),
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth >= 1100
                          ? 3
                          : constraints.maxWidth >= 700
                              ? 2
                              : 1;
                      final cardWidth = (constraints.maxWidth - (cols - 1) * 16) / cols;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: filtered.map((v) {
                          final expired = v.isExpired;
                          final isLive = v.active && !expired;
                          return SizedBox(
                            width: cardWidth,
                            child: AdminCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: isLive ? AdminColors.forest : AdminColors.surfaceMuted,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(15),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                v.shipping ? 'MIỄN PHÍ SHIP' : 'GIẢM ${v.percent}%',
                                                style: TextStyle(
                                                  fontSize: 21,
                                                  fontWeight: FontWeight.w700,
                                                  color: isLive
                                                      ? AdminColors.sage
                                                      : AdminColors.inkMuted,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                v.code,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1.4,
                                                  color: isLive
                                                      ? Colors.white
                                                      : AdminColors.inkSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        AdminBadge(
                                          label: expired
                                              ? 'Hết hạn'
                                              : v.active
                                                  ? 'Đang chạy'
                                                  : 'Tạm tắt',
                                          color: expired
                                              ? AdminColors.rose
                                              : v.active
                                                  ? AdminColors.emerald
                                                  : AdminColors.inkSecondary,
                                          bgColor: expired
                                              ? AdminColors.roseBg
                                              : v.active
                                                  ? AdminColors.emeraldBg
                                                  : Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            AdminBadge(
                                              label: v.audienceSummary,
                                              color: AdminColors.forest,
                                              bgColor: AdminColors.sageSoft,
                                              icon: Iconsax.people,
                                            ),
                                            if (v.autoTag.isNotEmpty)
                                              const AdminBadge(
                                                label: 'AUTO',
                                                color: Color(0xFFB45309),
                                                bgColor: Color(0xFFFEF3C7),
                                                icon: Icons.auto_awesome_rounded,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          v.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AdminColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (!v.shipping)
                                          Text(
                                            'Giảm tối đa: ${widget.controller.formatMoney(v.maxUsd)}',
                                            style: const TextStyle(
                                                fontSize: 12.5,
                                                color: AdminColors.inkSecondary),
                                          ),
                                        Text(
                                          'Đơn tối thiểu: ${v.minUsd > 0 ? widget.controller.formatMoney(v.minUsd) : 'Không yêu cầu'}',
                                          style: const TextStyle(
                                              fontSize: 12.5,
                                              color: AdminColors.inkSecondary),
                                        ),
                                        Text(
                                          'HSD: ${DateFormat('dd/MM/yyyy').format(v.expires)}',
                                          style: const TextStyle(
                                              fontSize: 12, color: AdminColors.inkMuted),
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Switch(
                                              value: v.active,
                                              activeColor: AdminColors.forest,
                                              onChanged: (val) => widget.controller
                                                  .toggleVoucherActive(v, val),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              tooltip: 'Chỉnh sửa',
                                              onPressed: () => _openEditor(existing: v),
                                              icon: const Icon(Iconsax.edit_2,
                                                  size: 18, color: AdminColors.forest),
                                            ),
                                            IconButton(
                                              tooltip: 'Xóa voucher',
                                              onPressed: () async {
                                                final ok = await showAdminConfirmDialog(
                                                  context,
                                                  title: 'Xóa voucher ${v.code}?',
                                                  message:
                                                      'Mã giảm giá này sẽ bị xóa khỏi hệ thống.',
                                                );
                                                if (ok) {
                                                  await widget.controller.deleteVoucher(v);
                                                }
                                              },
                                              icon: const Icon(Iconsax.trash,
                                                  size: 18, color: AdminColors.rose),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
