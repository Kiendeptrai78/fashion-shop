import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../models/product_model.dart';
import '../models/velora_ai_reply.dart';
import '../../../utils/localization/shop_locale.dart';

typedef VeloraAiGenerate = Future<String> Function(String instructions, List<Content> contents);

class VeloraGeminiAssistant {
  VeloraGeminiAssistant({VeloraAiGenerate? generate}) : _generate = generate ?? _generateWithFirebase;
  final VeloraAiGenerate _generate;
  final _history = <Content>[];
  List<String> _recentProductIds = const [];
  static Future<void>? _appCheck;
  static const modelName = String.fromEnvironment('VELORA_AI_MODEL', defaultValue: 'gemini-3.5-flash-lite');

  List<String> get recentProductIds => List.unmodifiable(_recentProductIds);

  void clearHistory() {
    _history.clear();
    _recentProductIds = const [];
  }

  static bool containsPersonalData(String text) =>
      RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}').hasMatch(text) ||
      RegExp(r'(?<!\d)(?:\+84|0)(?:[ .-]?\d){8,10}(?!\d)').hasMatch(text);

  static List<ProductModel> availableProducts(List<ProductModel> products) => products.where((p) =>
      !p.isDiscontinued && p.stock > 0 &&
      (p.productVariations?.isNotEmpty != true || p.productVariations!.any((v) => v.stock > 0))).toList();

  static Map<String, Object?> productContext(ProductModel p) {
    final price = p.salePrice > 0 && p.salePrice < p.price ? p.salePrice : p.price;
    return {
      'id': p.id, 'title': p.title, 'brand': p.brand?.name ?? '', 'category': p.categoryName,
      'description': (p.description ?? '').substring(0, (p.description ?? '').length.clamp(0, 800)),
      'stock': p.stock, 'priceUsd': price, 'priceVnd': (price * usdToVnd).round(),
      'availableOptions': (p.productVariations ?? []).where((v) => v.stock > 0).map((v) {
        final variantPrice = v.salePrice > 0 && (v.price <= 0 || v.salePrice < v.price)
            ? v.salePrice : v.price > 0 ? v.price : price;
        return {'attributes': v.attributeValues, 'stock': v.stock,
          'priceUsd': variantPrice, 'priceVnd': (variantPrice * usdToVnd).round()};
      }).toList(),
    };
  }

  Future<VeloraAiReply> ask(String query, {required String language,
      required List<ProductModel> products, bool catalogIsPartial = true}) async {
    if (containsPersonalData(query)) throw const FormatException('Personal data is not sent to AI.');
    final message = query.substring(0, query.length.clamp(0, 1500));
    final catalog = availableProducts(products).take(40).toList();
    final instructions = await rootBundle.loadString('assets/ai/velora_assistant.md');
    final request = Content.text(jsonEncode({
      'language': language == 'en' ? 'en' : 'vi', 'query': message,
      'catalogIsPartial': catalogIsPartial, 'catalogSnapshot': catalog.map(productContext).toList(),
    }));
    final raw = await _generate(instructions, [..._history, request]).timeout(const Duration(seconds: 30));
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) throw const FormatException('Invalid AI response.');
    final answer = decoded['answer'];
    final ids = decoded['productIds'];
    if (answer is! String || answer.trim().isEmpty || answer.length > 6000 || ids is! List ||
        ids.any((id) => id is! String || !catalog.any((p) => p.id == id))) {
      throw const FormatException('Ungrounded AI response.');
    }
    final picks = ids.cast<String>().toSet().take(3).map((id) => catalog.firstWhere((p) => p.id == id)).toList();
    final followUps = (decoded['followUps'] is List ? decoded['followUps'] as List : const [])
        .whereType<String>().where((s) => s.trim().isNotEmpty && s.length <= 120 && !containsPersonalData(s))
        .take(3).toList();
    final actions = (decoded['actions'] is List ? decoded['actions'] as List : const []).whereType<String>().toSet();
    _history.addAll([Content.text(message), Content.model([TextPart(raw)])]);
    if (picks.isNotEmpty) _recentProductIds = picks.map((p) => p.id).toList();
    if (_history.length > 6) _history.removeRange(0, _history.length - 6);
    return VeloraAiReply(text: answer.trim(), products: picks, followUpPrompts: followUps,
        showSupportChatShortcut: actions.contains('support'), showOrdersShortcut: actions.contains('orders'),
        showReturnsShortcut: actions.contains('returns'), showCartShortcut: actions.contains('cart'),
        showVoucherShortcut: actions.contains('vouchers'));
  }

  static Future<String> _generateWithFirebase(String instructions, List<Content> contents) async {
    if (kIsWeb) throw UnsupportedError('Web App Check must be configured before enabling web AI.');
    try {
      await (_appCheck ??= FirebaseAppCheck.instance.activate(
        appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      ));
    } catch (_) {
      _appCheck = null;
      rethrow;
    }
    final model = FirebaseAI.googleAI(appCheck: FirebaseAppCheck.instance).generativeModel(model: modelName,
      systemInstruction: Content.system(instructions),
      generationConfig: GenerationConfig(temperature: 0.3, maxOutputTokens: 2048,
        responseMimeType: 'application/json', responseSchema: Schema.object(properties: {
          'answer': Schema.string(), 'productIds': Schema.array(items: Schema.string(), maxItems: 3),
          'followUps': Schema.array(items: Schema.string(), maxItems: 3),
          'actions': Schema.array(items: Schema.enumString(enumValues: ['support','orders','returns','cart','vouchers'])),
        })),
    );
    final response = await model.generateContent(contents);
    if (response.text == null) throw const FormatException('No AI answer.');
    return response.text!;
  }
}
