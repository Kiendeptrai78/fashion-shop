import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class AdminOrdersView extends StatefulWidget {
  const AdminOrdersView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends State<AdminOrdersView> {
  OrderStatus? _selectedStatus;
  String _query = '';

  List<AdminOrderRecord> _filtered(List<AdminOrderRecord> all) {
    final q = _query.trim().toLowerCase();
    return all.where((record) {
      if (_selectedStatus != null && record.order.status != _selectedStatus) {
        return false;
      }
      if (q.isEmpty) return true;
      return record.order.id.toLowerCase().contains(q) ||
          record.customerName.toLowerCase().contains(q) ||
          record.customerEmail.toLowerCase().contains(q) ||
          record.order.paymentMethod.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openOrderDetail(AdminOrderRecord record) async {
    OrderStatus currentStatus = record.order.status;
    DateTime deliveryDate = record.order.deliveryDate;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final meta = AdminOrderStatusMeta.of(currentStatus);
          return Dialog(
            backgroundColor: AdminColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740, maxHeight: 760),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AdminColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Đơn hàng #${record.order.id}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AdminColors.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  AdminBadge(
                                    label: meta.label,
                                    color: meta.color,
                                    bgColor: meta.bgColor,
                                    icon: meta.icon,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Đặt ngày ${DateFormat('dd/MM/yyyy HH:mm').format(record.order.orderDate)} • ${record.order.paymentMethod}',
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

                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status & Delivery controls
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AdminColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AdminColors.border),
                            ),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 14,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.end,
                              children: [
                                SizedBox(
                                  width: 260,
                                  child: DropdownButtonFormField<OrderStatus>(
                                    value: currentStatus,
                                    decoration: adminInputDecoration(
                                      label: 'Cập nhật trạng thái đơn hàng',
                                    ),
                                    items: OrderStatus.values.map((status) {
                                      final sm = AdminOrderStatusMeta.of(status);
                                      return DropdownMenuItem(
                                        value: status,
                                        child: Text(
                                          sm.label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: sm.color,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: saving
                                        ? null
                                        : (next) async {
                                            if (next == null || next == currentStatus) return;
                                            setModalState(() => saving = true);
                                            await widget.controller
                                                .updateOrderStatus(record, next);
                                            setModalState(() {
                                              currentStatus = next;
                                              saving = false;
                                            });
                                          },
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: saving
                                      ? null
                                      : () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: deliveryDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2035),
                                          );
                                          if (picked != null) {
                                            setModalState(() => saving = true);
                                            await widget.controller
                                                .updateOrderDeliveryDate(record, picked);
                                            setModalState(() {
                                              deliveryDate = picked;
                                              saving = false;
                                            });
                                          }
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AdminColors.ink,
                                    side: const BorderSide(color: AdminColors.borderStrong),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  ),
                                  icon: const Icon(Iconsax.calendar, size: 17),
                                  label: Text(
                                    'Giao dự kiến: ${DateFormat('dd/MM/yyyy').format(deliveryDate)}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Customer & Address
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _InfoBox(
                                  title: 'Khách hàng',
                                  lines: [
                                    record.customerName,
                                    if (record.customerEmail.isNotEmpty) record.customerEmail,
                                    if ((record.customer?.phoneNumber ?? '').isNotEmpty)
                                      'SĐT: ${record.customer!.phoneNumber}',
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _InfoBox(
                                  title: 'Địa chỉ giao hàng',
                                  lines: record.order.address == null
                                      ? ['Không có thông tin địa chỉ']
                                      : [
                                          record.order.address!.name,
                                          record.order.address!.phoneNumber,
                                          record.order.address.toString(),
                                        ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Danh sách sản phẩm',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AdminColors.border),
                            ),
                            child: Column(
                              children: record.order.items.map((item) {
                                final variationText = item.selectedVariation?.entries
                                        .map((e) => '${e.key}: ${e.value}')
                                        .join(' • ') ??
                                    '';
                                return ListTile(
                                  leading: AdminImageThumb(
                                    url: item.image ?? '',
                                    width: 48,
                                    height: 48,
                                  ),
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'SL: ${item.quantity} × ${widget.controller.formatMoney(item.price)}'
                                    '${variationText.isNotEmpty ? ' • $variationText' : ''}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AdminColors.inkSecondary,
                                    ),
                                  ),
                                  trailing: Text(
                                    widget.controller.formatMoney(item.price * item.quantity),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AdminColors.ink,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Summary
                          Align(
                            alignment: Alignment.centerRight,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Column(
                                children: [
                                  if (record.order.discountAmount > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Giảm giá ${record.order.couponCode.isNotEmpty ? '(${record.order.couponCode})' : ''}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AdminColors.inkSecondary,
                                            ),
                                          ),
                                          Text(
                                            '- ${widget.controller.formatMoney(record.order.discountAmount)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AdminColors.emerald,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Tổng thanh toán',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        widget.controller.formatMoney(record.order.totalAmount),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: AdminColors.forest,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Obx(() {
      final all = widget.controller.orders.toList();
      final filtered = _filtered(all);

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Quản lý Đơn hàng',
                  subtitle:
                      'Xem chi tiết đơn, cập nhật trạng thái giao hàng và tự động gửi thông báo cho khách.',
                  actions: [
                    AdminSearchField(
                      hint: 'Tìm theo mã đơn, khách hàng, phương thức...',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Status Filter Pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusFilterChip(
                      label: 'Tất cả (${all.length})',
                      selected: _selectedStatus == null,
                      onTap: () => setState(() => _selectedStatus = null),
                    ),
                    for (final status in OrderStatus.values)
                      _StatusFilterChip(
                        label:
                            '${AdminOrderStatusMeta.of(status).label} (${widget.controller.countOrdersByStatus(status)})',
                        selected: _selectedStatus == status,
                        onTap: () => setState(() => _selectedStatus = status),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                AdminCard(
                  padding: const EdgeInsets.all(0),
                  child: filtered.isEmpty
                      ? const AdminEmptyState(
                          icon: Iconsax.shopping_bag,
                          title: 'Không có đơn hàng nào phù hợp',
                          subtitle: 'Thử thay đổi bộ lọc trạng thái hoặc từ khóa tìm kiếm.',
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 960),
                            child: DataTable(
                              headingRowColor:
                                  WidgetStateProperty.all(AdminColors.surfaceMuted),
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: 66,
                              columns: const [
                                DataColumn(label: Text('Mã đơn', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Khách hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Ngày đặt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                              ],
                              rows: filtered.map((record) {
                                final meta = AdminOrderStatusMeta.of(record.order.status);
                                final totalQty = record.order.items
                                    .fold<int>(0, (sum, i) => sum + i.quantity);
                                return DataRow(
                                  cells: [
                                    DataCell(Text(
                                      '#${record.order.id}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: AdminColors.forest,
                                      ),
                                    )),
                                    DataCell(Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          record.customerName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        if (record.customerEmail.isNotEmpty)
                                          Text(
                                            record.customerEmail,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AdminColors.inkMuted,
                                            ),
                                          ),
                                      ],
                                    )),
                                    DataCell(Text(
                                      '$totalQty sản phẩm',
                                      style: const TextStyle(fontSize: 12.5),
                                    )),
                                    DataCell(Text(
                                      DateFormat('dd/MM/yyyy').format(record.order.orderDate),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AdminColors.inkSecondary,
                                      ),
                                    )),
                                    DataCell(Text(
                                      record.order.paymentMethod,
                                      style: const TextStyle(fontSize: 12.5),
                                    )),
                                    DataCell(Text(
                                      widget.controller.formatMoney(record.order.totalAmount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    )),
                                    DataCell(AdminBadge(
                                      label: meta.label,
                                      color: meta.color,
                                      bgColor: meta.bgColor,
                                      icon: meta.icon,
                                    )),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Xem & cập nhật trạng thái',
                                          onPressed: () => _openOrderDetail(record),
                                          icon: const Icon(Iconsax.eye, size: 18, color: AdminColors.forest),
                                        ),
                                        IconButton(
                                          tooltip: 'Xóa đơn hàng',
                                          onPressed: () async {
                                            final ok = await showAdminConfirmDialog(
                                              context,
                                              title: 'Xóa đơn hàng #${record.order.id}?',
                                              message:
                                                  'Thao tác này sẽ xóa vĩnh viễn đơn hàng khỏi lịch sử của khách hàng.',
                                            );
                                            if (ok) {
                                              await widget.controller.deleteOrder(record);
                                            }
                                          },
                                          icon: const Icon(Iconsax.trash, size: 18, color: AdminColors.rose),
                                        ),
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

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AdminColors.forest : AdminColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AdminColors.forest : AdminColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AdminColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.title, required this.lines});

  final String title;
  final List<String> lines;

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AdminColors.inkMuted,
            ),
          ),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                line,
                style: const TextStyle(
                  fontSize: 13,
                  color: AdminColors.ink,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
