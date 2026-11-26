import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

Future<DateTime?> _showMonthPickerDialog(
  BuildContext context, {
  required AdminWebController controller,
  required DateTime initialMonth,
  required String title,
}) async {
  var selectedYear = initialMonth.year;
  final now = DateTime.now();

  return showDialog<DateTime>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setModalState) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Year selector bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            setModalState(() => selectedYear -= 1),
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      ),
                      Text(
                        'Năm $selectedYear',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: selectedYear >= now.year + 1
                            ? null
                            : () => setModalState(() => selectedYear += 1),
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 58,
                  ),
                  itemBuilder: (_, idx) {
                    final m = idx + 1;
                    final isPicked = initialMonth.year == selectedYear &&
                        initialMonth.month == m;
                    final ordCount =
                        controller.countOrdersInMonth(selectedYear, m);
                    final rev = controller.revenueInMonthUsd(selectedYear, m);

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.of(dialogCtx)
                          .pop(DateTime(selectedYear, m, 1)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isPicked
                              ? const Color(0xFF111827)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isPicked
                                ? const Color(0xFF111827)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tháng $m',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isPicked
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ordCount > 0
                                  ? '$ordCount đơn · ${controller.formatCompactMoney(rev)}'
                                  : '0 đơn',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isPicked
                                    ? Colors.white70
                                    : (ordCount > 0
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFF94A3B8)),
                                fontWeight: ordCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
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
        ),
      ),
    ),
  );
}

class AdminPeriodFilterBar extends StatelessWidget {
  const AdminPeriodFilterBar({
    super.key,
    required this.controller,
    this.trailingAction,
  });

  final AdminWebController controller;
  final Widget? trailingAction;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = controller.customSelectedDate.value ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Chọn ngày xem doanh thu',
    );
    if (picked != null) {
      controller.customSelectedDate.value = picked;
      controller.selectedTimeFilter.value = AdminTimeFilter.customDate;
    }
  }

  Future<void> _pickMonth(BuildContext context) async {
    final now = DateTime.now();
    final initial = controller.customSelectedMonth.value ??
        DateTime(now.year, now.month, 1);
    final picked = await _showMonthPickerDialog(
      context,
      controller: controller,
      initialMonth: initial,
      title: 'Chọn tháng xem doanh thu',
    );
    if (picked != null) {
      controller.customSelectedMonth.value = picked;
      controller.selectedTimeFilter.value = AdminTimeFilter.customMonth;
    }
  }

  Future<void> _openCompareMenu(BuildContext context) async {
    final now = DateTime.now();
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'So sánh với kỳ khác',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Iconsax.autobrightness, size: 18),
                  title: const Text(
                    'Tự động so với kỳ liền trước',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    controller.compareCustomMonth.value = null;
                    controller.compareCustomDate.value = null;
                    Navigator.of(dialogCtx).pop();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Iconsax.calendar, size: 18),
                  title: const Text(
                    'Chọn một tháng bất kỳ để đối chiếu',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.of(dialogCtx).pop();
                    final m = await _showMonthPickerDialog(
                      context,
                      controller: controller,
                      initialMonth: controller.compareCustomMonth.value ??
                          DateTime(now.year, now.month - 1, 1),
                      title: 'Chọn tháng dùng để so sánh',
                    );
                    if (m != null) {
                      controller.compareCustomDate.value = null;
                      controller.compareCustomMonth.value = m;
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Iconsax.calendar_1, size: 18),
                  title: const Text(
                    'Chọn một ngày cụ thể để đối chiếu',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.of(dialogCtx).pop();
                    final d = await showDatePicker(
                      context: context,
                      initialDate: controller.compareCustomDate.value ??
                          now.subtract(const Duration(days: 1)),
                      firstDate: DateTime(2024, 1, 1),
                      lastDate: DateTime(now.year + 1, 12, 31),
                      helpText: 'Chọn ngày dùng để so sánh',
                    );
                    if (d != null) {
                      controller.compareCustomMonth.value = null;
                      controller.compareCustomDate.value = d;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.selectedTimeFilter.value;
      final customDate = controller.customSelectedDate.value;
      final customMonth = controller.customSelectedMonth.value;
      final cmpMonth = controller.compareCustomMonth.value;
      final cmpDate = controller.compareCustomDate.value;

      final tabs = <(AdminTimeFilter, String)>[
        (
          AdminTimeFilter.today,
          'Hôm nay (${controller.countOrdersForFilter(AdminTimeFilter.today)})'
        ),
        (
          AdminTimeFilter.yesterday,
          'Hôm qua (${controller.countOrdersForFilter(AdminTimeFilter.yesterday)})'
        ),
        (
          AdminTimeFilter.last7Days,
          '7 ngày (${controller.countOrdersForFilter(AdminTimeFilter.last7Days)})'
        ),
        (
          AdminTimeFilter.thisMonth,
          'Tháng này (${controller.countOrdersForFilter(AdminTimeFilter.thisMonth)})'
        ),
        (
          AdminTimeFilter.allTime,
          'Tất cả (${controller.orders.length})'
        ),
      ];

      final isCustomDate =
          active == AdminTimeFilter.customDate && customDate != null;
      final isCustomMonth =
          active == AdminTimeFilter.customMonth && customMonth != null;
      final hasManualCompare = cmpMonth != null || cmpDate != null;
      final compareBtnLabel = cmpMonth != null
          ? 'vs T${cmpMonth.month}/${cmpMonth.year}'
          : (cmpDate != null
              ? 'vs ${DateFormat('dd/MM').format(cmpDate)}'
              : 'So sánh');

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tab in tabs)
                    _UnderlinePeriodTab(
                      label: tab.$2,
                      selected: active == tab.$1,
                      onTap: () => controller.selectedTimeFilter.value = tab.$1,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _CompactPickerButton(
                    icon: Iconsax.calendar,
                    label: isCustomMonth
                        ? 'Tháng ${customMonth.month}/${customMonth.year}'
                        : 'Chọn tháng',
                    active: isCustomMonth,
                    onTap: () => _pickMonth(context),
                  ),
                  _CompactPickerButton(
                    icon: Iconsax.calendar_1,
                    label: isCustomDate
                        ? DateFormat('dd/MM/yyyy').format(customDate)
                        : 'Chọn ngày',
                    active: isCustomDate,
                    onTap: () => _pickDate(context),
                  ),
                  _CompactPickerButton(
                    icon: Iconsax.arrow_swap_horizontal,
                    label: compareBtnLabel,
                    active: hasManualCompare,
                    onTap: () => _openCompareMenu(context),
                  ),
                  if (trailingAction != null) trailingAction!,
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CompactPickerButton extends StatelessWidget {
  const _CompactPickerButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? const Color(0xFFF8FAFC) : Colors.white,
        foregroundColor: const Color(0xFF111827),
        side: BorderSide(
          color: active ? const Color(0xFF111827) : const Color(0xFFD1D5DB),
          width: active ? 1.3 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _UnderlinePeriodTab extends StatelessWidget {
  const _UnderlinePeriodTab({
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
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF111827) : Colors.transparent,
              width: 2.2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF111827) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  bool _showCostConfig = false;

  AdminWebController get c => widget.controller;

  String _deltaText(double current, double prev, String prevLabel) {
    if (prev <= 0 && current <= 0) return 'So với $prevLabel: 0 ₫';
    if (prev <= 0) return '+100% vs $prevLabel (0 ₫)';
    final pct = ((current - prev) / prev) * 100.0;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}% vs $prevLabel (${c.formatCompactMoney(prev)})';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final width = MediaQuery.sizeOf(context).width;
      final isWide = width >= 1080;

      final periodTitle = c.selectedPeriodTitle;
      final breakdowns = c.periodFinanceBreakdowns;
      final soldProducts = c.soldProductsForRecords(c.financeFilteredOrders);

      final collectedUsd =
          breakdowns.fold<double>(0.0, (s, b) => s + b.netRevenue);
      final cogsUsd = breakdowns.fold<double>(0.0, (s, b) => s + b.cogs);
      final taxUsd = breakdowns.fold<double>(0.0, (s, b) => s + b.tax);
      final netProfitUsd =
          breakdowns.fold<double>(0.0, (s, b) => s + b.netProfit);
      final margin =
          collectedUsd <= 0 ? 0.0 : (netProfitUsd / collectedUsd) * 100.0;
      final isLoss = netProfitUsd < 0;

      final vnpayUsd = c.financeFilteredOrders
          .where((r) => r.order.paymentMethod.toLowerCase().contains('vnpay'))
          .fold<double>(0.0, (s, r) => s + r.order.totalAmount);
      final codUsd = c.financeFilteredOrders
          .where((r) => !r.order.paymentMethod.toLowerCase().contains('vnpay'))
          .fold<double>(0.0, (s, r) => s + r.order.totalAmount);
      final pairsSold = c.financeFilteredOrders.fold<int>(
        0,
        (s, r) =>
            s + r.order.items.fold<int>(0, (isum, item) => isum + item.quantity),
      );

      final deliveredCount = c.periodDeliveredCount;
      final inProgressCount = c.periodInProgressCount;
      final cancelledCount = c.periodCancelledCount;

      // Comparison calculation against preceding / chosen period
      final cmp = c.comparisonPeriodData;
      final cmpBreakdowns = cmp.records.map(c.breakdownForOrder).toList();
      final cmpCollected =
          cmpBreakdowns.fold<double>(0.0, (s, b) => s + b.netRevenue);
      final cmpProfit =
          cmpBreakdowns.fold<double>(0.0, (s, b) => s + b.netProfit);
      final cmpPairs = cmp.records.fold<int>(
        0,
        (s, r) =>
            s + r.order.items.fold<int>(0, (isum, item) => isum + item.quantity),
      );

      final useMonthlyChart =
          c.selectedTimeFilter.value == AdminTimeFilter.thisMonth ||
              c.selectedTimeFilter.value == AdminTimeFilter.customMonth ||
              c.selectedTimeFilter.value == AdminTimeFilter.allTime;
      final chartSeries = useMonthlyChart
          ? c.activeMonthlyComparisonSeries
          : c.last7DaysRevenueSeries;
      final lowStock = c.lowStockProducts.take(6).toList();

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Tổng quan & Doanh thu',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () => c.selectSection(AdminSection.orders),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Iconsax.shopping_bag, size: 16),
                      label: Text(
                        c.pendingOrdersCount > 0
                            ? 'Đơn chờ (${c.pendingOrdersCount})'
                            : 'Đơn hàng',
                      ),
                    ),
                    AdminPrimaryButton(
                      label: 'Kho sản phẩm',
                      icon: Iconsax.box,
                      onPressed: () => c.selectSection(AdminSection.products),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Period filter bar + compact COGS/VAT toggle
                AdminPeriodFilterBar(
                  controller: c,
                  trailingAction: _CompactPickerButton(
                    icon: Iconsax.setting_4,
                    label:
                        'Vốn ${c.cogsRatePercent.value.toInt()}% · Thuế ${c.vatRatePercent.value.toInt()}%',
                    active: _showCostConfig,
                    onTap: () =>
                        setState(() => _showCostConfig = !_showCostConfig),
                  ),
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: !_showCostConfig
                      ? const SizedBox.shrink()
                      : Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Wrap(
                            spacing: 22,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: c.onlyCompletedForFinance.value,
                                    activeTrackColor: AdminColors.forest,
                                    onChanged: (v) =>
                                        c.onlyCompletedForFinance.value = v,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Chỉ tính đơn đã giao',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Giá vốn: ${c.cogsRatePercent.value.toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 145,
                                    child: Slider(
                                      value: c.cogsRatePercent.value
                                          .clamp(10.0, 75.0),
                                      min: 10,
                                      max: 75,
                                      divisions: 13,
                                      activeColor: AdminColors.forest,
                                      onChanged: (v) =>
                                          c.cogsRatePercent.value = v,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Thuế:',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  for (final vat in [0.0, 5.0, 8.0, 10.0])
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text(
                                          '${vat.toInt()}%',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                c.vatRatePercent.value == vat
                                                    ? Colors.white
                                                    : const Color(0xFF111827),
                                          ),
                                        ),
                                        selected: c.vatRatePercent.value == vat,
                                        selectedColor: const Color(0xFF111827),
                                        checkmarkColor: Colors.white,
                                        backgroundColor:
                                            const Color(0xFFF8FAFC),
                                        onSelected: (_) =>
                                            c.vatRatePercent.value = vat,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // 4 Concise KPI Cards with Period-over-Period Comparison
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 1080
                        ? 4
                        : constraints.maxWidth >= 640
                            ? 2
                            : 1;
                    final cardWidth =
                        (constraints.maxWidth - (cols - 1) * 14) / cols;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _CleanMetricCard(
                          width: cardWidth,
                          label: 'Thực thu · $periodTitle',
                          value: c.formatMoney(collectedUsd),
                          sub1:
                              'VNPay: ${c.formatMoney(vnpayUsd)} · COD: ${c.formatMoney(codUsd)}',
                          sub2: cmp.active
                              ? _deltaText(collectedUsd, cmpCollected, cmp.label)
                              : '${breakdowns.length} đơn hợp lệ',
                          sub2Positive: cmp.active
                              ? (collectedUsd >= cmpCollected)
                              : null,
                        ),
                        _CleanMetricCard(
                          width: cardWidth,
                          label: 'Đơn hàng & Sản lượng',
                          value: '${breakdowns.length} đơn · $pairsSold đôi',
                          sub1:
                              'Giao xong: $deliveredCount · Đang xử lý: $inProgressCount · Hủy: $cancelledCount',
                          sub2: cmp.active
                              ? 'So với ${cmp.label}: ${cmp.records.length} đơn · $cmpPairs đôi'
                              : 'Tổng toàn hệ thống',
                          onTap: () => c.selectSection(AdminSection.orders),
                        ),
                        _CleanMetricCard(
                          width: cardWidth,
                          label: isLoss ? 'Lỗ ròng' : 'Lãi ròng (${margin.toStringAsFixed(0)}%)',
                          value:
                              '${isLoss ? '-' : '+'}${c.formatMoney(netProfitUsd.abs())}',
                          valueColor: collectedUsd == 0
                              ? const Color(0xFF111827)
                              : (isLoss
                                  ? const Color(0xFFB91C1C)
                                  : const Color(0xFF15803D)),
                          sub1:
                              'Vốn ${c.cogsRatePercent.value.toInt()}%: ${c.formatMoney(cogsUsd)} · Thuế ${c.vatRatePercent.value.toInt()}%: ${c.formatMoney(taxUsd)}',
                          sub2: cmp.active
                              ? _deltaText(netProfitUsd, cmpProfit, cmp.label)
                              : 'Thực thu − Giá vốn − Thuế',
                          sub2Positive: cmp.active
                              ? (netProfitUsd >= cmpProfit)
                              : null,
                        ),
                        _CleanMetricCard(
                          width: cardWidth,
                          label: 'Cần xử lý',
                          value: '${c.pendingOrdersCount} đơn chờ',
                          sub1:
                              '${c.pendingReturnsCount} đổi trả · ${c.unreadSupportChatsCount} tin nhắn mới',
                          sub2: '${c.lowStockProducts.length} mẫu sắp hết hàng',
                          onTap: () => c.selectSection(AdminSection.orders),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Sold Items + Trend Chart
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 11,
                        child: _SoldProductsTableCard(
                          periodTitle: periodTitle,
                          items: soldProducts,
                          controller: c,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 12,
                        child: _CleanSingleBarChartCard(
                          title: useMonthlyChart
                              ? 'Doanh thu 6 tháng'
                              : 'Doanh thu 7 ngày qua',
                          series: chartSeries,
                          controller: c,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _SoldProductsTableCard(
                    periodTitle: periodTitle,
                    items: soldProducts,
                    controller: c,
                  ),
                  const SizedBox(height: 16),
                  _CleanSingleBarChartCard(
                    title: useMonthlyChart
                        ? 'Doanh thu 6 tháng'
                        : 'Doanh thu 7 ngày qua',
                    series: chartSeries,
                    controller: c,
                  ),
                ],
                const SizedBox(height: 18),

                // Order Ledger
                _UnifiedOrderLedgerCard(
                  periodTitle: periodTitle,
                  breakdowns: breakdowns,
                  controller: c,
                ),

                if (lowStock.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _LowStockCard(
                    products: lowStock,
                    controller: c,
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

class _CleanMetricCard extends StatelessWidget {
  const _CleanMetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.sub1,
    required this.sub2,
    this.valueColor = const Color(0xFF111827),
    this.sub2Positive,
    this.onTap,
  });

  final double width;
  final String label;
  final String value;
  final String sub1;
  final String sub2;
  final Color valueColor;
  final bool? sub2Positive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final deltaColor = sub2Positive == null
        ? const Color(0xFF64748B)
        : (sub2Positive! ? const Color(0xFF15803D) : const Color(0xFFB91C1C));

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  sub1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: sub2Positive != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: deltaColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoldProductsTableCard extends StatelessWidget {
  const _SoldProductsTableCard({
    required this.periodTitle,
    required this.items,
    required this.controller,
  });

  final String periodTitle;
  final List<AdminSoldProductSummary> items;
  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    final totalPairs = items.fold<int>(0, (s, item) => s + item.quantitySold);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sản phẩm bán ra · $periodTitle ($totalPairs đôi)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              if (items.isEmpty && controller.orders.isNotEmpty)
                TextButton(
                  onPressed: () => controller.selectedTimeFilter.value =
                      AdminTimeFilter.allTime,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Xem tất cả →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 38),
              child: Center(
                child: Text(
                  'Chưa có sản phẩm bán ra trong kỳ này.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < items.take(8).length; i++) ...[
                  if (i > 0)
                    const Divider(height: 14, color: Color(0xFFF1F5F9)),
                  Builder(builder: (_) {
                    final item = items[i];
                    return Row(
                      children: [
                        AdminImageThumb(
                          url: item.thumbnail,
                          width: 42,
                          height: 42,
                          fit: BoxFit.contain,
                          borderRadius: 8,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Text(
                                item.variationsSummary.isNotEmpty
                                    ? item.variationsSummary
                                    : '${item.orderCount} đơn',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'x${item.quantitySold}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 96,
                          child: Text(
                            controller.formatMoney(item.grossRevenueUsd),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _UnifiedOrderLedgerCard extends StatelessWidget {
  const _UnifiedOrderLedgerCard({
    required this.periodTitle,
    required this.breakdowns,
    required this.controller,
  });

  final String periodTitle;
  final List<OrderFinancialBreakdown> breakdowns;
  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Sổ đơn hàng · $periodTitle (${breakdowns.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => controller.selectSection(AdminSection.orders),
                  child: const Text(
                    'Tất cả đơn →',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (breakdowns.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Center(
                child: Text(
                  'Không có đơn hàng trong kỳ đã chọn.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1020),
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  dataRowMinHeight: 50,
                  dataRowMaxHeight: 58,
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Thời gian',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Sản phẩm / Khách',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Kênh TT',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Trạng thái',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Giảm giá',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Thực thu',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Vốn + Thuế',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Lãi ròng',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  rows: breakdowns.map((b) {
                    final meta = AdminOrderStatusMeta.of(b.record.order.status);
                    final isVnPay = b.record.order.paymentMethod
                        .toLowerCase()
                        .contains('vnpay');
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            DateFormat('HH:mm · dd/MM/yy')
                                .format(b.record.order.orderDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 225,
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
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  b.record.customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            isVnPay ? 'VNPay' : 'COD',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        DataCell(
                          AdminBadge(
                            label: meta.label,
                            color: meta.color,
                            bgColor: meta.bgColor,
                          ),
                        ),
                        DataCell(
                          Text(
                            b.discount > 0
                                ? '-${controller.formatMoney(b.discount)}'
                                : '—',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            controller.formatMoney(b.netRevenue),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            controller.formatMoney(b.cogs + b.tax),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${b.isLoss ? '-' : '+'}${controller.formatMoney(b.netProfit.abs())}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: b.isLoss
                                  ? const Color(0xFFB91C1C)
                                  : const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CleanSingleBarChartCard extends StatelessWidget {
  const _CleanSingleBarChartCard({
    required this.title,
    required this.series,
    required this.controller,
  });

  final String title;
  final List<({String label, double revenue, int orderCount})> series;
  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    final maxRevenue =
        series.fold<double>(0, (m, e) => e.revenue > m ? e.revenue : m);
    final maxY = maxRevenue <= 0 ? 100.0 : (maxRevenue * 1.25);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 225,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF111827),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = series[group.x.toInt()];
                      return BarTooltipItem(
                        '${item.label}\n${controller.formatMoney(item.revenue)} · ${item.orderCount} đơn',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 54,
                      getTitlesWidget: (value, meta) => Text(
                        controller.formatCompactMoney(value),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
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
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: idx == series.length - 1
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: idx == series.length - 1
                                  ? const Color(0xFF111827)
                                  : const Color(0xFF64748B),
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
                        width: 26,
                        color: const Color(0xFF173E32),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
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

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({
    required this.products,
    required this.controller,
  });

  final List products;
  final AdminWebController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sắp hết hàng (≤ 10 đôi)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    controller.selectSection(AdminSection.products),
                child: const Text(
                  'Nhập kho →',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 960
                  ? 3
                  : (constraints.maxWidth >= 600 ? 2 : 1);
              final tileW = (constraints.maxWidth - (cols - 1) * 12) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: products.map((product) {
                  final isOut = product.stock <= 0;
                  return Container(
                    width: tileW,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        AdminImageThumb(
                          url: product.thumbnail,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Text(
                                product.brand?.name ?? product.categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isOut
                                ? const Color(0xFFFEF2F2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isOut
                                  ? const Color(0xFFFECACA)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            isOut ? 'Hết hàng' : 'Còn ${product.stock}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isOut
                                  ? const Color(0xFFB91C1C)
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
