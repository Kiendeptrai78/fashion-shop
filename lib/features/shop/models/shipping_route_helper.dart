import 'dart:math' as math;
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

class _VnGeoPoint {
  const _VnGeoPoint({
    required this.name,
    required this.lat,
    required this.lng,
    required this.region,
    this.aliases = const [],
  });

  final String name;
  final double lat;
  final double lng;
  final String region;
  final List<String> aliases;
}

class ShippingRouteHelper {
  ShippingRouteHelper._();

  static const String warehouseLabel = 'Tổng Kho VELORA Hà Nội (Cầu Giấy)';
  static const double warehouseLat = 21.0333;
  static const double warehouseLng = 105.7833;

  // Vietnam National Highway 1A backbone waypoints for accurate road routing
  static const _hubVinh = (lat: 18.6796, lng: 105.6813);
  static const _hubDaNang = (lat: 16.0544, lng: 108.2022);
  static const _hubNhaTrang = (lat: 12.2388, lng: 109.1967);
  static const _hubHcm = (lat: 10.7769, lng: 106.7009);

  /// All 63 provinces & centrally governed cities of Vietnam with exact coordinates.
  static const List<_VnGeoPoint> _vietnamProvinces = [
    // --- Miền Bắc ---
    _VnGeoPoint(name: 'Hà Nội', lat: 21.0285, lng: 105.8542, region: 'Thủ đô Hà Nội', aliases: ['ha noi', 'hanoi']),
    _VnGeoPoint(name: 'Bắc Ninh', lat: 21.1861, lng: 106.0763, region: 'Đồng bằng sông Hồng', aliases: ['bac ninh', 'tu son', 'que vo', 'thuan thanh', 'yen phong', 'tien du']),
    _VnGeoPoint(name: 'Hưng Yên', lat: 20.6464, lng: 106.0511, region: 'Đồng bằng sông Hồng', aliases: ['hung yen', 'my hao', 'van giang', 'van lam']),
    _VnGeoPoint(name: 'Vĩnh Phúc', lat: 21.3089, lng: 105.6049, region: 'Đồng bằng sông Hồng', aliases: ['vinh phuc', 'vinh yen', 'phuc yen', 'binh xuyen', 'tam dao']),
    _VnGeoPoint(name: 'Hà Nam', lat: 20.5435, lng: 105.9139, region: 'Đồng bằng sông Hồng', aliases: ['ha nam', 'phu ly', 'duy tien']),
    _VnGeoPoint(name: 'Hải Dương', lat: 20.9373, lng: 106.3146, region: 'Đồng bằng sông Hồng', aliases: ['hai duong', 'chi linh', 'kinh mon', 'cam giang']),
    _VnGeoPoint(name: 'Hải Phòng', lat: 20.8449, lng: 106.6881, region: 'Đồng bằng sông Hồng', aliases: ['hai phong', 'hong bang', 'ngo quyen', 'le chan', 'hai an', 'kien an', 'do son', 'thuy nguyen', 'cat ba']),
    _VnGeoPoint(name: 'Nam Định', lat: 20.4388, lng: 106.1621, region: 'Đồng bằng sông Hồng', aliases: ['nam dinh', 'hai hau', 'giao thuy', 'xuan truong']),
    _VnGeoPoint(name: 'Ninh Bình', lat: 20.2506, lng: 105.9745, region: 'Đồng bằng sông Hồng', aliases: ['ninh binh', 'tam diep', 'hoa lu', 'gia vien', 'trang an']),
    _VnGeoPoint(name: 'Thái Bình', lat: 20.4463, lng: 106.3366, region: 'Đồng bằng sông Hồng', aliases: ['thai binh', 'dong hung', 'hung ha', 'kien xuong']),
    _VnGeoPoint(name: 'Quảng Ninh', lat: 20.9599, lng: 107.0425, region: 'Đông Bắc Bộ', aliases: ['quang ninh', 'ha long', 'cam pha', 'uong bi', 'mong cai', 'quang yen']),
    _VnGeoPoint(name: 'Bắc Giang', lat: 21.2731, lng: 106.1946, region: 'Đông Bắc Bộ', aliases: ['bac giang', 'viet yen', 'hiep hoa', 'lang giang']),
    _VnGeoPoint(name: 'Thái Nguyên', lat: 21.5942, lng: 105.8482, region: 'Đông Bắc Bộ', aliases: ['thai nguyen', 'song cong', 'pho yen', 'dai tu']),
    _VnGeoPoint(name: 'Phú Thọ', lat: 21.3227, lng: 105.4020, region: 'Đông Bắc Bộ', aliases: ['phu tho', 'viet tri']),
    _VnGeoPoint(name: 'Hòa Bình', lat: 20.8133, lng: 105.3383, region: 'Tây Bắc Bộ', aliases: ['hoa binh', 'mai chau']),
    _VnGeoPoint(name: 'Lạng Sơn', lat: 21.8537, lng: 106.7615, region: 'Đông Bắc Bộ', aliases: ['lang son']),
    _VnGeoPoint(name: 'Tuyên Quang', lat: 21.8236, lng: 105.2142, region: 'Đông Bắc Bộ', aliases: ['tuyen quang']),
    _VnGeoPoint(name: 'Yên Bái', lat: 21.7168, lng: 104.8986, region: 'Tây Bắc Bộ', aliases: ['yen bai', 'nghia lo', 'mu cang chai']),
    _VnGeoPoint(name: 'Bắc Kạn', lat: 22.1470, lng: 105.8348, region: 'Đông Bắc Bộ', aliases: ['bac kan', 'bac can']),
    _VnGeoPoint(name: 'Cao Bằng', lat: 22.6667, lng: 106.2500, region: 'Đông Bắc Bộ', aliases: ['cao bang']),
    _VnGeoPoint(name: 'Hà Giang', lat: 22.8233, lng: 104.9836, region: 'Đông Bắc Bộ', aliases: ['ha giang', 'dong van']),
    _VnGeoPoint(name: 'Lào Cai', lat: 22.4809, lng: 103.9755, region: 'Tây Bắc Bộ', aliases: ['lao cai', 'sa pa', 'sapa', 'bao thang', 'bat xat']),
    _VnGeoPoint(name: 'Sơn La', lat: 21.3256, lng: 103.9188, region: 'Tây Bắc Bộ', aliases: ['son la', 'moc chau']),
    _VnGeoPoint(name: 'Lai Châu', lat: 22.3864, lng: 103.4703, region: 'Tây Bắc Bộ', aliases: ['lai chau']),
    _VnGeoPoint(name: 'Điện Biên', lat: 21.3860, lng: 103.0230, region: 'Tây Bắc Bộ', aliases: ['dien bien', 'dien bien phu']),

    // --- Bắc Trung Bộ ---
    _VnGeoPoint(name: 'Thanh Hóa', lat: 19.8067, lng: 105.7852, region: 'Bắc Trung Bộ', aliases: ['thanh hoa', 'sam son', 'bim son', 'nghi son', 'hoang hoa', 'quang xuong', 'dong son', 'tho xuan', 'trieu son', 'tinh gia']),
    _VnGeoPoint(name: 'Nghệ An', lat: 18.6796, lng: 105.6813, region: 'Bắc Trung Bộ', aliases: ['nghe an', 'tp vinh', 'thanh pho vinh', 'cua lo', 'hoang mai nghe an', 'dien chau', 'quynh luu', 'nam dan']),
    _VnGeoPoint(name: 'Hà Tĩnh', lat: 18.3428, lng: 105.9057, region: 'Bắc Trung Bộ', aliases: ['ha tinh', 'hong linh', 'ky anh', 'nghi xuan']),
    _VnGeoPoint(name: 'Quảng Bình', lat: 17.4689, lng: 106.6223, region: 'Bắc Trung Bộ', aliases: ['quang binh', 'dong hoi', 'ba don', 'bo trach', 'le thuy']),
    _VnGeoPoint(name: 'Quảng Trị', lat: 16.8163, lng: 107.1003, region: 'Bắc Trung Bộ', aliases: ['quang tri', 'dong ha']),
    _VnGeoPoint(name: 'Thừa Thiên Huế', lat: 16.4637, lng: 107.5909, region: 'Bắc Trung Bộ', aliases: ['thua thien hue', 'tp hue', 'hue', 'huong thuy', 'huong tra', 'phu vang']),

    // --- Duyên hải Nam Trung Bộ & Tây Nguyên ---
    _VnGeoPoint(name: 'Đà Nẵng', lat: 16.0544, lng: 108.2022, region: 'Duyên hải Miền Trung', aliases: ['da nang', 'hai chau', 'thanh khe', 'son tra', 'ngu hanh son', 'lien chieu', 'cam le', 'hoa vang']),
    _VnGeoPoint(name: 'Quảng Nam', lat: 15.5736, lng: 108.4740, region: 'Duyên hải Miền Trung', aliases: ['quang nam', 'tam ky', 'hoi an', 'dien ban', 'duy xuyen']),
    _VnGeoPoint(name: 'Quảng Ngãi', lat: 15.1214, lng: 108.8044, region: 'Duyên hải Miền Trung', aliases: ['quang ngai']),
    _VnGeoPoint(name: 'Bình Định', lat: 13.7830, lng: 109.2197, region: 'Duyên hải Miền Trung', aliases: ['binh dinh', 'quy nhon', 'an nhon', 'hoai nhon', 'tuy phuoc']),
    _VnGeoPoint(name: 'Phú Yên', lat: 13.0955, lng: 109.3209, region: 'Duyên hải Miền Trung', aliases: ['phu yen', 'tuy hoa']),
    _VnGeoPoint(name: 'Khánh Hòa', lat: 12.2388, lng: 109.1967, region: 'Duyên hải Miền Trung', aliases: ['khanh hoa', 'nha trang', 'cam ranh', 'ninh hoa', 'dien khanh']),
    _VnGeoPoint(name: 'Ninh Thuận', lat: 11.5643, lng: 108.9886, region: 'Duyên hải Miền Trung', aliases: ['ninh thuan', 'phan rang']),
    _VnGeoPoint(name: 'Bình Thuận', lat: 10.9289, lng: 108.1021, region: 'Duyên hải Miền Trung', aliases: ['binh thuan', 'phan thiet', 'mui ne']),
    _VnGeoPoint(name: 'Kon Tum', lat: 14.3545, lng: 108.0076, region: 'Tây Nguyên', aliases: ['kon tum']),
    _VnGeoPoint(name: 'Gia Lai', lat: 13.9833, lng: 108.0000, region: 'Tây Nguyên', aliases: ['gia lai', 'pleiku']),
    _VnGeoPoint(name: 'Đắk Lắk', lat: 12.6667, lng: 108.0500, region: 'Tây Nguyên', aliases: ['dak lak', 'dac lac', 'buon ma thuot']),
    _VnGeoPoint(name: 'Đắk Nông', lat: 12.0033, lng: 107.6876, region: 'Tây Nguyên', aliases: ['dak nong', 'gia nghia']),
    _VnGeoPoint(name: 'Lâm Đồng', lat: 11.9404, lng: 108.4583, region: 'Tây Nguyên', aliases: ['lam dong', 'da lat', 'dalat', 'bao loc', 'duc trong', 'di linh']),

    // --- Đông Nam Bộ ---
    _VnGeoPoint(name: 'TP. Hồ Chí Minh', lat: 10.7769, lng: 106.7009, region: 'Đông Nam Bộ', aliases: ['ho chi minh', 'tp hcm', 'tphcm', 'hcm', 'sai gon', 'saigon', 'thu duc', 'binh thanh', 'phu nhuan', 'tan binh', 'go vap', 'tan phu', 'binh chanh', 'nha be']),
    _VnGeoPoint(name: 'Bình Dương', lat: 10.9804, lng: 106.6519, region: 'Đông Nam Bộ', aliases: ['binh duong', 'thu dau mot', 'di an', 'thuan an', 'tan uyen', 'ben cat']),
    _VnGeoPoint(name: 'Đồng Nai', lat: 10.9574, lng: 106.8427, region: 'Đông Nam Bộ', aliases: ['dong nai', 'bien hoa', 'long khanh', 'long thanh', 'nhon trach', 'trang bom']),
    _VnGeoPoint(name: 'Bà Rịa - Vũng Tàu', lat: 10.3460, lng: 107.0843, region: 'Đông Nam Bộ', aliases: ['ba ria vung tau', 'ba ria', 'vung tau', 'phu my', 'long dien']),
    _VnGeoPoint(name: 'Bình Phước', lat: 11.5350, lng: 106.8832, region: 'Đông Nam Bộ', aliases: ['binh phuoc', 'dong xoai']),
    _VnGeoPoint(name: 'Tây Ninh', lat: 11.3100, lng: 106.0983, region: 'Đông Nam Bộ', aliases: ['tay ninh']),

    // --- Đồng bằng sông Cửu Long (Miền Tây) ---
    _VnGeoPoint(name: 'Long An', lat: 10.5359, lng: 106.4137, region: 'Đồng bằng sông Cửu Long', aliases: ['long an', 'tan an', 'ben luc', 'duc hoa', 'can giuoc']),
    _VnGeoPoint(name: 'Tiền Giang', lat: 10.3600, lng: 106.3600, region: 'Đồng bằng sông Cửu Long', aliases: ['tien giang', 'my tho']),
    _VnGeoPoint(name: 'Bến Tre', lat: 10.2433, lng: 106.3756, region: 'Đồng bằng sông Cửu Long', aliases: ['ben tre']),
    _VnGeoPoint(name: 'Trà Vinh', lat: 9.9347, lng: 106.3453, region: 'Đồng bằng sông Cửu Long', aliases: ['tra vinh']),
    _VnGeoPoint(name: 'Vĩnh Long', lat: 10.2537, lng: 105.9722, region: 'Đồng bằng sông Cửu Long', aliases: ['vinh long']),
    _VnGeoPoint(name: 'Đồng Tháp', lat: 10.4602, lng: 105.6329, region: 'Đồng bằng sông Cửu Long', aliases: ['dong thap', 'cao lanh', 'sa dec']),
    _VnGeoPoint(name: 'An Giang', lat: 10.3864, lng: 105.4352, region: 'Đồng bằng sông Cửu Long', aliases: ['an giang', 'long xuyen', 'chau doc']),
    _VnGeoPoint(name: 'Cần Thơ', lat: 10.0452, lng: 105.7469, region: 'Đồng bằng sông Cửu Long', aliases: ['can tho', 'ninh kieu', 'binh thuy', 'cai rang', 'o mon', 'thot not']),
    _VnGeoPoint(name: 'Hậu Giang', lat: 9.7845, lng: 105.4701, region: 'Đồng bằng sông Cửu Long', aliases: ['hau giang', 'vi thanh']),
    _VnGeoPoint(name: 'Sóc Trăng', lat: 9.6025, lng: 105.9739, region: 'Đồng bằng sông Cửu Long', aliases: ['soc trang']),
    _VnGeoPoint(name: 'Bạc Liêu', lat: 9.2940, lng: 105.7216, region: 'Đồng bằng sông Cửu Long', aliases: ['bac lieu']),
    _VnGeoPoint(name: 'Kiên Giang', lat: 10.0125, lng: 105.0809, region: 'Đồng bằng sông Cửu Long', aliases: ['kien giang', 'rach gia', 'phu quoc', 'ha tien']),
    _VnGeoPoint(name: 'Cà Mau', lat: 9.1768, lng: 105.1524, region: 'Đồng bằng sông Cửu Long', aliases: ['ca mau']),
  ];

  /// Hanoi district coordinates so inner-city & suburban distances from Cầu Giấy are exact.
  static const Map<String, ({double lat, double lng})> _hanoiDistrictCoords = {
    'cau giay': (lat: 21.0333, lng: 105.7833),
    'nam tu liem': (lat: 21.0185, lng: 105.7625),
    'bac tu liem': (lat: 21.0706, lng: 105.7586),
    'dong da': (lat: 21.0181, lng: 105.8292),
    'ba dinh': (lat: 21.0341, lng: 105.8372),
    'thanh xuan': (lat: 20.9949, lng: 105.8058),
    'tay ho': (lat: 21.0695, lng: 105.8235),
    'hoan kiem': (lat: 21.0285, lng: 105.8542),
    'hai ba trung': (lat: 21.0058, lng: 105.8576),
    'ha dong': (lat: 20.9718, lng: 105.7788),
    'hoang mai': (lat: 20.9746, lng: 105.8544),
    'long bien': (lat: 21.0362, lng: 105.8938),
    'hoai duc': (lat: 21.0297, lng: 105.7029),
    'thanh tri': (lat: 20.9410, lng: 105.8453),
    'gia lam': (lat: 21.0235, lng: 105.9403),
    'dong anh': (lat: 21.1378, lng: 105.8468),
    'soc son': (lat: 21.2577, lng: 105.8489),
    'son tay': (lat: 21.1389, lng: 105.5050),
  };

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
    s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static bool _isValidVietnamCoord(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= 8.0 && lat <= 23.6 && lng >= 102.0 && lng <= 110.2;
  }

  /// Calculates realistic highway road distance (km) between any two coordinates in Vietnam,
  /// following the S-shaped National Highway 1A corridor when crossing North-Central-South regions.
  static int calculateVietnamRoadKm(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    final direct = _haversineKm(fromLat, fromLng, toLat, toLng);
    if (direct < 2.0) return 3;

    // Same local area or short inter-province trip
    final latSpan = (fromLat - toLat).abs();
    if (direct <= 220 || latSpan <= 2.2) {
      final factor = direct < 25 ? 1.22 : 1.25;
      return math.max(3, (direct * factor).round());
    }

    // Build ordered North-to-South highway waypoints between fromLat and toLat
    final goingSouth = fromLat > toLat;
    final hiLat = goingSouth ? fromLat : toLat;
    final loLat = goingSouth ? toLat : fromLat;

    final corridor = <({double lat, double lng})>[];
    if (hiLat > _hubVinh.lat + 0.6 && loLat < _hubVinh.lat - 0.6) {
      corridor.add(_hubVinh);
    }
    if (hiLat > _hubDaNang.lat + 0.4 && loLat < _hubDaNang.lat - 0.4) {
      corridor.add(_hubDaNang);
    }
    if (hiLat > _hubNhaTrang.lat + 0.5 && loLat < _hubNhaTrang.lat - 0.5) {
      corridor.add(_hubNhaTrang);
    }
    if (hiLat > _hubHcm.lat + 0.35 && loLat < _hubHcm.lat - 0.15) {
      corridor.add(_hubHcm);
    }
    final ordered = goingSouth ? corridor : corridor.reversed.toList();

    var curLat = fromLat;
    var curLng = fromLng;
    var totalStraight = 0.0;
    for (final wp in ordered) {
      totalStraight += _haversineKm(curLat, curLng, wp.lat, wp.lng);
      curLat = wp.lat;
      curLng = wp.lng;
    }
    totalStraight += _haversineKm(curLat, curLng, toLat, toLng);

    // Apply realistic road curvature multiplier along QL1A / CT01
    final roadFactor = ordered.isEmpty ? 1.25 : 1.23;
    return math.max(3, (totalStraight * roadFactor).round());
  }

  static bool _containsWholePhrase(String haystack, String needle) {
    if (haystack.isEmpty || needle.isEmpty) return false;
    final paddedHay = ' $haystack ';
    final paddedNeedle = ' $needle ';
    return paddedHay.contains(paddedNeedle);
  }

  /// Finds the canonical Vietnam province from a text string (city, district, or raw text),
  /// matching exact province names first and then longest word-boundary aliases so
  /// e.g. "Vĩnh Phúc" never collides with "Vinh".
  static _VnGeoPoint? _matchProvince(String text) {
    final norm = _norm(text);
    if (norm.isEmpty) return null;

    // 1. Exact canonical province name match
    for (final p in _vietnamProvinces) {
      final pNorm = _norm(p.name);
      if (norm == pNorm || _containsWholePhrase(norm, pNorm)) {
        return p;
      }
    }

    // 2. Longest alias whole-phrase match
    _VnGeoPoint? best;
    var bestLen = 0;
    for (final p in _vietnamProvinces) {
      for (final alias in p.aliases) {
        if (alias.length > bestLen && _containsWholePhrase(norm, alias)) {
          best = p;
          bestLen = alias.length;
        }
      }
    }
    if (best != null) return best;

    // 3. Hanoi district match (when user typed only district like "Cầu Giấy", "Hà Đông")
    for (final distKey in _hanoiDistrictCoords.keys) {
      if (_containsWholePhrase(norm, distKey)) {
        return _vietnamProvinces.first; // Hà Nội
      }
    }

    // 4. Standalone "vinh" -> Nghệ An (only after ruling out Vĩnh Phúc / Vĩnh Long / Trà Vinh)
    if (_containsWholePhrase(norm, 'vinh')) {
      return _vietnamProvinces.firstWhere((p) => p.name == 'Nghệ An');
    }

    return null;
  }

  /// Calculates road distance (km) between ANY two Vietnamese provinces/cities.
  static int distanceBetweenProvinces(String fromText, String toText) {
    final from = _matchProvince(fromText);
    final to = _matchProvince(toText);
    if (from == null || to == null) return 0;
    if (from.name == to.name) return 10;
    return calculateVietnamRoadKm(from.lat, from.lng, to.lat, to.lng);
  }

  /// Resolves the canonical province name for dropdown pre-selection when editing saved addresses.
  static String? resolveCanonicalProvince(String rawText) {
    return _matchProvince(rawText)?.name;
  }

  static ({double lat, double lng})? _resolveHanoiDistrictCoord(String text) {
    final norm = _norm(text);
    if (norm.isEmpty) return null;
    for (final entry in _hanoiDistrictCoords.entries) {
      if (_containsWholePhrase(norm, entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static ShippingEtaEstimate estimateFromRawText(String rawText) {
    final cleaned = rawText.trim();
    final matched = _matchProvince(cleaned);
    final detectedCity = matched?.name ?? (cleaned.isNotEmpty ? cleaned : 'Hà Nội');
    return estimateForAddress(
      AddressModel(
        id: 'ai_query',
        name: '',
        phoneNumber: '',
        street: '',
        city: detectedCity,
        state: cleaned,
        country: 'Việt Nam',
      ),
    );
  }

  static ShippingEtaEstimate estimateForAddress(AddressModel? address) {
    final cityRaw = (address?.city ?? '').trim();
    final stateRaw = (address?.state ?? '').trim();
    final streetRaw = (address?.street ?? '').trim();

    // Priority: match Province/City first, then District/State, then Street (prevents "Đường Hà Nội, TP. Huế" matching Hà Nội)
    final matchedProvince = _matchProvince(cityRaw) ??
        _matchProvince(stateRaw) ??
        _matchProvince(streetRaw) ??
        _vietnamProvinces.first;

    final displayCity = matchedProvince.name;
    final fullDest = [streetRaw, stateRaw, cityRaw]
        .where((s) => s.isNotEmpty)
        .toSet()
        .join(', ');
    final safeFullDest = fullDest.isNotEmpty ? fullDest : displayCity;

    // Determine target coordinates:
    // 1) User pinned exact GPS point inside Vietnam
    // 2) Specific Hanoi district coordinates when destination is Hà Nội
    // 3) Matched province center coordinates
    double targetLat = matchedProvince.lat;
    double targetLng = matchedProvince.lng;
    if (_isValidVietnamCoord(address?.latitude, address?.longitude)) {
      targetLat = address!.latitude!;
      targetLng = address.longitude!;
    } else if (matchedProvince.name == 'Hà Nội') {
      final distCoord = _resolveHanoiDistrictCoord('$stateRaw $streetRaw');
      if (distCoord != null) {
        targetLat = distCoord.lat;
        targetLng = distCoord.lng;
      } else {
        targetLat = 21.0285;
        targetLng = 105.8200;
      }
    }

    // Special check for Phú Quốc island (+85 km sea/air link from Rạch Giá)
    final fullNorm = _norm('$streetRaw $stateRaw $cityRaw');
    var distanceKm = calculateVietnamRoadKm(
      warehouseLat,
      warehouseLng,
      targetLat,
      targetLng,
    );
    if (_containsWholePhrase(fullNorm, 'phu quoc') &&
        !_isValidVietnamCoord(address?.latitude, address?.longitude)) {
      distanceKm += 95;
    }

    // Determine shipping zone, ETA days, and checkpoints based on real distance & region
    if (distanceKm <= 38 && matchedProvince.name == 'Hà Nội') {
      return ShippingEtaEstimate(
        warehouseName: warehouseLabel,
        destinationCity: displayCity,
        fullDestination: safeFullDest,
        zoneName: 'Nội thành & Ngoại thành Hà Nội',
        distanceKm: distanceKm,
        minDays: 1,
        maxDays: 2,
        checkpoints: [
          'Tổng Kho VELORA Cầu Giấy, Hà Nội',
          'Trung tâm Phân loại Nhanh Hà Nội',
          'Bưu cục Giao nhanh ${stateRaw.isNotEmpty ? stateRaw : displayCity}',
          safeFullDest,
        ],
      );
    }

    if (distanceKm <= 220) {
      return ShippingEtaEstimate(
        warehouseName: warehouseLabel,
        destinationCity: displayCity,
        fullDestination: safeFullDest,
        zoneName: 'Tuyến Liên tỉnh ${matchedProvince.region}',
        distanceKm: distanceKm,
        minDays: 2,
        maxDays: 3,
        checkpoints: [
          'Tổng Kho VELORA Cầu Giấy, Hà Nội',
          'Hub Trung chuyển Cửa ngõ Hà Nội',
          'Kho Phân loại Tỉnh $displayCity',
          safeFullDest,
        ],
      );
    }

    if (distanceKm <= 550) {
      return ShippingEtaEstimate(
        warehouseName: warehouseLabel,
        destinationCity: displayCity,
        fullDestination: safeFullDest,
        zoneName: 'Tuyến Nhanh ${matchedProvince.region}',
        distanceKm: distanceKm,
        minDays: 2,
        maxDays: 3,
        checkpoints: [
          'Tổng Kho VELORA Cầu Giấy, Hà Nội',
          'Hub Trung chuyển Pháp Vân – Quốc lộ 1A',
          'Kho Phân loại Khu vực $displayCity',
          safeFullDest,
        ],
      );
    }

    if (distanceKm <= 1200) {
      return ShippingEtaEstimate(
        warehouseName: warehouseLabel,
        destinationCity: displayCity,
        fullDestination: safeFullDest,
        zoneName: 'Tuyến Nhanh Bắc – Trung (${matchedProvince.region})',
        distanceKm: distanceKm,
        minDays: 3,
        maxDays: 4,
        checkpoints: [
          'Tổng Kho VELORA Cầu Giấy, Hà Nội',
          'Trạm Tiếp vận Hàng không Nội Bài (HAN)',
          'Trung tâm Khai thác Miền Trung ($displayCity)',
          safeFullDest,
        ],
      );
    }

    return ShippingEtaEstimate(
      warehouseName: warehouseLabel,
      destinationCity: displayCity,
      fullDestination: safeFullDest,
      zoneName: 'Tuyến Bay Hà Nội – ${matchedProvince.region}',
      distanceKm: distanceKm,
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
                            softWrap: true,
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
                            softWrap: true,
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
