import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/product_model.dart';
import '../../../models/product_size_guide.dart';

class ProductSizeGuideSection extends StatelessWidget {
  const ProductSizeGuideSection({super.key, required this.product, this.selectedSize});
  final ProductModel product;
  final String? selectedSize;

  static String sizeKey(String size) => size.trim().toUpperCase().replaceFirst(RegExp(r'^EU\s*'), '').replaceAll(',', '.');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final configured = product.sizeGuide;
    final guide = configured != null && configured.rows.isNotEmpty ? configured : ProductSizeGuide.reference;
    final sizes = <String>{
      for (final attribute in product.productAttributes ?? [])
        if (attribute.name?.toLowerCase() == 'size') ...?attribute.values,
      for (final variation in product.productVariations ?? [])
        if (variation.attributeValues['Size']?.isNotEmpty == true) variation.attributeValues['Size']!,
    }.toList()..sort((a, b) {
      final x = double.tryParse(sizeKey(a)); final y = double.tryParse(sizeKey(b));
      return x != null && y != null ? x.compareTo(y) : a.compareTo(b);
    });
    if (sizes.isEmpty) sizes.addAll(guide.rows.map((row) => row.size));
    final rows = {for (final row in guide.rows) sizeKey(row.size): row.footLengthCm};
    final number = NumberFormat('0.##', isEn ? 'en_US' : 'vi_VN');
    final tint = Color.alphaBlend(colors.primary.withValues(alpha: 0.07), colors.surface);
    final body = theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface, fontSize: 13.5, height: 1.55);
    final steps = isEn ? const [
      'Stand on a sheet of paper on a firm, flat floor, wearing your usual socks.',
      'Mark your heel and longest toe, then measure the distance between them in centimetres.',
      'Measure both feet and use the longer measurement when comparing sizes.',
    ] : const [
      'Đứng lên tờ giấy trên sàn phẳng, mang loại tất bạn thường dùng khi đi giày.',
      'Đánh dấu gót và đầu ngón dài nhất, rồi đo khoảng cách giữa hai điểm bằng cm.',
      'Đo cả hai chân và lấy số đo chân dài hơn để đối chiếu bảng.',
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.straighten_rounded, color: colors.primary, size: 23),
        const SizedBox(width: 10),
        Expanded(child: Text(isEn ? 'Size guide' : 'Bảng size tham khảo',
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 19, fontWeight: FontWeight.w700,
            color: colors.onSurface))),
      ]),
      const SizedBox(height: 14),
            Text(guide.isReference ? (isEn ? 'General reference' : 'Bảng tham khảo chung')
                : (isEn ? 'Product size chart' : 'Bảng size riêng của mẫu'),
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.primary)),
            const SizedBox(height: 6),
            Text(guide.isReference
                ? (isEn ? 'This model does not have its own measurements yet. These approximate values are a general shop reference; fit varies by model.'
                    : 'Mẫu này chưa có số đo riêng. Các số đo dưới đây là tham khảo chung của shop; độ vừa có thể khác giữa các mẫu.')
                : (isEn ? 'Foot-length measurements supplied for this model.' : 'Số đo chiều dài chân được cung cấp riêng cho mẫu giày này.'),
              style: body),
            const SizedBox(height: 16),
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Table(
              columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth(1.5)},
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder(horizontalInside: BorderSide(color: theme.dividerColor.withValues(alpha: 0.18))),
              children: [
                TableRow(decoration: BoxDecoration(color: tint), children: [
                  Padding(padding: const EdgeInsets.all(12), child: Text(isEn ? 'EU size' : 'Size EU',
                    style: body?.copyWith(fontWeight: FontWeight.w700))),
                  Padding(padding: const EdgeInsets.all(12), child: Text(isEn ? 'Foot length (cm)' : 'Dài chân (cm)',
                    style: body?.copyWith(fontWeight: FontWeight.w700))),
                ]),
                for (final size in sizes)
                  TableRow(decoration: BoxDecoration(color: sizeKey(size) == sizeKey(selectedSize ?? '')
                      ? tint : colors.surface), children: [
                    Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                      Text(sizeKey(size), style: body?.copyWith(fontWeight: FontWeight.w700)),
                      if (sizeKey(size) == sizeKey(selectedSize ?? '')) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle_rounded, color: colors.primary, size: 18),
                      ],
                    ])),
                    Padding(padding: const EdgeInsets.all(12), child: Text(rows[sizeKey(size)] == null
                      ? (isEn ? 'Not provided' : 'Chưa có số đo') : number.format(rows[sizeKey(size)]), style: body)),
                  ]),
              ],
            )),
            if (sizes.isEmpty) ...[
              const SizedBox(height: 12),
              Text(isEn ? 'Size options have not been added for this product.' : 'Sản phẩm chưa có danh sách kích cỡ.', style: body),
            ],
            if (guide.fitNote.trim().isNotEmpty) ...[
              const SizedBox(height: 14), Text(guide.fitNote, style: body),
            ],
            if (guide.source.trim().isNotEmpty) ...[
              const SizedBox(height: 8), Text('${isEn ? 'Source' : 'Nguồn'}: ${guide.source}', style: body?.copyWith(fontSize: 12.5)),
            ],
            const SizedBox(height: 22),
            Text(isEn ? 'Measure your feet' : 'Cách đo chiều dài chân',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colors.onSurface)),
            const SizedBox(height: 12),
            for (final (index, text) in steps.indexed)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 26, height: 26, alignment: Alignment.center,
                    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(8)),
                    child: Text('${index + 1}', style: body?.copyWith(fontWeight: FontWeight.w700, color: colors.primary))),
                  const SizedBox(width: 10), Expanded(child: Text(text, style: body)),
                ])),
            Text(isEn ? 'These are foot-length measurements, not outsole measurements. If you are between sizes or have wide feet, contact VELORA to check this model’s fit.'
                : 'Đây là chiều dài chân, không phải chiều dài đế giày. Nếu số đo nằm giữa hai size hoặc chân bè, hãy nhờ VELORA tư vấn form của mẫu này.', style: body),
    ]);
  }
}
