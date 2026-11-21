import 'package:flutter/material.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/features/shop/models/category_model.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class HomeEditorialHero extends StatelessWidget {
  const HomeEditorialHero({super.key, required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: ColoredBox(color: const Color(0xFFDDE5D9), child: Column(children: [
      Stack(children: [
        AspectRatio(aspectRatio: 1.5, child: Image.asset(
            'assets/images/banners/home-velora-editorial.png', fit: BoxFit.cover,
            alignment: Alignment.topCenter, excludeFromSemantics: true)),
        Positioned(top: 20, left: 20, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xF2F6F7F1), borderRadius: BorderRadius.circular(4)),
          child: const ShopText('THE VELORA EDIT', style: TextStyle(fontSize: 9,
              letterSpacing: 1.8, fontWeight: FontWeight.w700, color: Color(0xFF173E32))))),
      ]),
      Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 22), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          const ShopText('A pair.\nYour signature.', style: TextStyle(fontSize: 34,
              height: 1.05, letterSpacing: -1.4, fontWeight: FontWeight.w600, color: Color(0xFF173E32))),
          const SizedBox(height: 12),
          const ShopText('Find your everyday rotation.', style: TextStyle(fontSize: 12,
              height: 1.5, color: Color(0xFF4F6253))),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: onExplore, style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF173E32), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: ShopText('Explore the edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded, size: 19),
            ]),
          )),
        ],
      )),
    ])),
  );
}

class HomeCollections extends StatelessWidget {
  const HomeCollections({super.key, required this.categories, required this.onSelect});
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onSelect;

  @override
  Widget build(BuildContext context) => SizedBox(height: 176, child: ListView.separated(
    scrollDirection: Axis.horizontal, itemCount: categories.length,
    separatorBuilder: (_, __) => const SizedBox(width: 12),
    itemBuilder: (context, index) {
      final category = categories[index];
      final dark = Theme.of(context).brightness == Brightness.dark;
      return SizedBox(width: 146, child: Material(
        color: dark ? const Color(0xFF24352D) : const Color(0xFFF0F1EB),
        borderRadius: BorderRadius.circular(14), clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: () => onSelect(category), child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: TRoundedImage(imageUrl: category.image, isNetworkImage: true,
                  width: double.infinity, borderRadius: 0, padding: const EdgeInsets.all(4))),
              const SizedBox(height: 8),
              Row(children: [Expanded(child: ShopText(category.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                const Icon(Icons.north_east_rounded, size: 16)]),
            ],
          ),
        )),
      ));
    },
  ));
}
