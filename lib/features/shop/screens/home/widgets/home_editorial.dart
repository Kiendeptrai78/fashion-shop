import 'package:flutter/material.dart';
import 'package:fashion_business_app/common/widgets/images/rounded_image.dart';
import 'package:fashion_business_app/features/shop/models/category_model.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class HomeEditorialHero extends StatelessWidget {
  const HomeEditorialHero({super.key, required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3EBE0), Color(0xFFD5E1D2)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF173E32).withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.5,
                  child: Image.asset(
                    'assets/images/banners/home-velora-editorial.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    excludeFromSemantics: true,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.55, 1.0],
                        colors: [
                          Colors.transparent,
                          const Color(0xFFDDE5D9).withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF173E32).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 11, color: Color(0xFFDDEABB)),
                        SizedBox(width: 6),
                        ShopText(
                          'THE VELORA EDIT',
                          style: TextStyle(
                            fontSize: 9.5,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDDEABB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShopText(
                    'A pair.\nYour signature.',
                    style: TextStyle(
                      fontSize: 32,
                      height: 1.06,
                      letterSpacing: -1.2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF133329),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const ShopText(
                    'Find your everyday rotation.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF43594A),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onExplore,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF173E32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: ShopText(
                              'Explore the edit',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDEABB).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, size: 17, color: Color(0xFFDDEABB)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class HomeCollections extends StatelessWidget {
  const HomeCollections({super.key, required this.categories, required this.onSelect});
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onSelect;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 184,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final category = categories[index];
            final dark = Theme.of(context).brightness == Brightness.dark;
            return SizedBox(
              width: 152,
              child: Material(
                color: dark ? const Color(0xFF1D2D26) : const Color(0xFFF3F5F0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE4E8DF),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelect(category),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TRoundedImage(
                            imageUrl: category.image,
                            isNetworkImage: true,
                            width: double.infinity,
                            borderRadius: 10,
                            padding: const EdgeInsets.all(6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ShopText(
                                category.name,
                                softWrap: true,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: dark ? const Color(0xFF284136) : const Color(0xFFE3ECE6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.north_east_rounded,
                                size: 14,
                                color: dark ? const Color(0xFFDDEABB) : const Color(0xFF173E32),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}
