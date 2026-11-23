import 'dart:ui' as ui;

import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class ShippingEtaEstimate {
  const ShippingEtaEstimate({
    required this.warehouseName,
    required this.destinationCity,
    required this.fullDestination,
    required this.zoneName,
    required this.distanceKm,
    required this.minDays,
    required this.maxDays,
    required this.checkpoints,
  });

  final String warehouseName;
  final String destinationCity;
  final String fullDestination;
  final String zoneName;
  final int distanceKm;
  final int minDays;
  final int maxDays;
  final List<String> checkpoints;

  DateTime latestDeliveryDate(DateTime orderDate) =>
      orderDate.add(Duration(days: maxDays));

  String etaRangeText({bool english = false}) =>
      english ? '$minDays–$maxDays days' : '$minDays–$maxDays ngày';

  String customerEtaHeadline({bool english = false}) {
    if (english) {
      if (maxDays <= 2) {
        return 'Near VELORA Hanoi Warehouse — Your order will arrive within $minDays–$maxDays days at the latest.';
      }
      return 'Shipping from VELORA Hanoi Warehouse to $destinationCity — Estimated $minDays–$maxDays days.';
    }
    if (maxDays <= 2) {
      return 'Kho Hà Nội gần địa chỉ của bạn ($destinationCity) — Đơn hàng sẽ sớm giao cho bạn trong khoảng $minDays–$maxDays ngày muộn nhất!';
    }
    return 'Vận chuyển từ Tổng Kho Hà Nội về $destinationCity (~$distanceKm km) — Ước lượng giao trong khoảng $minDays–$maxDays ngày.';
  }

  String currentLocationLabel(OrderStatus status, {bool english = false}) {
    switch (status) {
      case OrderStatus.pending:
        return english
            ? 'At VELORA Hanoi Warehouse (Awaiting confirmation)'
            : 'Đang tại: ${checkpoints[0]}';
      case OrderStatus.processing:
        return english
            ? 'Packing at Cau Giay Hub, Hanoi'
            : 'Đang tại: ${checkpoints[1]}';
      case OrderStatus.shipped:
        return english
            ? 'In transit to $destinationCity local hub'
            : 'Đang di chuyển: ${checkpoints[2]}';
      case OrderStatus.received:
        return english
            ? 'Delivered to $fullDestination'
            : 'Đã giao tới: ${checkpoints[3]}';
      case OrderStatus.cancelled:
        return english ? 'Order cancelled' : 'Đơn hàng đã hủy';
    }
  }

  double progressFraction(OrderStatus status) => switch (status) {
        OrderStatus.pending => 0.12,
        OrderStatus.processing => 0.38,
        OrderStatus.shipped => 0.74,
        OrderStatus.received => 1.0,
        OrderStatus.cancelled => 0.0,
      };
}

class ShippingRouteHelper {
  ShippingRouteHelper._();

  static const String warehouseLabel = 'Tổng Kho VELORA Hà Nội (Cầu Giấy)';

  static String _norm(String raw) {
    var s = raw.toLowerCase().trim();
    const map = {
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'đ': 'd',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏa': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    };
    map.forEach((k, v) => s = s.replaceAll(k, v));
    return s;
  }

  static ShippingEtaEstimate estimateForAddress(AddressModel? address) {
    final cityRaw = (address?.city ?? '').trim();
    final stateRaw = (address?.state ?? '').trim();
    final streetRaw = (address?.street ?? '').trim();
    final combined = '$streetRaw $cityRaw $stateRaw'.trim();
    final norm = _norm(combined);

    final displayCity = cityRaw.isNotEmpty
        ? cityRaw
        : (stateRaw.isNotEmpty ? stateRaw : 'Hà Nội');
    final fullDest = [streetRaw, cityRaw, stateRaw]
        .where((s) => s.isNotEmpty)
        .join(', ');
    final safeFullDest = fullDest.isNotEmpty ? fullDest : displayCity;

    // 1. Nội thành & Vùng thủ đô Hà Nội (1 - 2 ngày)
    const hanoiKeywords = [
      'ha noi',
      'hanoi',
      'hn',
      'cau giay',
      'dong da',
      'ba dinh',
      'hoan kiem',
      'hai ba trung',
      'thanh xuan',
      'tay ho',
      'long bien',
      'ha dong',
      'nam tu liem',
      'bac tu liem',
      'hoang mai',
      'gia lam',
      'dong anh',
      'thanh tri',
      'bac ninh',
      'hung yen',
    ];
    if (norm.isEmpty || hanoiKeywords.any((k) => norm.contains(k))) {
      final cityLabel =
          norm.contains('bac ninh') ? 'Bắc Ninh' : (norm.contains('hung yen') ? 'Hưng Yên' : 'Hà Nội');
      return ShippingEtaEstimate(
        warehouseName: warehouseLabel,
        destinationCity: cityRaw.isNotEmpty ? cityRaw : cityLabel,
        fullDestination: safeFullDest,
        zoneName: 'Nội vùng Thủ đô Hà Nội',
        distanceKm: 12,
        minDays: 1,
        maxDays: 2,
        checkpoints: [
          'Tổng Kho VELORA Cầu Giấy, Hà Nội',
          'Trung tâm Phân loại Nhanh Hà Nội',
          'Bưu cục Giao nhanh $cityLabel',
          safeFullDest,
        ],
      );
    }

    // 2. Thanh Hóa & Bắc Trung Bộ / Liên tỉnh Miền Bắc (2 - 3 ngày)
    const northAndNorthCentral = <String, (String, int)>{
      'thanh hoa': ('Thanh Hóa', 155),
      'nghe an': ('Nghệ An', 295),
      'vinh': ('TP. Vinh, Nghệ An', 295),
      'ha tinh': ('Hà Tĩnh', 340),
      'hai phong': ('Hải Phòng', 105),
      'quang ninh': ('Quảng Ninh', 150),
      'ha long': ('Hạ Long, Quảng Ninh', 150),
      'hai duong': ('Hải Dương', 60),
      'nam dinh': ('Nam Định', 88),
      'thai binh': ('Thái Bình', 105),
      'ninh binh': ('Ninh Bình', 93),
      'ha nam': ('Hà Nam', 58),
      'vinh phuc': ('Vĩnh Phúc', 52),
      'thai nguyen': ('Thái Nguyên', 78),
      'phu tho': ('Phú Thọ', 85),
      'bac giang': ('Bắc Giang', 55),
      'hoa binh': ('Hòa Bình', 74),
      'lang son': ('Lạng Sơn', 154),
      'lao cai': ('Lào Cai', 285),
      'yen bai': ('Yên Bái', 165),
      'tuyen quang': ('Tuyên Quang', 135),
      'son la': ('Sơn La', 300),
    };
    for (final entry in northAndNorthCentral.entries) {
      if (norm.contains(entry.key)) {
        final label = entry.value.$1;
        final km = entry.value.$2;
        return ShippingEtaEstimate(
          warehouseName: warehouseLabel,
          destinationCity: label,
          fullDestination: safeFullDest,
          zoneName: 'Tuyến Liên tỉnh Miền Bắc & Bắc Trung Bộ',
          distanceKm: km,
          minDays: 2,
          maxDays: 3,
          checkpoints: [
            'Tổng Kho VELORA Cầu Giấy, Hà Nội',
            'Hub Trung chuyển Pháp Vân – Quốc lộ 1A',
            'Kho Phân loại Tỉnh $label',
            safeFullDest,
          ],
        );
      }
    }

    // 3. Miền Trung & Tây Nguyên (3 - 4 ngày)
    const centralKeywords = <String, (String, int)>{
      'da nang': ('Đà Nẵng', 765),
      'hue': ('Thừa Thiên Huế', 660),
      'quang binh': ('Quảng Bình', 490),
      'quang tri': ('Quảng Trị', 590),
      'quang nam': ('Quảng Nam', 820),
      'hoi an': ('Hội An, Quảng Nam', 795),
      'quang ngai': ('Quảng Ngãi', 890),
      'binh dinh': ('Bình Định', 1060),
      'quy nhon': ('Quy Nhơn, Bình Định', 1060),
      'khanh hoa': ('Khánh Hòa', 1280),
      'nha trang': ('Nha Trang, Khánh Hòa', 1280),
      'dak lak': ('Đắk Lắk', 1350),
      'gia lai': ('Gia Lai', 1180),
      'lam dong': ('Lâm Đồng', 1480),
      'da lat': ('Đà Lạt, Lâm Đồng', 1480),
    };
    for (final entry in centralKeywords.entries) {
      if (norm.contains(entry.key)) {
        final label = entry.value.$1;
        final km = entry.value.$2;
        return ShippingEtaEstimate(
          warehouseName: warehouseLabel,
          destinationCity: label,
          fullDestination: safeFullDest,
          zoneName: 'Tuyến Nhanh Bắc – Trung',
          distanceKm: km,
          minDays: 3,
          maxDays: 4,
          checkpoints: [
            'Tổng Kho VELORA Cầu Giấy, Hà Nội',
            'Trạm Tiếp vận Hàng không Nội Bài (HAN)',
            'Trung tâm Khai thác Miền Trung ($label)',
            safeFullDest,
          ],
        );
      }
    }

    // 4. TP.HCM & Miền Nam (3 - 5 ngày)
    return ShippingEtaEstimate(
      warehouseName: warehouseLabel,
      destinationCity: displayCity,
      fullDestination: safeFullDest,
      zoneName: 'Tuyến Bay Hà Nội – Miền Nam',
      distanceKm: 1650,
      minDays: 3,
      maxDays: 5,
      checkpoints: [
        'Tổng Kho VELORA Cầu Giấy, Hà Nội',
        'Ga Hàng hóa Sân bay Nội Bài (HAN)',
        'Hub Phân loại Khu vực ($displayCity)',
        safeFullDest,
      ],
    );
  }
}

/// Interactive GPS Route & Live Order Tracking Map widget for Mobile & Web Admin.
class VeloraOrderTrackingMap extends StatelessWidget {
  const VeloraOrderTrackingMap({
    super.key,
    required this.status,
    required this.address,
    required this.orderDate,
    required this.deliveryDate,
    this.onAutoSetDeliveryDate,
  });

  final OrderStatus status;
  final AddressModel? address;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final ValueChanged<DateTime>? onAutoSetDeliveryDate;

  @override
  Widget build(BuildContext context) {
    final estimate = ShippingRouteHelper.estimateForAddress(address);
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final progress = estimate.progressFraction(status);
    final stepIdx = switch (status) {
      OrderStatus.pending => 0,
      OrderStatus.processing => 1,
      OrderStatus.shipped => 2,
      OrderStatus.received => 3,
      OrderStatus.cancelled => -1,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E4DD), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102B23).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Visual Map Canvas
          SizedBox(
            height: 178,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _RouteMapCanvasPainter(
                    progress: progress,
                    isCancelled: status == OrderStatus.cancelled,
                  ),
                ),
                // Top-left Origin Badge (Kho Hà Nội)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF102B23).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.building_4,
                          size: 14,
                          color: Color(0xFFDDEABB),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Kho xuất phát: Hà Nội (Cầu Giấy)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Top-right Distance & ETA Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD8D2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.routing,
                          size: 14,
                          color: Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '~${estimate.distanceKm} km • ${estimate.etaRangeText(english: isEn)}',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom-left Live GPS Checkpoint Pill
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: const Color(0xFFCBD8D2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: status == OrderStatus.received
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFE0F2FE),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            status == OrderStatus.received
                                ? Iconsax.tick_circle
                                : Iconsax.truck_fast,
                            size: 15,
                            color: status == OrderStatus.received
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            estimate.currentLocationLabel(
                              status,
                              english: isEn,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          '→ ${estimate.destinationCity}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Smart ETA Explanation & Checkpoints
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Iconsax.timer_1,
                        size: 17,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              estimate.customerEtaHeadline(english: isEn),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0C4A6E),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Dự kiến giao muộn nhất: ${DateFormat('dd/MM/yyyy').format(estimate.latestDeliveryDate(orderDate))} • Khu vực: ${estimate.zoneName}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onAutoSetDeliveryDate != null)
                        TextButton.icon(
                          onPressed: () => onAutoSetDeliveryDate!(
                            estimate.latestDeliveryDate(orderDate),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Iconsax.magicpen, size: 13),
                          label: Text(
                            'Set tự động (${estimate.minDays}–${estimate.maxDays} ngày)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 4 Route Checkpoints
                for (int i = 0; i < estimate.checkpoints.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: i < estimate.checkpoints.length - 1 ? 8 : 0),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: i <= stepIdx
                                ? (i == stepIdx
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFF16A34A))
                                : const Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            i <= stepIdx
                                ? Icons.check_rounded
                                : Icons.circle_outlined,
                            size: 12,
                            color: i <= stepIdx
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            estimate.checkpoints[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: i == stepIdx
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: i <= stepIdx
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        if (i == stepIdx)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Vị trí hiện tại',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                      ],
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

class _RouteMapCanvasPainter extends CustomPainter {
  const _RouteMapCanvasPainter({
    required this.progress,
    required this.isCancelled,
  });

  final double progress;
  final bool isCancelled;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft topographic map background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE6F2EC), Color(0xFFD9ECF5)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Stylized river / coastline & map grid
    final riverPath = Path()
      ..moveTo(size.width * 0.18, 0)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.35,
        size.width * 0.22,
        size.height * 0.7,
        size.width * 0.38,
        size.height,
      );
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );

    final gridPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (double x = 40; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 30; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Curved GPS Highway Route from Hanoi Warehouse (left) to Customer (right)
    final start = Offset(size.width * 0.12, size.height * 0.56);
    final mid1 = Offset(size.width * 0.38, size.height * 0.26);
    final mid2 = Offset(size.width * 0.64, size.height * 0.68);
    final end = Offset(size.width * 0.88, size.height * 0.42);

    final routePath = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(mid1.dx, mid1.dy, mid2.dx, mid2.dy, end.dx, end.dy);

    // Inactive full route track
    canvas.drawPath(
      routePath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      routePath,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );

    // Active traveled route segment + courier marker
    final metrics = routePath.computeMetrics().toList();
    if (metrics.isNotEmpty && !isCancelled) {
      final metric = metrics.first;
      final activeLen = metric.length * progress.clamp(0.0, 1.0);
      final activePath = metric.extractPath(0, activeLen);
      canvas.drawPath(
        activePath,
        Paint()
          ..color = const Color(0xFF0284C7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );

      final tangent = metric.getTangentForOffset(activeLen);
      if (tangent != null) {
        final pos = tangent.position;
        // Pulsing halo
        canvas.drawCircle(
          pos,
          16,
          Paint()..color = const Color(0xFF0284C7).withValues(alpha: 0.22),
        );
        canvas.drawCircle(
          pos,
          9,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          pos,
          6.5,
          Paint()..color = const Color(0xFF0284C7),
        );
      }
    }

    // Origin node (Hanoi Warehouse)
    canvas.drawCircle(start, 9, Paint()..color = Colors.white);
    canvas.drawCircle(start, 6.5, Paint()..color = const Color(0xFF173E32));

    // Destination node (Customer address)
    canvas.drawCircle(end, 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      end,
      6.5,
      Paint()
        ..color = progress >= 1.0
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626),
    );
  }

  @override
  bool shouldRepaint(covariant _RouteMapCanvasPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isCancelled != isCancelled;
}
