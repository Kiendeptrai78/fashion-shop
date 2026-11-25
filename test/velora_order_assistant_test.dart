import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/features/shop/models/cart_item_model.dart';
import 'package:fashion_business_app/features/shop/models/order_model.dart';
import 'package:fashion_business_app/features/shop/services/velora_ai_service.dart';
import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

OrderModel order(String id, int day, {OrderStatus status = OrderStatus.received}) => OrderModel(
  id: id, orderDate: DateTime(2026, 11, day, 10, 30), deliveryDate: DateTime(2026, 11, day + 1),
  status: status, totalAmount: 128.5, discountAmount: 10, couponCode: 'WELCOME10',
  paymentMethod: 'Cash on delivery', address: AddressModel(id: 'address', name: 'Customer',
    phoneNumber: '0900000000', street: '12 Duy Tân', state: 'Cầu Giấy', city: 'Hà Nội', country: 'Việt Nam'),
  items: [CartItemModel(productId: id, title: 'Sneaker $id', price: 90, quantity: 2,
    selectedVariation: {'Color': 'Sage', 'Size': '41'})],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the reported request returns exactly the newest saved order and its details', () async {
    var calls = 0;
    final records = [order('OLD-ORDER', 20), order('LATEST-ORDER', 25),
      order('PENDING-ORDER', 24, status: OrderStatus.pending)];
    final service = VeloraAiService(loadUserOrders: () async { calls++; return records; });
    final reply = await service.ask('gửi thông tin đơn hàng gần nhất giúp tôi');
    expect(calls, 1);
    expect(reply.text, contains('Đơn hàng gần nhất của bạn'));
    expect(reply.text, contains('LATEST-ORDER'));
    expect(reply.text, isNot(contains('OLD-ORDER')));
    expect(reply.text, isNot(contains('PENDING-ORDER')));
    expect(reply.text, contains('25/11/2026 10:30'));
    expect(reply.text, contains('Giao thành công'));
    expect(reply.text, contains('Sneaker LATEST-ORDER'));
    expect(reply.text, contains('×2'));
    expect(reply.text, contains('Sage'));
    expect(reply.text, contains('41'));
    expect(reply.text, contains('WELCOME10'));
    expect(reply.text, contains('12 Duy Tân'));
    expect(reply.text, contains(formatShopMoney(128.5, language: 'vi')));
    expect(reply.text, isNot(contains('Lộ trình:')));
    expect(reply.products, isEmpty);
    expect(reply.showOrdersShortcut, isTrue);
    expect(records.first.id, 'OLD-ORDER');
  });

  test('latest-order wording works with accents, shorthand, whitespace, and English', () async {
    final service = VeloraAiService(loadUserOrders: () async => [order('OLDER', 20), order('LATEST', 25)]);
    for (final query in ['Cho tôi xem đơn mới nhất', 'gui thong tin don gan nhat giup toi',
      'Đơn vừa đặt của tôi', 'Thông tin ĐƠN   HÀNG gần nhất',
      'Please send information about my most recent order', 'Where is my current order?']) {
      expect(VeloraAiService.handlesLocally(query), isTrue, reason: query);
      final reply = await service.ask(query, language: query.startsWith('Please') || query.startsWith('Where') ? 'en' : 'vi');
      expect(reply.text, contains('LATEST'), reason: query);
      expect(reply.text, isNot(contains('OLDER')), reason: query);
    }
  });

  test('a cancelled newest order is not replaced by an older active order', () async {
    final service = VeloraAiService(loadUserOrders: () async => [
      order('OLD-PENDING', 20, status: OrderStatus.pending),
      order('LATEST-CANCELLED', 25, status: OrderStatus.cancelled),
    ]);
    final reply = await service.ask('Đơn hàng mới nhất của tôi');
    expect(reply.text, contains('LATEST-CANCELLED'));
    expect(reply.text, contains('Đã hủy đơn'));
    expect(reply.text, isNot(contains('OLD-PENDING')));
  });

  test('English latest-order details use English labels, status and USD', () async {
    final service = VeloraAiService(loadUserOrders: () async => [order('LATEST', 25)]);
    final reply = await service.ask('Send my latest order details', language: 'en');
    expect(reply.text, contains('Your most recent order'));
    expect(reply.text, contains('Delivered'));
    expect(reply.text, contains('Order total: \$128.50'));
    expect(reply.text, isNot(contains('Trạng thái')));
  });

  test('an order request containing contact details stays local instead of being blocked as an AI prompt', () async {
    final service = VeloraAiService(loadUserOrders: () async => [order('MY-ORDER', 25)]);
    final reply = await service.ask('Đơn hàng gần nhất của tôi, số điện thoại 0901234567');
    expect(reply.text, contains('MY-ORDER'));
    expect(reply.text, isNot(contains('Bạn không cần gửi thông tin cá nhân')));
    expect(reply.products, isEmpty);
  });

  test('order read failures are explicit and never become empty-order claims or cancellation advice', () async {
    final service = VeloraAiService(loadUserOrders: () async => throw StateError('offline'));
    final reply = await service.ask('Gửi thông tin đơn hàng gần nhất');
    expect(reply.text, contains('chưa đọc được dữ liệu đơn hàng'));
    expect(reply.text, isNot(contains('chưa có đơn hàng')));
    expect(reply.text, isNot(contains('hủy')));
    expect(reply.products, isEmpty);
  });

  test('signed-out and empty accounts get distinct accurate answers', () async {
    final signedOut = await VeloraAiService(loadUserOrders: () async => null).ask('Đơn gần nhất');
    expect(signedOut.text, contains('cần đăng nhập'));
    final empty = await VeloraAiService(loadUserOrders: () async => []).ask('Đơn gần nhất');
    expect(empty.text, contains('chưa có đơn hàng'));
    expect(empty.products, isEmpty);
  });

  test('all-orders requests keep a clear recent-order list instead of pretending it is a single order', () async {
    final service = VeloraAiService(loadUserOrders: () async => [order('OLD', 20), order('NEW', 25)]);
    final reply = await service.ask('Xem tất cả đơn hàng của tôi');
    expect(reply.text, contains('2 đơn hàng gần nhất'));
    expect(reply.text, contains('NEW'));
    expect(reply.text, contains('OLD'));
    expect(reply.text.indexOf('NEW'), lessThan(reply.text.indexOf('OLD')));
  });

  test('return requests mentioning an order still reach the returns handler', () async {
    var orderReads = 0;
    final service = VeloraAiService(loadUserOrders: () async { orderReads++; return [order('NEW', 25)]; });
    final reply = await service.ask('Tôi muốn đổi trả đơn hàng gần nhất');
    expect(orderReads, 0);
    expect(reply.showReturnsShortcut, isTrue);
  });
}
