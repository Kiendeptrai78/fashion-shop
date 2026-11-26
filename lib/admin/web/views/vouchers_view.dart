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
  String _typeFilter = 'all'; // 'all' | 'product' | 'shipping'
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

  Future<void> _openEditor({
    AdminVoucherRecord? existing,
    String? preselectedUserId,
    bool defaultShipping = false,
  }) async {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final percentCtrl =
        TextEditingController(text: (existing?.percent ?? 15).toString());
    final maxUsdCtrl =
        TextEditingController(text: (existing?.maxUsd ?? 20).toString());
    final minUsdCtrl =
        TextEditingController(text: (existing?.minUsd ?? 50).toString());
    bool shipping = existing?.shipping ?? defaultShipping;
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
    DateTime expires =
        existing?.expires ?? DateTime.now().add(const Duration(days: 14));
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
          final bomCount = clientStats
              .where((s) => s.segment == CustomerSegment.bomHang)
              .length;
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 16, 14, 14),
                    decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: AdminColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            existing == null
                                ? (shipping
                                    ? 'Tạo Mã Miễn phí vận chuyển (Freeship)'
                                    : 'Tạo Mã Giảm giá sản phẩm')
                                : 'Chỉnh sửa Voucher ${existing.code}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed:
                              saving ? null : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Explicit 2-Type Selector right at the top
                            const Text(
                              'Loại Voucher',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AdminColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () =>
                                        setModalState(() => shipping = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 11,
                                      ),
                                      decoration: BoxDecoration(
                                        color: !shipping
                                            ? AdminColors.sageSoft
                                                .withValues(alpha: 0.5)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: !shipping
                                              ? AdminColors.forest
                                              : AdminColors.border,
                                          width: !shipping ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Iconsax.discount_shape,
                                            size: 18,
                                            color: !shipping
                                                ? AdminColors.forest
                                                : AdminColors.inkSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'Giảm giá sản phẩm (%)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () =>
                                        setModalState(() => shipping = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 11,
                                      ),
                                      decoration: BoxDecoration(
                                        color: shipping
                                            ? AdminColors.sageSoft
                                                .withValues(alpha: 0.5)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: shipping
                                              ? AdminColors.forest
                                              : AdminColors.border,
                                          width: shipping ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.local_shipping_outlined,
                                            size: 18,
                                            color: shipping
                                                ? AdminColors.forest
                                                : AdminColors.inkSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'Miễn phí vận chuyển',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: codeCtrl,
                              readOnly: existing != null,
                              textCapitalization: TextCapitalization.characters,
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'Vui lòng nhập mã voucher';
                                if (s.contains(' ')) {
                                  return 'Mã voucher không được có khoảng trắng';
                                }
                                return null;
                              },
                              decoration: adminInputDecoration(
                                label: 'Mã Voucher (CODE) *',
                                hint: shipping
                                    ? 'Ví dụ: FREESHIP0D, SHIPVIP'
                                    : 'Ví dụ: VELORA20, VIP30',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: titleCtrl,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Vui lòng nhập mô tả ưu đãi'
                                  : null,
                              decoration: adminInputDecoration(
                                label: 'Tên / Mô tả chương trình *',
                                hint: shipping
                                    ? 'Ví dụ: Miễn phí giao hàng toàn quốc'
                                    : 'Ví dụ: Ưu đãi khách thân thiết cuối tuần',
                              ),
                            ),
                            const SizedBox(height: 14),

                            if (!shipping) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: percentCtrl,
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        final n = int.tryParse((v ?? '').trim());
                                        if (n == null || n <= 0 || n > 100) {
                                          return 'Từ 1 đến 100%';
                                        }
                                        return null;
                                      },
                                      decoration: adminInputDecoration(
                                        label: 'Mức giảm (%) *',
                                        hint: '15',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: maxUsdCtrl,
                                      onChanged: (_) => setModalState(() {}),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      validator: (v) {
                                        final n =
                                            double.tryParse((v ?? '').trim());
                                        if (n == null || n <= 0) {
                                          return 'Nhập số dương';
                                        }
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
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  'Tối đa quy đổi: ${formatShopMoney(maxUsd, language: 'vi')}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AdminColors.inkSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: minUsdCtrl,
                                    onChanged: (_) => setModalState(() {}),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
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
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                            23,
                                            59,
                                          );
                                        });
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 15,
                                      ),
                                      side: const BorderSide(
                                        color: AdminColors.borderStrong,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                    ),
                                    icon:
                                        const Icon(Iconsax.calendar, size: 16),
                                    label: Text(
                                      'HSD: ${DateFormat('dd/MM/yyyy').format(expires)}',
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                'Đơn tối thiểu quy đổi: ${formatShopMoney(minUsd, language: 'vi')}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AdminColors.inkSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Audience targeting section
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AdminColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AdminColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Đối tượng áp dụng',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AdminColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    value: targetAudience,
                                    isExpanded: true,
                                    decoration: adminInputDecoration(
                                      label: 'Phân khúc khách hàng',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'all',
                                        child: Text('Tất cả khách hàng'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'newMember',
                                        child: Text(
                                          'Thành viên mới (chưa mua đơn nào)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'loyal',
                                        child: Text(
                                          'Khách lâu năm & VIP (≥ 1 đơn)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'vip',
                                        child: Text('Chỉ Khách VIP'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'specific',
                                        child: Text(
                                          'Chọn đích danh từng khách...',
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) => setModalState(
                                      () => targetAudience = v ?? 'all',
                                    ),
                                  ),
                                  if (targetAudience != 'specific') ...[
                                    const SizedBox(height: 4),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      activeColor: AdminColors.forest,
                                      title: Text(
                                        'Loại trừ tài khoản bom hàng ($bomCount tài khoản)',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      value: excludeBomHang,
                                      onChanged: (v) => setModalState(
                                        () => excludeBomHang = v,
                                      ),
                                    ),
                                  ],
                                  if (targetAudience == 'specific') ...[
                                    const SizedBox(height: 10),
                                    TextField(
                                      onChanged: (v) =>
                                          setModalState(() => userSearch = v),
                                      decoration: adminInputDecoration(
                                        label: 'Tìm khách hàng',
                                        hint: 'Nhập tên hoặc email...',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      constraints:
                                          const BoxConstraints(maxHeight: 180),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AdminColors.border,
                                        ),
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: filteredClients.length,
                                        itemBuilder: (_, idx) {
                                          final st = filteredClients[idx];
                                          final checked = selectedUserIds
                                              .contains(st.user.id);
                                          return CheckboxListTile(
                                            dense: true,
                                            activeColor: AdminColors.forest,
                                            value: checked,
                                            onChanged: (val) =>
                                                setModalState(() {
                                              if (val == true) {
                                                selectedUserIds.add(st.user.id);
                                              } else {
                                                selectedUserIds
                                                    .remove(st.user.id);
                                              }
                                            }),
                                            title: Text(
                                              st.user.fullName.trim().isNotEmpty
                                                  ? st.user.fullName
                                                  : st.user.email,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${st.user.email} · ${st.receivedOrders} nhận / ${st.cancelledOrders} hủy',
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    'Áp dụng cho ${matchedUsers.length} khách hàng phù hợp.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AdminColors.inkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              activeColor: AdminColors.forest,
                              title: const Text(
                                'Kích hoạt Voucher ngay',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: active,
                              onChanged: (v) =>
                                  setModalState(() => active = v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              activeColor: AdminColors.forest,
                              title: Text(
                                'Gửi thông báo đẩy tới ${matchedUsers.length} khách hàng',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: sendNotification,
                              onChanged: (v) =>
                                  setModalState(() => sendNotification = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
                    decoration: const BoxDecoration(
                      border:
                          Border(top: BorderSide(color: AdminColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed:
                              saving ? null : () => Navigator.of(context).pop(),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 10),
                        AdminPrimaryButton(
                          label:
                              existing == null ? 'Tạo Voucher' : 'Lưu thay đổi',
                          icon: Iconsax.tick_circle,
                          loading: saving,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            if (targetAudience == 'specific' &&
                                selectedUserIds.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Vui lòng chọn ít nhất 1 khách hàng nhận Voucher.',
                                  ),
                                ),
                              );
                              return;
                            }
                            setModalState(() => saving = true);
                            final ok = await widget.controller.saveVoucher(
                              AdminVoucherRecord(
                                code: codeCtrl.text.trim().toUpperCase(),
                                title: titleCtrl.text.trim(),
                                percent: shipping
                                    ? 0
                                    : (int.tryParse(percentCtrl.text.trim()) ??
                                        0),
                                maxUsd: shipping
                                    ? 0
                                    : (double.tryParse(
                                            maxUsdCtrl.text.trim()) ??
                                        0),
                                minUsd:
                                    double.tryParse(minUsdCtrl.text.trim()) ??
                                        0,
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

  Widget _compactAutoChip({
    required String label,
    required int percent,
    required int targetCount,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required VoidCallback onIssueNow,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.ink,
                ),
              ),
              Text(
                '-$percent% · $targetCount khách',
                style: const TextStyle(
                  fontSize: 11,
                  color: AdminColors.inkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 28,
            child: FittedBox(
              child: Switch(
                value: enabled,
                activeColor: AdminColors.forest,
                onChanged: onToggle,
              ),
            ),
          ),
          TextButton(
            onPressed: _autoBusy ? null : onIssueNow,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Phát ngay',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AdminColors.forest,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Single compact horizontal row per voucher (clean vertical list).
  Widget _buildCompactVoucherRow(AdminVoucherRecord v) {
    final expired = v.isExpired;
    final isLive = v.active && !expired;

    final statusLabel = expired
        ? 'Hết hạn'
        : (v.active ? 'Đang chạy' : 'Tạm tắt');
    final statusColor = expired
        ? AdminColors.rose
        : (v.active ? AdminColors.emerald : AdminColors.inkSecondary);
    final statusBg = expired
        ? AdminColors.roseBg
        : (v.active ? AdminColors.emeraldBg : AdminColors.surfaceMuted);

    final minText = v.minUsd > 0
        ? 'Đơn từ ${widget.controller.formatMoney(v.minUsd)}'
        : 'Đơn 0đ';
    final maxText = !v.shipping && v.maxUsd > 0
        ? 'Tối đa ${widget.controller.formatMoney(v.maxUsd)} · '
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // 1. Compact Type & Value Stub
          Container(
            width: 96,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isLive
                  ? AdminColors.sageSoft.withValues(alpha: 0.55)
                  : AdminColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  v.shipping ? 'FREESHIP' : '-${v.percent}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isLive ? AdminColors.forest : AdminColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  v.shipping ? 'Vận chuyển' : 'Sản phẩm',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AdminColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 2. Code, Title & Conditions on 2 tight lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      v.code,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AdminColors.ink,
                      ),
                    ),
                    Text(
                      '· ${v.title}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$maxText$minText · Đối tượng: ${v.audienceSummary} · HSD: ${DateFormat('dd/MM/yyyy').format(v.expires)}',
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 3. Single Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 4. Compact Switch + Edit + Delete
          SizedBox(
            height: 28,
            child: FittedBox(
              child: Switch(
                value: v.active,
                activeColor: AdminColors.forest,
                onChanged: (val) =>
                    widget.controller.toggleVoucherActive(v, val),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Chỉnh sửa',
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            onPressed: () => _openEditor(existing: v),
            icon: const Icon(
              Iconsax.edit_2,
              size: 16,
              color: AdminColors.inkSecondary,
            ),
          ),
          IconButton(
            tooltip: 'Xóa voucher',
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            onPressed: () async {
              final ok = await showAdminConfirmDialog(
                context,
                title: 'Xóa voucher ${v.code}?',
                message: 'Mã giảm giá này sẽ bị xóa khỏi hệ thống.',
              );
              if (ok) {
                await widget.controller.deleteVoucher(v);
              }
            },
            icon: const Icon(
              Iconsax.trash,
              size: 16,
              color: AdminColors.rose,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListGroupCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<AdminVoucherRecord> items,
  }) {
    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
            child: Row(
              children: [
                Icon(icon, size: 17, color: AdminColors.ink),
                const SizedBox(width: 8),
                Text(
                  '$title (${items.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AdminColors.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.border),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Text(
                'Chưa có mã nào trong nhóm này.',
                style: TextStyle(fontSize: 12.5, color: AdminColors.inkMuted),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AdminColors.border),
              itemBuilder: (_, idx) => _buildCompactVoucherRow(items[idx]),
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

      final audienceFiltered = all.where((v) {
        if (_audienceFilter != 'all' && v.targetAudience != _audienceFilter) {
          return false;
        }
        if (q.isEmpty) return true;
        return v.code.toLowerCase().contains(q) ||
            v.title.toLowerCase().contains(q);
      }).toList();

      final shippingList =
          audienceFiltered.where((v) => v.shipping).toList();
      final productList =
          audienceFiltered.where((v) => !v.shipping).toList();

      final newCount = widget.controller
          .usersMatchingVoucherAudience(
              targetAudience: 'newMember', excludeBomHang: true)
          .length;
      final allCleanCount = widget.controller
          .usersMatchingVoucherAudience(
              targetAudience: 'all', excludeBomHang: true)
          .length;
      final vipCount = widget.controller
          .usersMatchingVoucherAudience(
              targetAudience: 'vip', excludeBomHang: true)
          .length;

      final typeTabs = [
        ('all', 'Tất cả (${audienceFiltered.length})'),
        ('shipping', 'Mã Freeship (${shippingList.length})'),
        ('product', 'Mã Giảm giá SP (${productList.length})'),
      ];

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Mã giảm giá (${all.length})',
                  actions: [
                    AdminSearchField(
                      hint: 'Tìm mã voucher...',
                      width: 220,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openEditor(defaultShipping: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.ink,
                        side: const BorderSide(color: AdminColors.borderStrong),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.local_shipping_outlined, size: 17),
                      label: const Text(
                        '+ Mã Freeship',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AdminPrimaryButton(
                      label: '+ Mã Giảm giá SP',
                      icon: Iconsax.ticket_discount,
                      onPressed: () => _openEditor(defaultShipping: false),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Slim 1-bar Auto-Voucher Strip (compact, zero screen bloat)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.flash_1,
                            size: 16,
                            color: AdminColors.forest,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Phát tự động:',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.ink,
                            ),
                          ),
                        ],
                      ),
                      _compactAutoChip(
                        label: 'Thành viên mới',
                        percent: cfg.welcomePercent,
                        targetCount: newCount,
                        enabled: cfg.autoWelcomeVoucher,
                        onToggle: (v) =>
                            widget.controller.saveAutomationSettings(
                          cfg.copyWith(autoWelcomeVoucher: v),
                        ),
                        onIssueNow: () async {
                          setState(() => _autoBusy = true);
                          await widget.controller
                              .issueAutoVoucherNow('new_member');
                          if (mounted) setState(() => _autoBusy = false);
                        },
                      ),
                      _compactAutoChip(
                        label: 'Dịp Lễ VN',
                        percent: cfg.holidayPercent,
                        targetCount: allCleanCount,
                        enabled: cfg.autoHolidayVoucher,
                        onToggle: (v) =>
                            widget.controller.saveAutomationSettings(
                          cfg.copyWith(autoHolidayVoucher: v),
                        ),
                        onIssueNow: () async {
                          setState(() => _autoBusy = true);
                          await widget.controller
                              .issueAutoVoucherNow('holiday');
                          if (mounted) setState(() => _autoBusy = false);
                        },
                      ),
                      _compactAutoChip(
                        label: 'Tri ân VIP',
                        percent: cfg.vipPercent,
                        targetCount: vipCount,
                        enabled: cfg.autoVipVoucher,
                        onToggle: (v) =>
                            widget.controller.saveAutomationSettings(
                          cfg.copyWith(autoVipVoucher: v),
                        ),
                        onIssueNow: () async {
                          setState(() => _autoBusy = true);
                          await widget.controller.issueAutoVoucherNow('vip');
                          if (mounted) setState(() => _autoBusy = false);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Colorless underline Type Tabs + Audience Filter on one clean bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < typeTabs.length; i++) ...[
                            if (i > 0) const SizedBox(width: 22),
                            InkWell(
                              onTap: () =>
                                  setState(() => _typeFilter = typeTabs[i].$1),
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _typeFilter == typeTabs[i].$1
                                          ? AdminColors.ink
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  typeTabs[i].$2,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _typeFilter == typeTabs[i].$1
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _typeFilter == typeTabs[i].$1
                                        ? AdminColors.ink
                                        : AdminColors.inkSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _audienceFilter,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AdminColors.ink,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('Đối tượng: Tất cả'),
                            ),
                            DropdownMenuItem(
                              value: 'newMember',
                              child: Text('Đối tượng: Thành viên mới'),
                            ),
                            DropdownMenuItem(
                              value: 'loyal',
                              child: Text('Đối tượng: Khách lâu năm'),
                            ),
                            DropdownMenuItem(
                              value: 'vip',
                              child: Text('Đối tượng: Khách VIP'),
                            ),
                            DropdownMenuItem(
                              value: 'specific',
                              child: Text('Đối tượng: Tặng riêng'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _audienceFilter = v ?? 'all'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Compact Vertical Lists separated into 2 clear categories
                if (audienceFiltered.isEmpty)
                  AdminCard(
                    child: AdminEmptyState(
                      icon: Iconsax.ticket_discount,
                      title: 'Chưa có voucher nào phù hợp',
                      subtitle:
                          'Bấm "+ Mã Freeship" hoặc "+ Mã Giảm giá SP" ở góc trên để tạo mới.',
                      action: AdminPrimaryButton(
                        label: '+ Tạo Voucher mới',
                        icon: Iconsax.ticket_discount,
                        onPressed: () => _openEditor(),
                      ),
                    ),
                  )
                else ...[
                  if (_typeFilter == 'all' || _typeFilter == 'shipping') ...[
                    _buildListGroupCard(
                      icon: Icons.local_shipping_outlined,
                      title: 'Mã Miễn phí vận chuyển (Freeship)',
                      subtitle: 'Khách áp tối đa 1 mã vận chuyển / đơn',
                      items: shippingList,
                    ),
                    if (_typeFilter == 'all') const SizedBox(height: 14),
                  ],
                  if (_typeFilter == 'all' || _typeFilter == 'product')
                    _buildListGroupCard(
                      icon: Iconsax.discount_shape,
                      title: 'Mã Giảm giá sản phẩm',
                      subtitle: 'Khách áp tối đa 1 mã giảm giá SP / đơn',
                      items: productList,
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
