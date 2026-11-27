import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/data/repositories/products/product_reposotory.dart';
import 'package:fashion_business_app/features/shop/models/catalog_query.dart';
import 'package:fashion_business_app/features/personalization/models_shopper_preferences.dart';
import 'package:fashion_business_app/navigation_menu.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class ShopperOnboarding extends StatefulWidget {
  const ShopperOnboarding({super.key, this.editing = false});
  final bool editing;

  @override
  State<ShopperOnboarding> createState() => _ShopperOnboardingState();
}

class _ShopperOnboardingState extends State<ShopperOnboarding> {
  late int _step;
  late String _age;
  late Set<String> _categories;
  late Future<CatalogFacets> _facets;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final saved = ShopperPreferences.load();
    _step = widget.editing ? 1 : 0;
    _age = saved.ageGroup;
    _categories = saved.categoryIds.toSet();
    _facets = ProductRepository.instance.fetchCatalogFacets();
  }

  Future<void> _finish({bool skip = false}) async {
    setState(() { _saving = true; _error = null; });
    try {
      final selectedCategories = skip ? <String>[] : _categories.toList();
      await ShopperPreferences(completed: true, ageGroup: skip ? 'unspecified' : _age,
          categoryIds: selectedCategories).save();
      await AccountActivity.current?.syncFavoriteCategories(selectedCategories);
      await AccountActivity.current?.syncPush();
      if (!mounted) return;
      if (widget.editing) { Get.back(); } else { Get.offAll(() => const NavigationMenu()); }
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Couldn’t save. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return PopScope(canPop: widget.editing, child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TAppbar(
        showBackArrow: widget.editing,
        leading: _step > (widget.editing ? 1 : 0)
            ? ShopGlassBackButton(
                tooltip: 'Back'.tr,
                onPressed: _saving ? null : () => setState(() => _step--),
              )
            : null,
        title: const ShopText('Make it yours', style: shopAppbarTitleStyle),
        actions: [
          if (!widget.editing)
            ShopGlassPillButton(
              height: 36,
              onTap: _saving ? null : () => _finish(skip: true),
              child: const ShopText(
                'Skip for now',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: SafeArea(top: false, child: ShopScrollUnderHeader(
        header: Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(children: [for (var i = 0; i < 3; i++) Expanded(child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(right: 6), height: 3,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
                color: i <= _step ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.15)),
          ))])),
        body: Column(children: [
        Expanded(child: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 320),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation,
              child: SlideTransition(position: Tween(begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(animation), child: child)),
          child: SingleChildScrollView(key: ValueKey(_step),
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: _step == 0 ? _intro(theme) : _step == 1 ? _ageStep(theme) : _categoryStep(theme),
          ),
        )),
        Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 16), child: Column(children: [
          if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12),
              child: ShopText(_error!, style: TextStyle(color: theme.colorScheme.error))),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : () {
            if (_step < 2) { setState(() => _step++); } else { _finish(); }
          }, child: _saving ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
              : ShopText(_step == 0 ? 'Make it yours' : _step == 2 ? 'Save my preferences' : 'Continue'))),
          const SizedBox(height: 12),
          ShopText('Saved on this device only. You’re in control.', textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall),
        ]))]),
      )),
    ));
  }

  Widget _heading(String title, String subtitle, ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      ShopText(title, style: const TextStyle(fontSize: 30, height: 1.2,
          fontWeight: FontWeight.w600, letterSpacing: -1)),
      const SizedBox(height: 14),
      ShopText(subtitle, style: theme.textTheme.bodyMedium?.copyWith(height: 1.7)),
      const SizedBox(height: 28),
    ],
  );

  Widget _intro(ThemeData theme) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    ClipRRect(borderRadius: BorderRadius.circular(20), child: AspectRatio(aspectRatio: 1.3,
        child: Image.asset('assets/images/banners/banner4.jpg', fit: BoxFit.cover))),
    const SizedBox(height: 28),
    _heading('A pair for every version of you.',
        'Find your everyday favorites, your next running partner, and everything in between.', theme),
  ]);

  Widget _ageStep(ThemeData theme) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _heading('Tell us a little about you.', 'Choose your age group. This is optional.', theme),
    for (final entry in ageGroups.entries) Padding(padding: const EdgeInsets.only(bottom: 10),
      child: Material(color: _age == entry.key ? theme.colorScheme.primary.withValues(alpha: 0.07)
          : theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12),
        child: RadioListTile<String>(value: entry.key, groupValue: _age,
          title: ShopText(entry.value), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _age == entry.key ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.15))),
          onChanged: (value) => setState(() => _age = value!),
        ))),
  ]);

  Widget _categoryStep(ThemeData theme) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _heading('What moves you?', 'Pick the collections you love. You can change this later in Settings.', theme),
    FutureBuilder<CatalogFacets>(future: _facets, builder: (context, snapshot) {
      if (snapshot.hasError) return Column(children: [
        const ShopText('Couldn’t load collections.'),
        TextButton(onPressed: () => setState(() { _facets = ProductRepository.instance.fetchCatalogFacets(); }),
            child: const ShopText('Retry')),
      ]);
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      return Column(children: [for (final category in snapshot.data!.categories)
        Padding(padding: const EdgeInsets.only(bottom: 12), child: CheckboxListTile(
          value: _categories.contains(category.id),
          onChanged: (selected) => setState(() {
            if (selected == true) { _categories.add(category.id); } else { _categories.remove(category.id); }
          }),
          secondary: Icon(Iconsax.tag, color: theme.colorScheme.primary),
          title: ShopText(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _categories.contains(category.id) ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.15))),
        )),
      ]);
    }),
  ]);
}
