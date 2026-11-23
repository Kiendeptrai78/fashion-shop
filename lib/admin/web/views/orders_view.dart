import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/admin/web/widgets/admin_product_video_preview_dialog.dart';
import 'package:fashion_business_app/features/shop/models/shipping_route_helper.dart';
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

  OrderStatus? _nextLogicalStatus(OrderStatus status) => switch (status) {
        OrderStatus.pending => OrderStatus.processing,
        OrderStatus.processing => OrderStatus.shipped,
        OrderStatus.shipped => OrderStatus.received,
        _ => null,
      };

  String _nextStepActionLabel(OrderStatus status) => switch (status) {
        OrderStatus.pending => 'Xác nhận & Đóng gói',
        OrderStatus.processing => 'Bàn giao Vận chuyển',
        OrderStatus.shipped => 'Xác nhận Giao thành công',
        _ => '',
      };

  Future<void> _openOrderDetail(AdminOrderRecord record) async {
    OrderStatus currentStatus = record.order.status;
    DateTime deliveryDate = record.order.deliveryDate;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final meta = AdminOrderStatusMeta.of(currentStatus);
          final nextStep = _nextLogicalStatus(currentStatus);
          final stepIdx = switch (currentStatus) {
            OrderStatus.pending => 1,
            OrderStatus.processing => 2,
            OrderStatus.shipped => 3,
            OrderStatus.received => 4,
            OrderStatus.cancelled => 0,
          };

          Future<void> applyStatus(OrderStatus next) async {
            if (next == currentStatus) return;
            setModalState(() => saving = true);
            await widget.controller.updateOrderStatus(record, next);
            setModalState(() {
              currentStatus = next;
              saving = false;
            });
          }

          return Dialog(
            backgroundColor: AdminColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780, maxHeight: 820),
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
                                  Flexible(
                                    child: Text(
                                      'Đơn hàng ${record.order.itemsSummary()}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AdminColors.ink,
                                      ),
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
                                'Khách: ${record.customerName} • Đặt ngày ${DateFormat('dd/MM/yyyy HH:mm').format(record.order.orderDate)} • ${record.order.paymentMethod}',
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
                          // 4-step Visual Order Pipeline Stepper + Next-Step Action Bar
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AdminColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AdminColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (currentStatus != OrderStatus.cancelled) ...[
                                  Row(
                                    children: List.generate(4, (i) {
                                      const steps = [
                                        ('1. Chờ xác nhận', Iconsax.clock, AdminColors.amber, AdminColors.amberBg),
                                        ('2. Đang đóng gói', Iconsax.box_time, AdminColors.violet, AdminColors.violetBg),
                                        ('3. Đang vận chuyển', Iconsax.truck_fast, AdminColors.sky, AdminColors.skyBg),
                                        ('4. Giao thành công', Iconsax.tick_circle, AdminColors.emerald, AdminColors.emeraldBg),
                                      ];
                                      final active = (i + 1) <= stepIdx;
                                      final current = (i + 1) == stepIdx;
                                      final sColor = steps[i].$3;
                                      final sBg = steps[i].$4;
                                      return Expanded(
                                        child: Container(
                                          margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: current
                                                ? sColor
                                                : (active ? sBg : Colors.white),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: active
                                                  ? sColor
                                                  : AdminColors.border,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                steps[i].$2,
                                                size: 15,
                                                color: current
                                                    ? Colors.white
                                                    : (active
                                                        ? sColor
                                                        : AdminColors.inkMuted),
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  steps[i].$1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: current
                                                        ? Colors.white
                                                        : (active
                                                            ? sColor
                                                            : AdminColors.inkMuted),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (nextStep != null)
                                      AdminPrimaryButton(
                                        label: 'Bước tiếp theo: ${_nextStepActionLabel(currentStatus)} →',
                                        icon: Iconsax.arrow_right_3,
                                        loading: saving,
                                        onPressed: () => applyStatus(nextStep),
                                      ),
                                    if (currentStatus == OrderStatus.pending ||
                                        currentStatus == OrderStatus.processing)
                                      OutlinedButton.icon(
                                        onPressed: saving
                                            ? null
                                            : () => applyStatus(OrderStatus.cancelled),
                                        icon: const Icon(
                                          Iconsax.close_circle,
                                          size: 16,
                                          color: AdminColors.rose,
                                        ),
                                        label: const Text(
                                          'Hủy đơn hàng',
                                          style: TextStyle(color: AdminColors.rose),
                                        ),
                                      ),
                                    SizedBox(
                                      width: 220,
                                      child: DropdownButtonFormField<OrderStatus>(
                                        value: currentStatus,
                                        decoration: adminInputDecoration(
                                          label: 'Chuyển trạng thái bất kỳ',
                                        ),
                                        items: OrderStatus.values.map((status) {
                                          final sm = AdminOrderStatusMeta.of(status);
                                          return DropdownMenuItem(
                                            value: status,
                                            child: Text(
                                              sm.label,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: sm.color,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: saving
                                            ? null
                                            : (next) {
                                                if (next != null) applyStatus(next);
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
                                            horizontal: 14, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(11),
                                        ),
                                      ),
                                      icon: const Icon(Iconsax.calendar, size: 17),
                                      label: Text(
                                        'Giao dự kiến: ${DateFormat('dd/MM/yyyy').format(deliveryDate)}',
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Live Route Map from Hanoi Warehouse + Auto ETA Estimator
                          VeloraOrderTrackingMap(
                            status: currentStatus,
                            address: record.order.address,
                            orderDate: record.order.orderDate,
                            deliveryDate: deliveryDate,
                            onAutoSetDeliveryDate: (autoDate) async {
                              setModalState(() => saving = true);
                              await widget.controller
                                  .updateOrderDeliveryDate(record, autoDate);
                              setModalState(() {
                                deliveryDate = autoDate;
                                saving = false;
                              });
                            },
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
                                final liveProduct = widget.controller.products
                                    .firstWhereOrNull((p) => p.id == item.productId);
                                final discontinued = liveProduct == null ||
                                    liveProduct.isDiscontinued;
                                return Opacity(
                                  opacity: discontinued ? 0.58 : 1.0,
                                  child: ListTile(
                                    onTap: liveProduct == null
                                        ? null
                                        : () => showAdminProductAndVideoPreviewDialog(
                                              context,
                                              controller: widget.controller,
                                              product: liveProduct,
                                            ),
                                    leading: AdminImageThumb(
                                      url: item.image ?? '',
                                      width: 48,
                                      height: 48,
                                    ),
                                    title: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              decoration: discontinued
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        if (discontinued) ...[
                                          const SizedBox(width: 8),
                                          const AdminBadge(
                                            label: '🚫 Đã ngừng bán',
                                            color: AdminColors.rose,
                                            bgColor: AdminColors.roseBg,
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(
                                      'SL: ${item.quantity} × ${widget.controller.formatMoney(item.price)}'
                                      '${variationText.isNotEmpty ? ' • $variationText' : ''}'
                                      '${liveProduct != null ? ' • Ấn xem chi tiết giày' : ''}',
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
                        accentColor: AdminOrderStatusMeta.of(status).color,
                        accentBg: AdminOrderStatusMeta.of(status).bgColor,
                        icon: AdminOrderStatusMeta.of(status).icon,
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
                      : Column(
                          children: [
                            // Responsive Full-Width Header (No horizontal clipping!)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 13,
                              ),
                              decoration: const BoxDecoration(
                                color: AdminColors.surfaceMuted,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                border: Border(
                                  bottom: BorderSide(color: AdminColors.border),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 25,
                                    child: Text(
                                      'Đơn hàng & Sản phẩm',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AdminColors.inkSecondary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    flex: 18,
                                    child: Text(
                                      'Khách hàng',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AdminColors.inkSecondary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    flex: 20,
                                    child: Text(
                                      'Tuyến Kho Hà Nội & Ngày giao',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AdminColors.inkSecondary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    flex: 14,
                                    child: Text(
                                      'Tổng tiền & TT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AdminColors.inkSecondary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    flex: 15,
                                    child: Text(
                                      'Trạng thái',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AdminColors.inkSecondary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    flex: 24,
                                    child: Text(
                                      'Thao tác nhanh',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AdminColors.inkSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: AdminColors.border,
                              ),
                              itemBuilder: (context, idx) {
                                final record = filtered[idx];
                                final meta = AdminOrderStatusMeta.of(
                                    record.order.status);
                                final nextStep =
                                    _nextLogicalStatus(record.order.status);
                                final totalQty = record.order.items.fold<int>(
                                    0, (sum, i) => sum + i.quantity);
                                final eta =
                                    ShippingRouteHelper.estimateForAddress(
                                        record.order.address);
                                final thumb = record.order.items.isNotEmpty
                                    ? (record.order.items.first.image ?? '')
                                    : '';

                                return InkWell(
                                  onTap: () => _openOrderDetail(record),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        // 1. Product & Order Summary
                                        Expanded(
                                          flex: 25,
                                          child: Row(
                                            children: [
                                              AdminImageThumb(
                                                url: thumb,
                                                width: 42,
                                                height: 42,
                                                fit: BoxFit.contain,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      record.order
                                                          .itemsSummary(),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 12.5,
                                                        color:
                                                            AdminColors.forest,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '$totalQty đôi • Đặt ${DateFormat('dd/MM/yyyy').format(record.order.orderDate)}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AdminColors
                                                            .inkMuted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // 2. Customer
                                        Expanded(
                                          flex: 18,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                record.customerName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                              if (record
                                                  .customerEmail.isNotEmpty)
                                                Text(
                                                  record.customerEmail,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AdminColors.inkMuted,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // 3. Route & Automatic ETA from Hanoi Warehouse
                                        Expanded(
                                          flex: 20,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Iconsax.routing,
                                                    size: 13,
                                                    color: AdminColors.sky,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'Kho HN → ${eta.destinationCity}',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AdminColors.ink,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Ước tính ${eta.minDays}–${eta.maxDays} ngày (~${eta.distanceKm} km)',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AdminColors.sky,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // 4. Total & Payment
                                        Expanded(
                                          flex: 14,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.controller.formatMoney(
                                                    record.order.totalAmount),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                              Text(
                                                record.order.paymentMethod,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AdminColors.inkSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // 5. Distinct Multi-Color Status Badge
                                        Expanded(
                                          flex: 15,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: AdminBadge(
                                              label: meta.label,
                                              color: meta.color,
                                              bgColor: meta.bgColor,
                                              icon: meta.icon,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // 6. Quick Actions (Always 100% visible on right)
                                        Expanded(
                                          flex: 24,
                                          child: Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            alignment: WrapAlignment.end,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              if (nextStep != null)
                                                FilledButton.tonalIcon(
                                                  onPressed: () => widget
                                                      .controller
                                                      .updateOrderStatus(
                                                          record, nextStep),
                                                  icon: const Icon(
                                                    Iconsax.arrow_right_3,
                                                    size: 13,
                                                  ),
                                                  label: Text(
                                                    _nextStepActionLabel(
                                                        record.order.status),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        AdminOrderStatusMeta.of(
                                                                nextStep)
                                                            .bgColor,
                                                    foregroundColor:
                                                        AdminOrderStatusMeta.of(
                                                                nextStep)
                                                            .color,
                                                    side: BorderSide(
                                                      color:
                                                          AdminOrderStatusMeta
                                                                  .of(nextStep)
                                                              .color
                                                              .withValues(
                                                                  alpha: 0.35),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 9,
                                                      vertical: 5,
                                                    ),
                                                    minimumSize:
                                                        const Size(0, 30),
                                                  ),
                                                ),
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                tooltip:
                                                    'Xem bản đồ hành trình & chi tiết đơn',
                                                onPressed: () =>
                                                    _openOrderDetail(record),
                                                icon: const Icon(
                                                  Iconsax.eye,
                                                  size: 17,
                                                  color: AdminColors.forest,
                                                ),
                                              ),
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                tooltip: 'Xóa đơn hàng',
                                                onPressed: () async {
                                                  final ok =
                                                      await showAdminConfirmDialog(
                                                    context,
                                                    title:
                                                        'Xóa đơn hàng ${record.order.itemsSummary()}?',
                                                    message:
                                                        'Thao tác này sẽ xóa vĩnh viễn đơn hàng khỏi lịch sử của khách hàng.',
                                                  );
                                                  if (ok) {
                                                    await widget.controller
                                                        .deleteOrder(record);
                                                  }
                                                },
                                                icon: const Icon(
                                                  Iconsax.trash,
                                                  size: 17,
                                                  color: AdminColors.rose,
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
                            ),
                          ],
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
    this.accentColor,
    this.accentBg,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accentColor;
  final Color? accentBg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final activeTone = accentColor ?? const Color(0xFF334155);
    final idleBg = accentBg ?? AdminColors.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? activeTone : idleBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? activeTone
                : (accentColor != null
                    ? activeTone.withValues(alpha: 0.35)
                    : AdminColors.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : activeTone,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (accentColor ?? AdminColors.inkSecondary),
              ),
            ),
          ],
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
