import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final width = MediaQuery.sizeOf(context).width;
      final isWide = width >= 1100;
      final series = controller.monthlyRevenueSeries;
      final recentOrders = controller.orders.take(6).toList();
      final lowStock = controller.lowStockProducts.take(6).toList();

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Xin chào, Quản trị viên',
                  subtitle:
                      'Theo dõi doanh thu, trạng thái đơn hàng, tồn kho và tương tác khách hàng theo thời gian thực.',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () => controller.selectSection(AdminSection.notifications),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.forest,
                        side: const BorderSide(color: AdminColors.borderStrong),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      ),
                      icon: const Icon(Iconsax.notification_bing, size: 17),
                      label: const Text('Gửi thông báo'),
                    ),
                    AdminPrimaryButton(
                      label: 'Quản lý sản phẩm',
                      icon: Iconsax.box,
                      onPressed: () => controller.selectSection(AdminSection.products),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // KPI Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 1100
                        ? 4
                        : constraints.maxWidth >= 650
                            ? 2
                            : 1;
                    final cardWidth =
                        (constraints.maxWidth - (cols - 1) * 16) / cols;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: AdminStatCard(
                            title: 'Doanh thu hoàn tất',
                            value: controller.formatMoney(controller.totalRevenueUsd),
                            subtitle:
                                'Đang xử lý: ${controller.formatMoney(controller.activePipelineUsd)}',
                            icon: Iconsax.wallet_money,
                            accentColor: AdminColors.emerald,
                            accentBg: AdminColors.emeraldBg,
                            onTap: () => controller.selectSection(AdminSection.orders),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: AdminStatCard(
                            title: 'Tổng đơn hàng',
                            value: '${controller.orders.length}',
                            subtitle:
                                '${controller.pendingOrdersCount} đơn chờ xác nhận / chuẩn bị',
                            icon: Iconsax.shopping_bag,
                            accentColor: AdminColors.sky,
                            accentBg: AdminColors.skyBg,
                            onTap: () => controller.selectSection(AdminSection.orders),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: AdminStatCard(
                            title: 'Sản phẩm & Kho',
                            value: '${controller.products.length}',
                            subtitle:
                                '${controller.brands.length} thương hiệu • ${controller.lowStockProducts.length} sắp hết hàng',
                            icon: Iconsax.box,
                            accentColor: AdminColors.forest,
                            accentBg: AdminColors.sageSoft,
                            onTap: () => controller.selectSection(AdminSection.products),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: AdminStatCard(
                            title: 'Khách hàng & Đánh giá',
                            value: '${controller.clientUsers.length}',
                            subtitle: controller.reviews.isEmpty
                                ? 'Chưa có đánh giá sản phẩm'
                                : 'TB ${controller.averageRating.toStringAsFixed(1)} ★ (${controller.reviews.length} đánh giá)',
                            icon: Iconsax.people,
                            accentColor: AdminColors.amber,
                            accentBg: AdminColors.amberBg,
                            onTap: () => controller.selectSection(AdminSection.users),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),

                // Charts row
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 13,
                        child: _RevenueChartCard(
                          series: series,
                          controller: controller,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 8,
                        child: _OrderStatusChartCard(controller: controller),
                      ),
                    ],
                  )
                else ...[
                  _RevenueChartCard(series: series, controller: controller),
                  const SizedBox(height: 18),
                  _OrderStatusChartCard(controller: controller),
                ],
                const SizedBox(height: 22),

                // Recent Orders + Low Stock
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 13,
                        child: _RecentOrdersCard(
                          orders: recentOrders,
                          controller: controller,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 8,
                        child: _LowStockCard(
                          products: lowStock,
                          controller: controller,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _RecentOrdersCard(orders: recentOrders, controller: controller),
                  const SizedBox(height: 18),
                  _LowStockCard(products: lowStock, controller: controller),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _RevenueChartCard extends StatelessWidget {
  const _RevenueChartCard({
    required this.series,
    required this.controller,
  });

  final List<({String label, double revenue, int orderCount})> series;
  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    final maxRevenue = series.fold<double>(0, (m, e) => e.revenue > m ? e.revenue : m);
    final maxY = maxRevenue <= 0 ? 100.0 : (maxRevenue * 1.25);

    return AdminCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doanh thu 6 tháng gần nhất',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.ink,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tính trên các đơn hàng chưa hủy (USD quy đổi tự động)',
                      style: TextStyle(fontSize: 12, color: AdminColors.inkMuted),
                    ),
                  ],
                ),
              ),
              AdminBadge(
                label: controller.showVnd.value ? 'VND' : 'USD',
                color: AdminColors.forest,
                bgColor: AdminColors.sageSoft,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AdminColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AdminColors.forestDark,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = series[group.x.toInt()];
                      return BarTooltipItem(
                        '${item.label}\n${controller.formatMoney(item.revenue)}\n${item.orderCount} đơn',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 54,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const Text('0', style: TextStyle(fontSize: 11, color: AdminColors.inkMuted));
                        }
                        return Text(
                          '\$${value.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, color: AdminColors.inkMuted),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= series.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            series[idx].label,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.inkSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(series.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: series[i].revenue,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [AdminColors.forest, AdminColors.forestLight],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusChartCard extends StatelessWidget {
  const _OrderStatusChartCard({required this.controller});

  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    final statuses = OrderStatus.values;
    final counts = {
      for (final s in statuses) s: controller.countOrdersByStatus(s),
    };
    final total = controller.orders.length;

    return AdminCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân bổ trạng thái đơn',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AdminColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Tổng cộng $total đơn hàng trên hệ thống',
            style: const TextStyle(fontSize: 12, color: AdminColors.inkMuted),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 168,
            child: total == 0
                ? const Center(
                    child: Text(
                      'Chưa có đơn hàng nào',
                      style: TextStyle(fontSize: 13, color: AdminColors.inkMuted),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      centerSpaceRadius: 42,
                      sectionsSpace: 3,
                      sections: [
                        for (final status in statuses)
                          if ((counts[status] ?? 0) > 0)
                            PieChartSectionData(
                              value: (counts[status] ?? 0).toDouble(),
                              color: AdminOrderStatusMeta.of(status).color,
                              radius: 34,
                              title: '${counts[status]}',
                              titleStyle: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          for (final status in statuses)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AdminOrderStatusMeta.of(status).color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AdminOrderStatusMeta.of(status).label,
                      style: const TextStyle(fontSize: 12.5, color: AdminColors.inkSecondary),
                    ),
                  ),
                  Text(
                    '${counts[status] ?? 0}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.ink,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  const _RecentOrdersCard({
    required this.orders,
    required this.controller,
  });

  final List<AdminOrderRecord> orders;
  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Đơn hàng gần đây',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => controller.selectSection(AdminSection.orders),
                child: const Text(
                  'Xem tất cả →',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.forest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Chưa có đơn hàng nào được tạo.',
                  style: TextStyle(color: AdminColors.inkMuted, fontSize: 13),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AdminColors.surfaceMuted),
                dataRowMinHeight: 52,
                dataRowMaxHeight: 58,
                columnSpacing: 22,
                columns: const [
                  DataColumn(label: Text('Mã đơn', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataColumn(label: Text('Khách hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataColumn(label: Text('Ngày đặt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataColumn(label: Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                ],
                rows: orders.map((record) {
                  final meta = AdminOrderStatusMeta.of(record.order.status);
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        '#${record.order.id}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                      )),
                      DataCell(Text(
                        record.customerName,
                        style: const TextStyle(fontSize: 12.5),
                      )),
                      DataCell(Text(
                        DateFormat('dd/MM/yyyy').format(record.order.orderDate),
                        style: const TextStyle(fontSize: 12.5, color: AdminColors.inkSecondary),
                      )),
                      DataCell(Text(
                        controller.formatMoney(record.order.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                      )),
                      DataCell(AdminBadge(
                        label: meta.label,
                        color: meta.color,
                        bgColor: meta.bgColor,
                        icon: meta.icon,
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({
    required this.products,
    required this.controller,
  });

  final List products;
  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cảnh báo tồn kho thấp',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => controller.selectSection(AdminSection.products),
                child: const Text(
                  'Kho hàng →',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.forest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Tất cả sản phẩm đều còn tồn kho tốt (> 10).',
                  style: TextStyle(color: AdminColors.emerald, fontSize: 13),
                ),
              ),
            )
          else
            Column(
              children: products.map((product) {
                final isOut = product.stock <= 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      AdminImageThumb(url: product.thumbnail, width: 44, height: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.ink,
                              ),
                            ),
                            Text(
                              product.brand?.name ?? product.categoryName,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AdminColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AdminBadge(
                        label: isOut ? 'Hết hàng' : 'Còn ${product.stock}',
                        color: isOut ? AdminColors.rose : AdminColors.amber,
                        bgColor: isOut ? AdminColors.roseBg : AdminColors.amberBg,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
