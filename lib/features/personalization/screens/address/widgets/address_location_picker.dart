import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;

class AddressLocationPicker extends StatelessWidget {
  const AddressLocationPicker({super.key, required this.label, required this.value,
    required this.items, required this.icon, required this.onChanged});
  final String label, value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;

  Future<void> _choose(BuildContext context) async {
    var query = '';
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final selected = await showShopBottomSheet<String>(context: context,
      isScrollControlled: true, useSafeArea: true,
      builder: (sheet) => StatefulBuilder(builder: (context, update) {
        final filtered = items.where((item) => item.toLowerCase().contains(query.toLowerCase())).toList();
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 16),
          child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.65,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(label, style: shopAppbarTitleStyle)),
                ShopGlassIconButton(icon: CupertinoIcons.xmark,
                  tooltip: isEn ? 'Close' : 'Đóng', onPressed: () => Navigator.pop(sheet)),
              ]),
              const SizedBox(height: 12),
              TextField(onChanged: (text) => update(() => query = text),
                decoration: InputDecoration(hintText: isEn ? 'Search by name' : 'Tìm theo tên',
                  prefixIcon: const Icon(CupertinoIcons.search))),
              const SizedBox(height: 8),
              Expanded(child: filtered.isEmpty
                  ? Center(child: Text(isEn ? 'No matching locations' : 'Không tìm thấy địa điểm'))
                  : ListView.builder(itemCount: filtered.length, itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(item),
                      trailing: item == value ? const Icon(CupertinoIcons.check_mark,
                        color: Color(0xFF173E32), size: 20) : null,
                      onTap: () => Navigator.pop(sheet, item));
                  })),
            ])),
        );
      }));
    if (context.mounted && selected != null && selected != value) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    child: GlassPicker(value: value, semanticLabel: label, height: 36, useOwnLayer: true,
        quality: GlassQuality.standard,
        settings: shopToolbarGlassSettings(context).copyWith(glassColor: Colors.transparent, blur: 0),
        shape: const LiquidRoundedSuperellipse(borderRadius: 16),
        textStyle: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 14, fontWeight: FontWeight.w600),
        icon: const Icon(CupertinoIcons.chevron_down, size: 16), onTap: () => _choose(context)),
  );
}
