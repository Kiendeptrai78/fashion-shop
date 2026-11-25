import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/shop/models/product_model.dart';
import 'features/shop/services/velora_gemini_assistant.dart';
import 'features/shop/services/velora_ai_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'features/shop/screens/assistant/velora_ai_chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  File('${Directory.systemTemp.path}/velora_ai_probe.txt').writeAsStringSync('AI_SMOKE_STAGE: start\n');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).timeout(const Duration(seconds: 25));
  report('AI_SMOKE_STAGE: firebase_ready');
  await FirebaseAppCheck.instance.activate(appleProvider: AppleProvider.debug).timeout(const Duration(seconds: 25));
  report('AI_SMOKE_STAGE: appcheck_activated');
  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('vi'), supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: const [GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    theme: ThemeData(useMaterial3: true, fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF173F35))),
    home: const VeloraAiChatScreen(),
  ));
  unawaited(probe());
}

Future<void> probe() async {
  try {
    report('AI_SMOKE_STAGE: requesting_appcheck_token');
    await FirebaseAppCheck.instance.getToken(true).timeout(const Duration(seconds: 25));
    report('AI_SMOKE_STAGE: appcheck_token_received');
    final snapshot = await FirebaseFirestore.instance.collection('Products').limit(40).get().timeout(const Duration(seconds: 25));
    final products = snapshot.docs.map(ProductModel.fromSnapshot).toList();
    report('AI_SMOKE_PUBLIC_PRODUCTS: ${products.length}');
    final assistant = VeloraGeminiAssistant();
    for (final question in ['Gợi ý giày chạy bộ dưới 3 triệu đồng', 'Đôi đầu có màu đen size 41 không?']) {
      final reply = await assistant.ask(question, language: 'vi', products: products);
      report('AI_SMOKE_REPLY: ${jsonEncode({'question': question, 'text': reply.text, 'productIds': reply.products.map((p) => p.id).toList()})}');
    }
    final reply = await VeloraAiService().ask('Giày chạy bộ dưới 3 triệu', language: 'vi');
    report('AI_SMOKE_SERVICE: ${jsonEncode({'text': reply.text, 'productIds': reply.products.map((p) => p.id).toList()})}');
    report('AI_SMOKE_COMPLETE');
  } catch (error) {
    report('AI_SMOKE_FAILURE: $error');
  }
}

void report(String message) {
  print(message);
  File('${Directory.systemTemp.path}/velora_ai_probe.txt').writeAsStringSync('$message\n', mode: FileMode.append);
}
