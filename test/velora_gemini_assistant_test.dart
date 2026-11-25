import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_business_app/features/shop/models/product_model.dart';
import 'package:fashion_business_app/features/shop/models/product_variation_model.dart';
import 'package:fashion_business_app/features/shop/services/velora_ai_service.dart';
import 'package:fashion_business_app/features/shop/services/velora_gemini_assistant.dart';

ProductModel shoe(String id, {int stock = 3, bool discontinued = false}) => ProductModel(
  id: id, title: 'VELORA $id', stock: stock, price: 100, salePrice: 80,
  thumbnail: '', productType: 'ProductType.variable', isFeatured: false,
  isDiscontinued: discontinued,
);

String response({List<String> ids = const ['shoe']}) => jsonEncode({
  'answer': '**VELORA** phù hợp ngân sách của bạn.', 'productIds': ids,
  'followUps': ['Bạn thích màu nào?'], 'actions': ['cart'],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads Markdown rules and sends only live catalog options with shop currency', () async {
    final product = shoe('shoe')..productVariations = [
      ProductVariationModel(id: 'yes', stock: 2, attributeValues: {'Color': 'White', 'Size': '40'}),
      ProductVariationModel(id: 'no', stock: 0, attributeValues: {'Color': 'Black', 'Size': '41'}),
    ];
    final assistant = VeloraGeminiAssistant(generate: (instructions, contents) async {
      expect(instructions, contains('# VELORA'));
      expect(instructions, contains('Không tự tạo giá'));
      final request = jsonDecode((contents.last.parts.single as TextPart).text);
      expect(request['language'], 'vi');
      expect(request['catalogIsPartial'], isTrue);
      final catalog = request['catalogSnapshot'] as List;
      expect(catalog, hasLength(1));
      expect(catalog.single['priceUsd'], 80);
      expect(catalog.single['priceVnd'], 2064960);
      expect(catalog.single['availableOptions'], hasLength(1));
      expect(catalog.single['availableOptions'][0]['attributes']['Size'], '40');
      expect(catalog.single['availableOptions'][0]['stock'], 2);
      expect(catalog.single['availableOptions'][0]['priceVnd'], 2064960);
      expect(request.keys, isNot(contains('orders')));
      return response();
    });
    final reply = await assistant.ask('Giày trắng dưới 3 triệu', language: 'vi',
      products: [product, shoe('sold-out', stock: 0), shoe('removed', discontinued: true)]);
    expect(reply.products.single.id, 'shoe');
    expect(reply.text, contains('**VELORA**'));
    expect(reply.showCartShortcut, isTrue);
  });

  test('rejects a fabricated product ID instead of rendering a fake recommendation', () async {
    final assistant = VeloraGeminiAssistant(generate: (_, __) async => response(ids: ['invented']));
    await expectLater(assistant.ask('Tư vấn giày', language: 'vi', products: [shoe('shoe')]),
      throwsFormatException);
  });

  test('rejects malformed and empty model answers', () async {
    for (final raw in ['not json', '{"answer":"", "productIds":[]}']) {
      final assistant = VeloraGeminiAssistant(generate: (_, __) async => raw);
      await expectLater(assistant.ask('Tư vấn giày', language: 'vi', products: []),
        throwsFormatException);
    }
  });

  test('blocks contact details before calling the external provider', () async {
    var calls = 0;
    final assistant = VeloraGeminiAssistant(generate: (_, __) async {
      calls++;
      return response();
    });
    for (final message in ['Email tôi test@example.com', 'Gọi tôi 0901234567']) {
      await expectLater(assistant.ask(message, language: 'vi', products: []), throwsFormatException);
    }
    expect(calls, 0);
    expect(VeloraGeminiAssistant.containsPersonalData('Giày dưới 2500000 đồng'), isFalse);
  });

  test('keeps three conversation turns and supports clearing account context', () async {
    final lengths = <int>[];
    final assistant = VeloraGeminiAssistant(generate: (_, contents) async {
      lengths.add(contents.length);
      return response();
    });
    for (var i = 0; i < 5; i++) {
      await assistant.ask('Giày màu $i', language: 'en', products: [shoe('shoe')]);
    }
    expect(lengths, [1, 3, 5, 7, 7]);
    expect(assistant.recentProductIds, ['shoe']);
    assistant.clearHistory();
    expect(assistant.recentProductIds, isEmpty);
    await assistant.ask('Giày trắng', language: 'vi', products: [shoe('shoe')]);
    expect(lengths.last, 1);
  });

  test('private account actions use the local service', () {
    for (final query in ['Đơn hàng của tôi', 'Giỏ hàng', 'Thanh toán ngân hàng',
      'Tôi muốn đổi size', 'My order', 'Mã giảm giá']) {
      expect(VeloraAiService.handlesLocally(query), isTrue, reason: query);
    }
    expect(VeloraAiService.handlesLocally('Giày chạy bộ dưới 2 triệu'), isFalse);
  });

  test('empty catalog permits an honest answer without product cards', () async {
    final assistant = VeloraGeminiAssistant(generate: (_, __) async => response(ids: []));
    final reply = await assistant.ask('Có giày xanh không?', language: 'vi', products: []);
    expect(reply.products, isEmpty);
  });
}
