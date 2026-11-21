import 'dart:math' as math;

import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class AdminFinanceView extends StatelessWidget {
  const AdminFinanceView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1100;

    return Obx(() {
      final netRevenue = controller.financeNetRevenueUsd;
      final grossRevenue = controller.financeGrossRevenueUsd;
      final discounts = controller.financeTotalDiscountUsd;
      final tax = controller.financeTotalTaxUsd;
      final cogs = controller.financeTotalCogsUsd;
      final netProfit = controller.financeNetProfitUsd;
      final margin = controller.financeProfitMarginPercent;
      final isLoss = netProfit < 0;
      final cancelledUsd = controller.cancelledOrdersUsd;
      final series = controller.financeChartSeries;
      final breakdowns = controller.financeBreakdowns;

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Doanh thu, Lãi / Lỗ & Thuế',
                  subtitle:
                      'Phân tích chi tiết doanh thu thuần, giá vốn hàng bán (COGS), thuế GTGT, giảm giá voucher và biên lợi nhuận thực tế.',
                  actions: [
                    SegmentedButton<FinancePeriod>(
                      segments: const [
                        ButtonSegment(
                          value: FinancePeriod.last7Days,
                          label: Text('7 ngày', style: TextStyle(fontSize: 12)),
                        ),
                        ButtonSegment(
                          value: FinancePeriod.last6Months,
                          label: Text('6 tháng', style: TextStyle(fontSize: 12)),
                        ),
                        ButtonSegment(
                          value: FinancePeriod.last12Months,
                          label: Text('12 tháng', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      selected: {controller.financePeriod.value},
                      onSelectionChanged: (set) =>
                          controller.financePeriod.value = set.first,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Accounting parameters bar (COGS %, VAT %, Completed-only toggle)
                AdminCard(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Order scope
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: controller.onlyCompletedForFinance.value,
                            activeColor: AdminColors.forest,
                            onChanged: (v) =>
                                controller.onlyCompletedForFinance.value = v,
                          ),
                          Text(
                            controller.onlyCompletedForFinance.value
                                ? 'Chỉ tính đơn Đã nhận (${breakdowns.length})'
                                : 'Tính mọi đơn chưa hủy (${breakdowns.length})',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),

                      // VAT rate selector
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Thuế suất:',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.inkSecondary),
                          ),
                          const SizedBox(width: 8),
                          for (final vat in [0.0, 5.0, 8.0, 10.0])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(
                                  vat == 0 ? 'Cố định (\$2/đơn)' : 'VAT ${vat.toInt()}%',
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                                selected: controller.vatRatePercent.value == vat,
                                selectedColor: AdminColors.sageSoft,
                                onSelected: (_) =>
                                    controller.vatRatePercent.value = vat,
                              ),
                            ),
                        ],
                      ),

                      // COGS % slider
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tỷ lệ Giá vốn (COGS): ${controller.cogsRatePercent.value.toInt()}%',
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.inkSecondary),
                          ),
                          SizedBox(
                            width: 170,
                            child: Slider(
                              value: controller.cogsRatePercent.value,
                              min: 30,
                              max: 95,
                              divisions: 13,
                              activeColor: AdminColors.forest,
                              label: '${controller.cogsRatePercent.value.toInt()}%',
                              onChanged: (v) =>
                                  controller.cogsRatePercent.value = v,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4 Main Financial KPIs
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
                            title: 'Doanh thu thuần',
                            value: controller.formatMoney(netRevenue),
                            subtitle:
                                'Tiền hàng: ${controller.formatMoney(grossRevenue)} • Giảm: -${controller.formatMoney(discounts)}',
                            icon: Iconsax.money_recive,
                            accentColor: AdminColors.forest,
                            accentBg: AdminColors.sageSoft,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: AdminStatCard(
                            title: isLoss ? 'Lỗ ròng (Net Loss)' : 'Lãi ròng (Net Profit)',
                            value:
                                '${isLoss ? '-' : '+'}${controller.formatMoney(netProfit.abs())}',
                            subtitle:
                                'Biên lợi nhuận: ${margin.toStringAsFixed(1)}% • ${isLoss ? 'Đang lỗ' : 'Có lãi'}',
                            icon: isLoss ? Iconsax.trend_down : Iconsax.trend_up,
                            accentColor:
                                isLoss ? AdminColors.rose : AdminColors.emerald,
                            accentBg:
                                isLoss ? AdminColors.roseBg : AdminColors.emeraldBg,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: AdminStatCard(
                            title: controller.vatRatePercent.value > 0
                                ? 'Thuế GTGT (${controller.vatRatePercent.value.toInt()}%)'
                                : 'Thuế đơn hàng',
                            value: controller.formatMoney(tax),
                            subtitle:
                                'Giá vốn (${controller.cogsRatePercent.value.toInt()}%): ${controller.formatMoney(cogs)}',
                            icon: Iconsax.receipt_item,
                            accentColor: AdminColors.amber,
                            accentBg: AdminColors.amberBg,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: AdminStatCard(
                            title: 'Đơn hủy / Thất thoát',
                            value: controller.formatMoney(cancelledUsd),
                            subtitle:
                                '${controller.countOrdersByStatus(OrderStatus.cancelled)} đơn bị hủy • Ship thu: ${controller.formatMoney(controller.financeTotalShippingUsd)}',
                            icon: Iconsax.close_circle,
                            accentColor: AdminColors.rose,
                            accentBg: AdminColors.roseBg,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),

                // Charts Row 1: Grouped Bar Chart (Revenue vs Cost+Tax vs Profit) + Cost Structure Donut
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 13,
                        child: _GroupedFinanceBarChart(
                          series: series,
                          controller: controller,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 8,
                        child: _FinancialStructureCard(
                          netProfit: netProfit,
                          cogs: cogs,
                          tax: tax,
                          discounts: discounts,
                          controller: controller,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _GroupedFinanceBarChart(series: series, controller: controller),
                  const SizedBox(height: 18),
                  _FinancialStructureCard(
                    netProfit: netProfit,
                    cogs: cogs,
                    tax: tax,
                    discounts: discounts,
                    controller: controller,
                  ),
                ],
                const SizedBox(height: 22),

                // Profit / Loss Line Chart
                _ProfitTrendLineChart(series: series, controller: controller),
                const SizedBox(height: 22),

                // Per-Order Financial Ledger Table
                AdminCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sổ chi tiết Doanh thu, Thuế & Lãi/Lỗ từng đơn (${breakdowns.length})',
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: AdminColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Công thức: Lãi/Lỗ = (Tiền hàng − Giảm giá) − Giá vốn (COGS) − Thuế',
                                    style: TextStyle(
                                        fontSize: 12, color: AdminColors.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (breakdowns.isEmpty)
                        const AdminEmptyState(
                          icon: Iconsax.chart_2,
                          title: 'Chưa có đơn hàng phát sinh doanh thu',
                          subtitle:
                              'Khi khách hàng đặt đơn, dữ liệu doanh thu, thuế và lãi/lỗ sẽ tự động hiển thị tại đây.',
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 1020),
                            child: DataTable(
                              headingRowColor:
                                  WidgetStateProperty.all(AdminColors.surfaceMuted),
                              dataRowMinHeight: 56,
                              dataRowMaxHeight: 64,
                              columns: const [
                                DataColumn(label: Text('Sản phẩm / Đơn', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Ngày đặt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Tiền hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Giảm giá', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Giá vốn', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Thuế', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Lãi / Lỗ ròng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                              ],
                              rows: breakdowns.map((b) {
                                final meta =
                                    AdminOrderStatusMeta.of(b.record.order.status);
                                return DataRow(
                                  cells: [
                                    DataCell(SizedBox(
                                      width: 210,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            b.record.order.itemsSummary(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          Text(
                                            b.record.customerName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AdminColors.inkMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                    DataCell(Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(b.record.order.orderDate),
                                      style: const TextStyle(fontSize: 12),
                                    )),
                                    DataCell(AdminBadge(
                                      label: meta.label,
                                      color: meta.color,
                                      bgColor: meta.bgColor,
                                    )),
                                    DataCell(Text(
                                      controller.formatMoney(b.grossSubtotal),
                                      style: const TextStyle(fontSize: 12.5),
                                    )),
                                    DataCell(Text(
                                      b.discount > 0
                                          ? '-${controller.formatMoney(b.discount)}'
                                          : '—',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: b.discount > 0
                                            ? AdminColors.amber
                                            : AdminColors.inkMuted,
                                      ),
                                    )),
                                    DataCell(Text(
                                      controller.formatMoney(b.cogs),
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AdminColors.inkSecondary),
                                    )),
                                    DataCell(Text(
                                      controller.formatMoney(b.tax),
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AdminColors.amber),
                                    )),
                                    DataCell(AdminBadge(
                                      label:
                                          '${b.isLoss ? '-' : '+'}${controller.formatMoney(b.netProfit.abs())}',
                                      color: b.isLoss
                                          ? AdminColors.rose
                                          : AdminColors.emerald,
                                      bgColor: b.isLoss
                                          ? AdminColors.roseBg
                                          : AdminColors.emeraldBg,
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
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

class _GroupedFinanceBarChart extends StatelessWidget {
  const _GroupedFinanceBarChart({
    required this.series,
    required this.controller,
  });

  final List<FinancePeriodPoint> series;
  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    final maxVal = series.fold<double>(
      0,
      (m, e) => math.max(m, math.max(e.revenue, math.max(e.costAndTax, e.profit.abs()))),
    );
    final maxY = maxVal <= 0 ? 100.0 : maxVal * 1.25;

    return AdminCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biểu đồ Doanh thu • Giá vốn & Thuế • Lãi/Lỗ',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.ink,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Di chuột vào từng cột để xem chi tiết số tiền theo kỳ',
                    style: TextStyle(fontSize: 12, color: AdminColors.inkMuted),
                  ),
                ],
              ),
              Wrap(
                spacing: 14,
                children: [
                  _LegendDot(color: AdminColors.forest, label: 'Doanh thu'),
                  _LegendDot(color: AdminColors.amber, label: 'Giá vốn + Thuế'),
                  _LegendDot(color: AdminColors.emerald, label: 'Lãi'),
                  _LegendDot(color: AdminColors.rose, label: 'Lỗ'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AdminColors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AdminColors.forestDark,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final p = series[group.x.toInt()];
                      return BarTooltipItem(
                        '${p.label} (${p.orderCount} đơn)\n'
                        'Doanh thu: ${controller.formatMoney(p.revenue)}\n'
                        'Thuế: ${controller.formatMoney(p.tax)}\n'
                        '${p.profit < 0 ? 'Lỗ' : 'Lãi'}: ${controller.formatMoney(p.profit.abs())}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
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
                      reservedSize: 56,
                      getTitlesWidget: (value, meta) => Text(
                        value == 0 ? '0' : '\$${value.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11, color: AdminColors.inkMuted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= series.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            series[idx].label,
                            style: const TextStyle(
                              fontSize: 11,
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
                  final p = series[i];
                  final rodWidth = series.length > 8 ? 7.0 : 12.0;
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: p.revenue,
                        width: rodWidth,
                        color: AdminColors.forest,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: p.costAndTax,
                        width: rodWidth,
                        color: AdminColors.amber,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: p.profit.abs(),
                        width: rodWidth,
                        color: p.profit < 0 ? AdminColors.rose : AdminColors.emerald,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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

class _FinancialStructureCard extends StatelessWidget {
  const _FinancialStructureCard({
    required this.netProfit,
    required this.cogs,
    required this.tax,
    required this.discounts,
    required this.controller,
  });

  final double netProfit;
  final double cogs;
  final double tax;
  final double discounts;
  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    final profitSlice = math.max(0.0, netProfit);
    final total = profitSlice + cogs + tax + discounts;

    final entries = [
      ('Lãi ròng', profitSlice, AdminColors.emerald),
      ('Giá vốn hàng bán', cogs, AdminColors.forestLight),
      ('Thuế phải nộp', tax, AdminColors.amber),
      ('Giảm giá Voucher', discounts, AdminColors.violet),
    ];

    return AdminCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cơ cấu dòng tiền & Thuế',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AdminColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Tỷ trọng giá vốn, thuế, khuyến mãi và lợi nhuận',
            style: TextStyle(fontSize: 12, color: AdminColors.inkMuted),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: total <= 0
                ? const Center(
                    child: Text(
                      'Chưa có dữ liệu tài chính',
                      style: TextStyle(fontSize: 13, color: AdminColors.inkMuted),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      centerSpaceRadius: 42,
                      sectionsSpace: 3,
                      sections: [
                        for (final item in entries)
                          if (item.$2 > 0)
                            PieChartSectionData(
                              value: item.$2,
                              color: item.$3,
                              radius: 36,
                              title: '${((item.$2 / total) * 100).round()}%',
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          for (final item in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                          fontSize: 12.5, color: AdminColors.inkSecondary),
                    ),
                  ),
                  Text(
                    controller.formatMoney(item.$2),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          if (netProfit < 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AdminBadge(
                label: 'Cảnh báo lỗ ròng: -${controller.formatMoney(netProfit.abs())}',
                color: AdminColors.rose,
                bgColor: AdminColors.roseBg,
                icon: Iconsax.warning_2,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfitTrendLineChart extends StatelessWidget {
  const _ProfitTrendLineChart({
    required this.series,
    required this.controller,
  });

  final List<FinancePeriodPoint> series;
  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    final values = series.map((e) => e.profit).toList();
    final minVal = values.fold<double>(0, math.min);
    final maxVal = values.fold<double>(0, math.max);
    final pad = math.max(20.0, (maxVal - minVal) * 0.25);
    final minY = minVal < 0 ? minVal - pad : 0.0;
    final maxY = maxVal <= 0 ? 50.0 : maxVal + pad;

    return AdminCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xu hướng Lãi / Lỗ ròng theo thời gian',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AdminColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Đường xu hướng lợi nhuận sau khi trừ giá vốn hàng bán và thuế',
            style: TextStyle(fontSize: 12, color: AdminColors.inkMuted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: v == 0 ? AdminColors.borderStrong : AdminColors.border,
                    strokeWidth: v == 0 ? 1.5 : 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AdminColors.forestDark,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final p = series[spot.x.toInt()];
                      return LineTooltipItem(
                        '${p.label}\n${p.profit < 0 ? 'Lỗ' : 'Lãi'}: ${controller.formatMoney(p.profit.abs())}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      getTitlesWidget: (v, _) => Text(
                        '\$${v.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11, color: AdminColors.inkMuted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= series.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            series[idx].label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.inkSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    preventCurveOverShooting: true,
                    barWidth: 3,
                    color: AdminColors.emerald,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AdminColors.emerald.withValues(alpha: 0.12),
                    ),
                    spots: List.generate(
                      series.length,
                      (i) => FlSpot(i.toDouble(), series[i].profit),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AdminColors.inkSecondary),
        ),
      ],
    );
  }
}
