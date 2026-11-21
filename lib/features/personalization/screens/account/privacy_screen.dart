import 'package:fashion_business_app/features/personalization/services/account_activity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/features/personalization/models_shopper_preferences.dart';
import 'package:fashion_business_app/features/personalization/screens/preferences/shopper_onboarding.dart';
import 'package:fashion_business_app/features/personalization/screens/profile/profile_screen.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
      title: const ShopText('Clear local preferences?'),
      content: const ShopText('This removes your age group and interests from this device. Your account, orders and bag stay available.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: const ShopText('Cancel')),
        TextButton(onPressed: () => Navigator.pop(dialog, true), child: const ShopText('Clear preferences'))],
    ));
    if (confirmed != true) return;
    try {
      // Keep completion so deleting preferences does not immediately ask for them again.
      await const ShopperPreferences(completed: true).save();
      await AccountActivity.current?.syncPush();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: ShopText('Local preferences cleared.')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: ShopText('Couldn’t save. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const TAppbar(showBackArrow: true, title: ShopText('Account Privacy',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      Icon(Iconsax.shield_tick, size: 56, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 24),
      const ShopText('Your choices. Your control.', style: TextStyle(fontSize: 28,
          height: 1.2, fontWeight: FontWeight.w600, letterSpacing: -0.8)),
      const SizedBox(height: 14),
      const ShopText('Manage the information you share and the preferences saved on this device.', style: TextStyle(height: 1.7)),
      const SizedBox(height: 28),
      const ShopText('On this device', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      const ShopText('Age stays on this device. Followed collections are synced only when you enable push notifications.', style: TextStyle(height: 1.7)),
      const SizedBox(height: 16),
      ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Iconsax.setting_4),
        title: const ShopText('Your preferences'), trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.to(() => const ShopperOnboarding(editing: true))),
      ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Iconsax.eraser_1),
        title: const ShopText('Clear preferences'), trailing: const Icon(Icons.chevron_right), onTap: () => _clear(context)),
      const Divider(height: 36),
      const ShopText('Account and purchases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      const ShopText('Your profile, delivery addresses and orders are saved to your account so you can use them when shopping.',
          style: TextStyle(height: 1.7)),
      const SizedBox(height: 16),
      ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Iconsax.user_edit),
        title: const ShopText('Manage account'), trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.to(() => const ProfileScreen())),
      const Divider(height: 36),
      const ShopText('Demo payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      const ShopText('Demo banking does not ask for real bank details. Its balance and transactions are stored only on this device.',
          style: TextStyle(height: 1.7)),
    ]),
  );
}
