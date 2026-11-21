import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'shop_translations.dart';

const usdToVnd = 25812.0;

String formatShopMoney(num usd, {String? language}) {
  final code = language ?? Get.locale?.languageCode ?? 'vi';
  if (code == 'vi') {
    return '${NumberFormat('#,##0', 'vi_VN').format((usd * usdToVnd).round())} ₫';
  }
  return NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2).format(usd);
}

String formatShopPrice(String price, {String? language}) => price.split(' - ')
    .map((part) => formatShopMoney(num.tryParse(part.trim()) ?? 0, language: language)).join(' – ');

class ShopLocale extends GetxController {
  ShopLocale(this.storage);
  final GetStorage storage;
  String get language => storage.read<String>('language') == 'en' ? 'en' : 'vi';

  Future<void> change(String code) async {
    await storage.write('language', code == 'en' ? 'en' : 'vi');
    await Get.updateLocale(Locale(language));
  }
}

/// The inherited locale keeps even const labels up to date after a language change.
class ShopText extends StatelessWidget {
  const ShopText(this.data, {super.key, this.style, this.textAlign, this.maxLines,
    this.overflow, this.softWrap, this.textDirection, this.semanticsLabel,
    this.textWidthBasis, this.textHeightBehavior, this.strutStyle, this.textScaleFactor});
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextDirection? textDirection;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final StrutStyle? strutStyle;
  final double? textScaleFactor;

  @override
  Widget build(BuildContext context) => Text(
    shopTranslate(data, language: Localizations.localeOf(context).languageCode),
    style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow,
    softWrap: softWrap, textDirection: textDirection, semanticsLabel: semanticsLabel,
    textWidthBasis: textWidthBasis, textHeightBehavior: textHeightBehavior,
    strutStyle: strutStyle, textScaleFactor: textScaleFactor,
  );
}
