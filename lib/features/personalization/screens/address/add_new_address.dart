import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/loaders/loader.dart';
import 'package:fashion_business_app/features/personalization/controllers/address_controller.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/shop/models/shipping_route_helper.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:fashion_business_app/utils/validators/validation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'widgets/address_map_picker.dart';

class AddNewAddressScreen extends StatefulWidget {
  const AddNewAddressScreen({super.key, this.editingAddress});

  final AddressModel? editingAddress;

  @override
  State<AddNewAddressScreen> createState() => _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends State<AddNewAddressScreen> {
  static const Map<String, List<String>> _vietnamLocations = {
    'Hà Nội': [
      'Quận Cầu Giấy',
      'Quận Đống Đa',
      'Quận Ba Đình',
      'Quận Hoàn Kiếm',
      'Quận Hai Bà Trưng',
      'Quận Thanh Xuân',
      'Quận Hoàng Mai',
      'Quận Tây Hồ',
      'Quận Long Biên',
      'Quận Nam Từ Liêm',
      'Quận Bắc Từ Liêm',
      'Quận Hà Đông',
      'Huyện Đông Anh',
      'Huyện Gia Lâm',
      'Huyện Thanh Trì',
      'Huyện Hoài Đức',
      'Huyện Sóc Sơn',
      'Thị xã Sơn Tây',
    ],
    'TP. Hồ Chí Minh': [
      'Quận 1',
      'Quận 3',
      'Quận 4',
      'Quận 5',
      'Quận 7',
      'Quận 10',
      'Quận Bình Thạnh',
      'Quận Phú Nhuận',
      'Quận Tân Bình',
      'Quận Gò Vấp',
      'Quận Tân Phú',
      'TP. Thủ Đức',
      'Huyện Bình Chánh',
      'Huyện Nhà Bè',
    ],
    'Đà Nẵng': [
      'Quận Hải Châu',
      'Quận Thanh Khê',
      'Quận Sơn Trà',
      'Quận Ngũ Hành Sơn',
      'Quận Liên Chiểu',
      'Quận Cẩm Lệ',
      'Huyện Hòa Vang',
    ],
    'Hải Phòng': [
      'Quận Hồng Bàng',
      'Quận Ngô Quyền',
      'Quận Lê Chân',
      'Quận Hải An',
      'Quận Kiến An',
      'Quận Đồ Sơn',
      'Huyện Thủy Nguyên',
    ],
    'Cần Thơ': [
      'Quận Ninh Kiều',
      'Quận Bình Thủy',
      'Quận Cái Răng',
      'Quận Ô Môn',
      'Quận Thốt Nốt',
    ],
    'An Giang': ['TP. Long Xuyên', 'TP. Châu Đốc', 'Thị xã Tân Châu', 'Huyện Chợ Mới'],
    'Bà Rịa - Vũng Tàu': ['TP. Vũng Tàu', 'TP. Bà Rịa', 'Thị xã Phú Mỹ', 'Huyện Long Điền'],
    'Bắc Giang': ['TP. Bắc Giang', 'Thị xã Việt Yên', 'Huyện Hiệp Hòa', 'Huyện Lạng Giang'],
    'Bắc Kạn': ['TP. Bắc Kạn', 'Huyện Ba Bể', 'Huyện Chợ Đồn', 'Huyện Na Rì'],
    'Bạc Liêu': ['TP. Bạc Liêu', 'Thị xã Giá Rai', 'Huyện Hòa Bình', 'Huyện Vĩnh Lợi'],
    'Bắc Ninh': ['TP. Bắc Ninh', 'TP. Từ Sơn', 'Thị xã Quế Võ', 'Thị xã Thuận Thành', 'Huyện Yên Phong', 'Huyện Tiên Du'],
    'Bến Tre': ['TP. Bến Tre', 'Huyện Châu Thành', 'Huyện Ba Tri', 'Huyện Bình Đại'],
    'Bình Định': ['TP. Quy Nhơn', 'Thị xã An Nhơn', 'Thị xã Hoài Nhơn', 'Huyện Tuy Phước'],
    'Bình Dương': ['TP. Thủ Dầu Một', 'TP. Dĩ An', 'TP. Thuận An', 'TP. Tân Uyên', 'TP. Bến Cát'],
    'Bình Phước': ['TP. Đồng Xoài', 'Thị xã Bình Long', 'Thị xã Phước Long', 'Huyện Chơn Thành'],
    'Bình Thuận': ['TP. Phan Thiết', 'Thị xã La Gi', 'Huyện Hàm Thuận Bắc', 'Huyện Tuy Phong'],
    'Cà Mau': ['TP. Cà Mau', 'Huyện Năm Căn', 'Huyện Cái Nước', 'Huyện Đầm Dơi'],
    'Cao Bằng': ['TP. Cao Bằng', 'Huyện Trùng Khánh', 'Huyện Hòa An', 'Huyện Quảng Hòa'],
    'Đắk Lắk': ['TP. Buôn Ma Thuột', 'Thị xã Buôn Hồ', 'Huyện Ea Kar', 'Huyện Cư M\'gar'],
    'Đắk Nông': ['TP. Gia Nghĩa', 'Huyện Đắk Mil', 'Huyện Đắk R\'Lấp', 'Huyện Cư Jút'],
    'Điện Biên': ['TP. Điện Biên Phủ', 'Thị xã Mường Lay', 'Huyện Điện Biên', 'Huyện Tuần Giáo'],
    'Đồng Nai': ['TP. Biên Hòa', 'TP. Long Khánh', 'Huyện Long Thành', 'Huyện Nhơn Trạch', 'Huyện Trảng Bom'],
    'Đồng Tháp': ['TP. Cao Lãnh', 'TP. Sa Đéc', 'TP. Hồng Ngự', 'Huyện Lấp Vò'],
    'Gia Lai': ['TP. Pleiku', 'Thị xã An Khê', 'Thị xã Ayun Pa', 'Huyện Chư Sê'],
    'Hà Giang': ['TP. Hà Giang', 'Huyện Đồng Văn', 'Huyện Vị Xuyên', 'Huyện Bắc Quang'],
    'Hà Nam': ['TP. Phủ Lý', 'Thị xã Duy Tiên', 'Huyện Kim Bảng', 'Huyện Lý Nhân'],
    'Hà Tĩnh': ['TP. Hà Tĩnh', 'Thị xã Hồng Lĩnh', 'Thị xã Kỳ Anh', 'Huyện Nghi Xuân'],
    'Hải Dương': ['TP. Hải Dương', 'TP. Chí Linh', 'Thị xã Kinh Môn', 'Huyện Cẩm Giàng'],
    'Hậu Giang': ['TP. Vị Thanh', 'TP. Ngã Bảy', 'Thị xã Long Mỹ', 'Huyện Châu Thành'],
    'Hòa Bình': ['TP. Hòa Bình', 'Huyện Lương Sơn', 'Huyện Mai Châu', 'Huyện Kim Bôi'],
    'Hưng Yên': ['TP. Hưng Yên', 'Thị xã Mỹ Hào', 'Huyện Văn Giang', 'Huyện Văn Lâm'],
    'Khánh Hòa': ['TP. Nha Trang', 'TP. Cam Ranh', 'Thị xã Ninh Hòa', 'Huyện Diên Khánh'],
    'Kiên Giang': ['TP. Rạch Giá', 'TP. Phú Quốc', 'TP. Hà Tiên', 'Huyện Châu Thành'],
    'Kon Tum': ['TP. Kon Tum', 'Huyện Đắk Hà', 'Huyện Ngọc Hồi', 'Huyện Sa Thầy'],
    'Lai Châu': ['TP. Lai Châu', 'Huyện Phong Thổ', 'Huyện Tam Đường', 'Huyện Than Uyên'],
    'Lâm Đồng': ['TP. Đà Lạt', 'TP. Bảo Lộc', 'Huyện Đức Trọng', 'Huyện Di Linh'],
    'Lạng Sơn': ['TP. Lạng Sơn', 'Huyện Cao Lộc', 'Huyện Hữu Lũng', 'Huyện Chi Lăng'],
    'Lào Cai': ['TP. Lào Cai', 'Thị xã Sa Pa', 'Huyện Bảo Thắng', 'Huyện Bát Xát'],
    'Long An': ['TP. Tân An', 'Huyện Bến Lức', 'Huyện Đức Hòa', 'Huyện Cần Giuộc'],
    'Nam Định': ['TP. Nam Định', 'Huyện Hải Hậu', 'Huyện Giao Thủy', 'Huyện Xuân Trường'],
    'Nghệ An': ['TP. Vinh', 'Thị xã Cửa Lò', 'Thị xã Hoàng Mai', 'Huyện Diễn Châu', 'Huyện Quỳnh Lưu', 'Huyện Nam Đàn'],
    'Ninh Bình': ['TP. Ninh Bình', 'TP. Tam Điệp', 'Huyện Hoa Lư', 'Huyện Gia Viễn'],
    'Ninh Thuận': ['TP. Phan Rang - Tháp Chàm', 'Huyện Ninh Hải', 'Huyện Ninh Phước', 'Huyện Thuận Nam'],
    'Phú Thọ': ['TP. Việt Trì', 'Thị xã Phú Thọ', 'Huyện Lâm Thao', 'Huyện Phù Ninh'],
    'Phú Yên': ['TP. Tuy Hòa', 'Thị xã Sông Cầu', 'Thị xã Đông Hòa', 'Huyện Tuy An'],
    'Quảng Bình': ['TP. Đồng Hới', 'Thị xã Ba Đồn', 'Huyện Bố Trạch', 'Huyện Lệ Thủy'],
    'Quảng Nam': ['TP. Tam Kỳ', 'TP. Hội An', 'Thị xã Điện Bàn', 'Huyện Duy Xuyên'],
    'Quảng Ngãi': ['TP. Quảng Ngãi', 'Thị xã Đức Phổ', 'Huyện Bình Sơn', 'Huyện Sơn Tịnh'],
    'Quảng Ninh': ['TP. Hạ Long', 'TP. Cẩm Phả', 'TP. Uông Bí', 'TP. Móng Cái', 'Thị xã Quảng Yên'],
    'Quảng Trị': ['TP. Đông Hà', 'Thị xã Quảng Trị', 'Huyện Vĩnh Linh', 'Huyện Gio Linh'],
    'Sóc Trăng': ['TP. Sóc Trăng', 'Thị xã Vĩnh Châu', 'Thị xã Ngã Năm', 'Huyện Mỹ Xuyên'],
    'Sơn La': ['TP. Sơn La', 'Huyện Mộc Châu', 'Huyện Mai Sơn', 'Huyện Thuận Châu'],
    'Tây Ninh': ['TP. Tây Ninh', 'Thị xã Hòa Thành', 'Thị xã Trảng Bàng', 'Huyện Gò Dầu'],
    'Thái Bình': ['TP. Thái Bình', 'Huyện Đông Hưng', 'Huyện Hưng Hà', 'Huyện Kiến Xương'],
    'Thái Nguyên': ['TP. Thái Nguyên', 'TP. Sông Công', 'TP. Phổ Yên', 'Huyện Đại Từ'],
    'Thanh Hóa': ['TP. Thanh Hóa', 'TP. Sầm Sơn', 'Thị xã Bỉm Sơn', 'Thị xã Nghi Sơn', 'Huyện Hoằng Hóa', 'Huyện Quảng Xương', 'Huyện Đông Sơn', 'Huyện Thọ Xuân', 'Huyện Triệu Sơn'],
    'Thừa Thiên Huế': ['TP. Huế', 'Thị xã Hương Thủy', 'Thị xã Hương Trà', 'Huyện Phú Vang'],
    'Tiền Giang': ['TP. Mỹ Tho', 'TP. Gò Công', 'Thị xã Cai Lậy', 'Huyện Châu Thành'],
    'Trà Vinh': ['TP. Trà Vinh', 'Thị xã Duyên Hải', 'Huyện Càng Long', 'Huyện Tiểu Cần'],
    'Tuyên Quang': ['TP. Tuyên Quang', 'Huyện Sơn Dương', 'Huyện Yên Sơn', 'Huyện Chiêm Hóa'],
    'Vĩnh Long': ['TP. Vĩnh Long', 'Thị xã Bình Minh', 'Huyện Long Hồ', 'Huyện Tam Bình'],
    'Vĩnh Phúc': ['TP. Vĩnh Yên', 'TP. Phúc Yên', 'Huyện Bình Xuyên', 'Huyện Tam Đảo'],
    'Yên Bái': ['TP. Yên Bái', 'Thị xã Nghĩa Lộ', 'Huyện Yên Bình', 'Huyện Trấn Yên'],
  };

  late String _selectedProvince;
  late String _selectedDistrict;
  String? _customDistrictFallback;

  bool get _isEditing => widget.editingAddress != null;

  @override
  void initState() {
    super.initState();
    final controller = AddressController.instance;
    final editing = widget.editingAddress;

    if (editing != null) {
      controller.name.text = editing.name;
      controller.phoneNumber.text = editing.phoneNumber;
      controller.street.text = editing.street;
      controller.country.text = 'Việt Nam';
      if (editing.latitude != null && editing.longitude != null) {
        controller.location.value = LatLng(editing.latitude!, editing.longitude!);
      } else {
        controller.location.value = null;
      }

      // Resolve canonical province from saved city or state (handles older free-text addresses like "Ha Noi")
      final resolvedProvince =
          _vietnamLocations.containsKey(editing.city.trim())
              ? editing.city.trim()
              : (ShippingRouteHelper.resolveCanonicalProvince(editing.city) ??
                  ShippingRouteHelper.resolveCanonicalProvince(editing.state) ??
                  'Hà Nội');
      _selectedProvince = _vietnamLocations.containsKey(resolvedProvince)
          ? resolvedProvince
          : 'Hà Nội';

      final districts = _vietnamLocations[_selectedProvince]!;
      final savedDistrict = editing.state.trim();
      if (districts.contains(savedDistrict)) {
        _selectedDistrict = savedDistrict;
      } else if (savedDistrict.isNotEmpty &&
          savedDistrict.toLowerCase() != _selectedProvince.toLowerCase() &&
          ShippingRouteHelper.resolveCanonicalProvince(savedDistrict) != _selectedProvince) {
        _customDistrictFallback = savedDistrict;
        _selectedDistrict = savedDistrict;
      } else {
        _selectedDistrict = districts.first;
      }
    } else {
      controller.resetFormFields();
      _selectedProvince = 'Hà Nội';
      _selectedDistrict = _vietnamLocations[_selectedProvince]!.first;
    }

    controller.city.text = _selectedProvince;
    controller.state.text = _selectedDistrict;
    controller.country.text = 'Việt Nam';
  }

  List<String> _districtsFor(String province) {
    final base = _vietnamLocations[province] ?? const ['Trung tâm'];
    if (_customDistrictFallback != null &&
        _selectedProvince == province &&
        !base.contains(_customDistrictFallback)) {
      return [_customDistrictFallback!, ...base];
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AddressController.instance;
    final districts = _districtsFor(_selectedProvince);
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      appBar: TAppbar(
        showBackArrow: true,
        title: Text(
          _isEditing
              ? (isEn ? 'Edit address' : 'Chỉnh sửa địa chỉ')
              : (isEn ? 'Add new address' : 'Thêm địa chỉ mới'),
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: controller.addressFormKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _isEditing
                  ? (isEn ? 'Update delivery details.' : 'Cập nhật địa chỉ nhận hàng.')
                  : (isEn ? 'Ready for delivery.' : 'Sẵn sàng nhận đôi giày mới.'),
              style: const TextStyle(
                fontSize: 25,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isEditing
                  ? (isEn
                      ? 'Adjust recipient, province, district, or map pin anytime.'
                      : 'Bạn có thể chỉnh sửa người nhận, tỉnh/thành, quận/huyện hoặc vị trí ghim bản đồ.')
                  : (isEn
                      ? 'Add the details that help your pair reach you.'
                      : 'Chọn tỉnh/thành và nhập địa chỉ chi tiết để tính chính xác khoảng cách & ngày giao.'),
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 24),
            const ShopText(
              'Recipient',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _field(
              controller.name,
              isEn ? 'Full Name' : 'Họ và tên người nhận',
              Iconsax.user,
              autofill: AutofillHints.name,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.phoneNumber,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: TValidator.validatePhoneNumber,
              decoration: InputDecoration(
                prefixIcon: const Icon(Iconsax.mobile),
                labelText: isEn ? 'Phone Number' : 'Số điện thoại nhận hàng',
              ),
            ),
            const Divider(height: 40),
            const ShopText(
              'Delivery address',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // 1. Dropdown Tỉnh / Thành phố (đầy đủ 63 tỉnh thành Việt Nam)
            DropdownButtonFormField<String>(
              value: _selectedProvince,
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Iconsax.building),
                labelText: isEn ? 'Province / City' : 'Tỉnh / Thành phố',
              ),
              items: _vietnamLocations.keys
                  .map(
                    (prov) => DropdownMenuItem<String>(
                      value: prov,
                      child: Text(prov),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _selectedProvince = val;
                  _customDistrictFallback = null;
                  _selectedDistrict = _vietnamLocations[val]!.first;
                  controller.city.text = _selectedProvince;
                  controller.state.text = _selectedDistrict;
                  controller.country.text = 'Việt Nam';
                  // Reset old GPS pin if switching to a different province so distance uses the newly selected province accurately
                  controller.location.value = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // 2. Dropdown Quận / Huyện / Thị xã
            DropdownButtonFormField<String>(
              value: districts.contains(_selectedDistrict)
                  ? _selectedDistrict
                  : districts.first,
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Iconsax.location),
                labelText: isEn ? 'District' : 'Quận / Huyện / Thị xã',
              ),
              items: districts
                  .map(
                    (dist) => DropdownMenuItem<String>(
                      value: dist,
                      child: Text(dist),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _selectedDistrict = val;
                  controller.state.text = _selectedDistrict;
                });
              },
            ),
            const SizedBox(height: 12),

            // Live accurate distance & ETA from VELORA Hanoi Warehouse (reacts to Province, District & GPS Pin!)
            Obx(() {
              final pin = controller.location.value;
              final eta = ShippingRouteHelper.estimateForAddress(
                AddressModel(
                  id: 'preview',
                  name: '',
                  phoneNumber: '',
                  street: controller.street.text.trim(),
                  city: _selectedProvince,
                  state: _selectedDistrict,
                  country: 'Việt Nam',
                  latitude: pin?.latitude,
                  longitude: pin?.longitude,
                ),
              );
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFF7DD3FC)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Iconsax.truck_fast,
                        size: 18,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn
                                ? 'VELORA Hanoi Warehouse → $_selectedDistrict, $_selectedProvince'
                                : 'Tổng Kho Hà Nội → $_selectedDistrict, $_selectedProvince',
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0C4A6E),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isEn
                                ? 'Road distance: ~${eta.distanceKm} km${pin != null ? ' (GPS pin)' : ''} • Est. delivery: ${eta.minDays}–${eta.maxDays} days'
                                : 'Quãng đường: ~${eta.distanceKm} km${pin != null ? ' (theo ghim GPS)' : ''} • Dự kiến giao: ${eta.minDays}–${eta.maxDays} ngày (${eta.zoneName})',
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0369A1),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // 3. Địa chỉ chi tiết (Số nhà, tên đường, phường/xã)
            _field(
              controller.street,
              isEn
                  ? 'Detailed address (House no., street, ward)'
                  : 'Địa chỉ chi tiết (Số nhà, tên đường, phường/xã)',
              Iconsax.building_31,
              autofill: AutofillHints.streetAddressLine1,
            ),
            const SizedBox(height: 22),

            Obx(
              () => AddressMapPicker(
                value: controller.location.value,
                onChanged: (point) => controller.location.value = point,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: ElevatedButton(
          onPressed: () async {
            controller.city.text = _selectedProvince;
            controller.state.text = _selectedDistrict;
            controller.country.text = 'Việt Nam';
            final AddressModel? saved = _isEditing
                ? await controller.updateAddress(widget.editingAddress!)
                : await controller.addNewAddresses();
            if (saved != null && context.mounted) {
              Navigator.of(context).pop(saved);
              Future.delayed(const Duration(milliseconds: 120), () {
                TLoaders.successSnackBar(
                  title: isEn ? 'Success' : 'Thành công',
                  message: _isEditing
                      ? (isEn
                          ? 'Address updated successfully!'
                          : 'Đã cập nhật địa chỉ giao hàng thành công!')
                      : (isEn
                          ? 'New address added successfully!'
                          : 'Đã thêm địa chỉ giao hàng mới thành công!'),
                );
              });
            }
          },
          child: Text(
            _isEditing
                ? (isEn ? 'Update address' : 'Cập nhật địa chỉ')
                : (isEn ? 'Save address' : 'Lưu địa chỉ'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? autofill,
  }) =>
      TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        autofillHints: autofill == null ? null : [autofill],
        textInputAction: TextInputAction.next,
        validator: (value) => TValidator.validateEmptyText(label, value),
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
        ),
      );
}
