import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/features/authentication/models/user_model.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/utils/constants/admin_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  String _query = '';
  String _roleFilter = 'all';

  Future<void> _openUserDetail(UserModel user) async {
    final userOrders = widget.controller.ordersForUser(user.id);
    final totalSpent = widget.controller.totalSpentForUser(user.id);
    final addressesFuture = widget.controller.fetchUserAddresses(user.id);
    final isAdmin = AdminConfig.isAdminEmail(user.email);

    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 740),
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.fullName.trim().isNotEmpty
                                      ? user.fullName
                                      : user.username,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AdminBadge(
                                label: isAdmin ? 'Quản trị viên' : 'Khách hàng',
                                color: isAdmin ? AdminColors.forest : AdminColors.sky,
                                bgColor: isAdmin ? AdminColors.sageSoft : AdminColors.skyBg,
                                icon: isAdmin ? Iconsax.shield_tick : Iconsax.user,
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
                      // Quick metrics
                      Row(
                        children: [
                          Expanded(
                            child: _MiniMetric(
                              label: 'Số đơn hàng',
                              value: '${userOrders.length}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniMetric(
                              label: 'Tổng chi tiêu',
                              value: widget.controller.formatMoney(totalSpent),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniMetric(
                              label: 'Username',
                              value: user.username.isNotEmpty ? '@${user.username}' : '—',
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
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                  'Đơn #${rec.order.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  '${DateFormat('dd/MM/yyyy').format(rec.order.orderDate)} • ${rec.order.items.length} mặt hàng',
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.controller.formatMoney(rec.order.totalAmount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
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
                    if (!isAdmin)
                      AdminPrimaryButton(
                        label: 'Gửi thông báo cho khách này',
                        icon: Iconsax.notification_bing,
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.controller.openNotificationComposerForUser(user.id);
                        },
                      ),
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
      final all = widget.controller.users;
      final q = _query.trim().toLowerCase();
      final filtered = all.where((u) {
        final isAdmin = AdminConfig.isAdminEmail(u.email);
        if (_roleFilter == 'admin' && !isAdmin) return false;
        if (_roleFilter == 'client' && isAdmin) return false;
        if (q.isEmpty) return true;
        return u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.phoneNumber.toLowerCase().contains(q) ||
            u.username.toLowerCase().contains(q);
      }).toList();

      final adminCount = all.where((u) => AdminConfig.isAdminEmail(u.email)).length;
      final clientCount = all.length - adminCount;

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Quản lý Người dùng (${all.length})',
                  subtitle:
                      'Email ${AdminConfig.adminEmail} là Quản trị viên duy nhất; toàn bộ email khác là tài khoản Khách hàng.',
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
                      label: Text('Tất cả (${all.length})'),
                      selected: _roleFilter == 'all',
                      onSelected: (_) => setState(() => _roleFilter = 'all'),
                    ),
                    ChoiceChip(
                      label: Text('Khách hàng ($clientCount)'),
                      selected: _roleFilter == 'client',
                      onSelected: (_) => setState(() => _roleFilter = 'client'),
                    ),
                    ChoiceChip(
                      label: Text('Quản trị viên ($adminCount)'),
                      selected: _roleFilter == 'admin',
                      onSelected: (_) => setState(() => _roleFilter = 'admin'),
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
                          subtitle: 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm.',
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 960),
                            child: DataTable(
                              headingRowColor:
                                  WidgetStateProperty.all(AdminColors.surfaceMuted),
                              dataRowMinHeight: 62,
                              dataRowMaxHeight: 68,
                              columns: const [
                                DataColumn(label: Text('Người dùng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Số điện thoại', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Vai trò', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Đơn hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Tổng chi tiêu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                              ],
                              rows: filtered.map((user) {
                                final isAdmin = AdminConfig.isAdminEmail(user.email);
                                final orderCount =
                                    widget.controller.ordersForUser(user.id).length;
                                final spent =
                                    widget.controller.totalSpentForUser(user.id);
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
                                    DataCell(Text(user.email, style: const TextStyle(fontSize: 12.5))),
                                    DataCell(Text(
                                      user.phoneNumber.isNotEmpty ? user.phoneNumber : '—',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AdminColors.inkSecondary,
                                      ),
                                    )),
                                    DataCell(AdminBadge(
                                      label: isAdmin ? 'Admin' : 'User',
                                      color: isAdmin ? AdminColors.forest : AdminColors.sky,
                                      bgColor:
                                          isAdmin ? AdminColors.sageSoft : AdminColors.skyBg,
                                      icon: isAdmin ? Iconsax.shield_tick : Iconsax.user,
                                    )),
                                    DataCell(Text(
                                      '$orderCount đơn',
                                      style: const TextStyle(fontSize: 12.5),
                                    )),
                                    DataCell(Text(
                                      widget.controller.formatMoney(spent),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    )),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Xem chi tiết khách hàng',
                                          onPressed: () => _openUserDetail(user),
                                          icon: const Icon(Iconsax.eye,
                                              size: 18, color: AdminColors.forest),
                                        ),
                                        if (!isAdmin) ...[
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
                                                    'Hồ sơ trong collection Users sẽ bị xóa. Lưu ý: để khóa đăng nhập vĩnh viễn hãy tắt/xóa tài khoản trong Firebase Authentication Console.',
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
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AdminColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
