import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/utils/constants/admin_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

({String label, Color color, Color bg, IconData icon}) segmentBadgeMeta(CustomerSegment seg) {
  switch (seg) {
    case CustomerSegment.vip:
      return (
        label: 'Khách VIP',
        color: const Color(0xFFB45309),
        bg: const Color(0xFFFEF3C7),
        icon: Iconsax.crown_1,
      );
    case CustomerSegment.loyal:
      return (
        label: 'Khách lâu năm',
        color: AdminColors.emerald,
        bg: AdminColors.emeraldBg,
        icon: Iconsax.verify,
      );
    case CustomerSegment.newMember:
      return (
        label: 'Thành viên mới',
        color: AdminColors.sky,
        bg: AdminColors.skyBg,
        icon: Iconsax.user_add,
      );
    case CustomerSegment.bomHang:
      return (
        label: 'Cảnh báo bom hàng',
        color: AdminColors.rose,
        bg: AdminColors.roseBg,
        icon: Iconsax.warning_2,
      );
    case CustomerSegment.admin:
      return (
        label: 'Quản trị viên',
        color: AdminColors.forest,
        bg: AdminColors.sageSoft,
        icon: Iconsax.shield_tick,
      );
  }
}

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  String _query = '';
  String _segmentFilter = 'all'; // 'all' | 'vip' | 'loyal' | 'newMember' | 'bomHang' | 'admin'

  Future<void> _openUserDetail(CustomerProfileStats stats) async {
    final user = stats.user;
    final userOrders = widget.controller.ordersForUser(user.id);
    final addressesFuture = widget.controller.fetchUserAddresses(user.id);
    final isAdmin = stats.segment == CustomerSegment.admin;
    final badge = segmentBadgeMeta(stats.segment);

    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740, maxHeight: 760),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AdminColors.border)),
                ),
                child: Row(
                  children: [
                    AdminImageThumb(
                      url: user.profilePicture,
                      width: 48,
                      height: 48,
                      borderRadius: 999,
                      placeholderIcon: Iconsax.user,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                user.fullName.trim().isNotEmpty ? user.fullName : user.username,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AdminColors.ink,
                                ),
                              ),
                              AdminBadge(
                                label: badge.label,
                                color: badge.color,
                                bgColor: badge.bg,
                                icon: badge.icon,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${user.email}${user.phoneNumber.isNotEmpty ? ' • ${user.phoneNumber}' : ''}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AdminColors.inkSecondary,
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
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stats.segment == CustomerSegment.bomHang) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AdminColors.roseBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AdminColors.rose.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.warning_2, color: AdminColors.rose, size: 19),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Tài khoản có ${stats.cancelledOrders}/${stats.totalOrders} đơn bị hủy (${(stats.cancelRate * 100).round()}%). Hệ thống tự động loại trừ khi phát Voucher khuyến mãi chung.',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AdminColors.rose,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Quick metrics
                      Row(
                        children: [
                          Expanded(
                            child: _MiniMetric(
                              label: 'Thành công / Tổng đơn',
                              value: '${stats.receivedOrders} / ${stats.totalOrders}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniMetric(
                              label: 'Đơn đã hủy',
                              value: '${stats.cancelledOrders} đơn',
                              highlightRose: stats.cancelledOrders >= 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniMetric(
                              label: 'Tổng chi tiêu',
                              value: widget.controller.formatMoney(stats.totalSpent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Saved Addresses
                      const Text(
                        'Sổ địa chỉ đã lưu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<AddressModel>>(
                        future: addressesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          final addresses = snapshot.data ?? [];
                          if (addresses.isEmpty) {
                            return const Text(
                              'Chưa lưu địa chỉ giao hàng nào.',
                              style: TextStyle(fontSize: 12.5, color: AdminColors.inkMuted),
                            );
                          }
                          return Column(
                            children: addresses.map((addr) {
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AdminColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(color: AdminColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${addr.name} • ${addr.phoneNumber}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      addr.toString(),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AdminColors.inkSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // Recent Orders
                      const Text(
                        'Lịch sử đơn hàng',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (userOrders.isEmpty)
                        const Text(
                          'Khách hàng chưa có đơn hàng nào.',
                          style: TextStyle(fontSize: 12.5, color: AdminColors.inkMuted),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AdminColors.border),
                          ),
                          child: Column(
                            children: userOrders.map((rec) {
                              final meta = AdminOrderStatusMeta.of(rec.order.status);
                              return ListTile(
                                dense: true,
                                title: Text(
                                  rec.order.itemsSummary(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                subtitle: Text(
                                  '${DateFormat('dd/MM/yyyy').format(rec.order.orderDate)} • #${rec.order.id}',
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.controller.formatMoney(rec.order.totalAmount),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                                    ),
                                    const SizedBox(width: 10),
                                    AdminBadge(
                                      label: meta.label,
                                      color: meta.color,
                                      bgColor: meta.bgColor,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AdminColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isAdmin) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.controller.openVoucherComposerForUser(user.id);
                        },
                        icon: const Icon(Iconsax.ticket_discount, size: 17),
                        label: const Text('Tặng Voucher riêng'),
                      ),
                      const SizedBox(width: 10),
                      AdminPrimaryButton(
                        label: 'Gửi thông báo cho khách này',
                        icon: Iconsax.notification_bing,
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.controller.openNotificationComposerForUser(user.id);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Obx(() {
      final allStats = widget.controller.users.map(widget.controller.customerStatsFor).toList();
      final q = _query.trim().toLowerCase();

      int countOf(CustomerSegment s) => allStats.where((st) => st.segment == s).length;

      final filtered = allStats.where((st) {
        if (_segmentFilter == 'vip' && st.segment != CustomerSegment.vip) return false;
        if (_segmentFilter == 'loyal' && st.segment != CustomerSegment.loyal) return false;
        if (_segmentFilter == 'newMember' && st.segment != CustomerSegment.newMember) return false;
        if (_segmentFilter == 'bomHang' && st.segment != CustomerSegment.bomHang) return false;
        if (_segmentFilter == 'admin' && st.segment != CustomerSegment.admin) return false;
        if (q.isEmpty) return true;
        final u = st.user;
        return u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.phoneNumber.toLowerCase().contains(q) ||
            u.username.toLowerCase().contains(q);
      }).toList();

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Quản lý & Phân loại Khách hàng (${allStats.length})',
                  subtitle:
                      'Tự động phân hạng Khách VIP, Khách lâu năm, Thành viên mới và Cảnh báo bom hàng dựa trên lịch sử mua thực tế.',
                  actions: [
                    AdminSearchField(
                      hint: 'Tìm theo tên, email, số điện thoại...',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('Tất cả (${allStats.length})'),
                      selected: _segmentFilter == 'all',
                      onSelected: (_) => setState(() => _segmentFilter = 'all'),
                    ),
                    ChoiceChip(
                      label: Text('Khách VIP (${countOf(CustomerSegment.vip)})'),
                      selected: _segmentFilter == 'vip',
                      onSelected: (_) => setState(() => _segmentFilter = 'vip'),
                    ),
                    ChoiceChip(
                      label: Text('Khách lâu năm (${countOf(CustomerSegment.loyal)})'),
                      selected: _segmentFilter == 'loyal',
                      onSelected: (_) => setState(() => _segmentFilter = 'loyal'),
                    ),
                    ChoiceChip(
                      label: Text('Thành viên mới (${countOf(CustomerSegment.newMember)})'),
                      selected: _segmentFilter == 'newMember',
                      onSelected: (_) => setState(() => _segmentFilter = 'newMember'),
                    ),
                    ChoiceChip(
                      selectedColor: AdminColors.rose,
                      checkmarkColor: Colors.white,
                      label: Text(
                        'Cảnh báo bom hàng (${countOf(CustomerSegment.bomHang)})',
                        style: TextStyle(
                          color: _segmentFilter == 'bomHang'
                              ? Colors.white
                              : AdminColors.rose,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      selected: _segmentFilter == 'bomHang',
                      onSelected: (_) => setState(() => _segmentFilter = 'bomHang'),
                    ),
                    ChoiceChip(
                      label: Text('Quản trị viên (${countOf(CustomerSegment.admin)})'),
                      selected: _segmentFilter == 'admin',
                      onSelected: (_) => setState(() => _segmentFilter = 'admin'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                AdminCard(
                  padding: EdgeInsets.zero,
                  child: filtered.isEmpty
                      ? const AdminEmptyState(
                          icon: Iconsax.people,
                          title: 'Không tìm thấy người dùng',
                          subtitle: 'Thử thay đổi phân khúc hoặc từ khóa tìm kiếm.',
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 1020),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(AdminColors.surfaceMuted),
                              dataRowMinHeight: 64,
                              dataRowMaxHeight: 72,
                              columns: const [
                                DataColumn(label: Text('Khách hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Email & SĐT', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Phân loại', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Thành công / Hủy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Tổng chi tiêu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                              ],
                              rows: filtered.map((stats) {
                                final user = stats.user;
                                final isAdmin = AdminConfig.isAdminEmail(user.email);
                                final badge = segmentBadgeMeta(stats.segment);
                                return DataRow(
                                  cells: [
                                    DataCell(Row(
                                      children: [
                                        AdminImageThumb(
                                          url: user.profilePicture,
                                          width: 40,
                                          height: 40,
                                          borderRadius: 999,
                                          placeholderIcon: Iconsax.user,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.fullName.trim().isNotEmpty
                                                  ? user.fullName
                                                  : 'Chưa đặt tên',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (user.username.isNotEmpty)
                                              Text(
                                                '@${user.username}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AdminColors.inkMuted,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    )),
                                    DataCell(Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(user.email, style: const TextStyle(fontSize: 12.5)),
                                        if (user.phoneNumber.isNotEmpty)
                                          Text(
                                            user.phoneNumber,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AdminColors.inkMuted,
                                            ),
                                          ),
                                      ],
                                    )),
                                    DataCell(AdminBadge(
                                      label: badge.label,
                                      color: badge.color,
                                      bgColor: badge.bg,
                                      icon: badge.icon,
                                    )),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${stats.receivedOrders} nhận',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: AdminColors.emerald,
                                          ),
                                        ),
                                        const Text(' · ', style: TextStyle(color: AdminColors.inkMuted)),
                                        Text(
                                          '${stats.cancelledOrders} hủy',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: stats.cancelledOrders >= 2
                                                ? AdminColors.rose
                                                : AdminColors.inkSecondary,
                                          ),
                                        ),
                                      ],
                                    )),
                                    DataCell(Text(
                                      widget.controller.formatMoney(stats.totalSpent),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: AdminColors.forest,
                                      ),
                                    )),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Xem chi tiết khách hàng',
                                          onPressed: () => _openUserDetail(stats),
                                          icon: const Icon(Iconsax.eye, size: 18, color: AdminColors.forest),
                                        ),
                                        if (!isAdmin) ...[
                                          IconButton(
                                            tooltip: 'Tặng Voucher riêng',
                                            onPressed: () => widget.controller
                                                .openVoucherComposerForUser(user.id),
                                            icon: const Icon(Iconsax.ticket_discount,
                                                size: 18, color: Color(0xFFB45309)),
                                          ),
                                          IconButton(
                                            tooltip: 'Gửi thông báo riêng',
                                            onPressed: () => widget.controller
                                                .openNotificationComposerForUser(user.id),
                                            icon: const Icon(Iconsax.notification,
                                                size: 18, color: AdminColors.sky),
                                          ),
                                          IconButton(
                                            tooltip: 'Xóa hồ sơ người dùng',
                                            onPressed: () async {
                                              final ok = await showAdminConfirmDialog(
                                                context,
                                                title: 'Xóa hồ sơ ${user.email}?',
                                                message:
                                                    'Hồ sơ trong collection Users sẽ bị xóa.',
                                              );
                                              if (ok) {
                                                await widget.controller.deleteUser(user);
                                              }
                                            },
                                            icon: const Icon(Iconsax.trash,
                                                size: 18, color: AdminColors.rose),
                                          ),
                                        ],
                                      ],
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value, this.highlightRose = false});

  final String label;
  final String value;
  final bool highlightRose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlightRose ? AdminColors.roseBg : AdminColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlightRose ? AdminColors.rose.withValues(alpha: 0.3) : AdminColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AdminColors.inkMuted)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: highlightRose ? AdminColors.rose : AdminColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
