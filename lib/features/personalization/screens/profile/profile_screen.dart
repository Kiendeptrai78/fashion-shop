import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/images/circular_image.dart';
import 'package:fashion_business_app/common/widgets/shimmer/shimmer.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'widgets/change_name.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const TAppbar(showBackArrow: true, title: ShopText('Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
      body: Obx(() {
        final user = controller.user.value;
        return ListView(padding: const EdgeInsets.all(24), children: [
          Center(child: controller.imageUploading.value ? const TShimmerEffect(width: 88, height: 88, radius: 44)
              : TCircularImage(image: user.profilePicture.isEmpty ? TImages.user : user.profilePicture,
                  width: 88, height: 88, fit: BoxFit.cover, isNetworkImage: user.profilePicture.isNotEmpty)),
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: controller.uploadUserProfilePicture,
              child: const ShopText('Change Profile Picture'))),
          const SizedBox(height: 28),
          const ShopText('Profile Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          ListTile(contentPadding: EdgeInsets.zero, title: const ShopText('Name'),
            subtitle: Text(user.fullName.trim().isEmpty ? '—' : user.fullName),
            trailing: const Icon(Icons.edit_outlined, size: 20),
            onTap: () async { await Get.to(() => const ChangeName()); controller.user.refresh(); }),
          _info('Username', user.username),
          const Divider(height: 36),
          const ShopText('Contact Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          _info('Email', user.email), _info('Phone Number', user.phoneNumber),
          const Divider(height: 36),
          ListTile(contentPadding: EdgeInsets.zero, title: const ShopText('Account reference'),
            subtitle: Text(user.id, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
            trailing: const Icon(Icons.copy_outlined, size: 20),
            onTap: user.id.isEmpty ? null : () async {
              await Clipboard.setData(ClipboardData(text: user.id));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: ShopText('Account reference copied.')));
            }),
          const SizedBox(height: 24),
          TextButton(onPressed: controller.deleteAccountWarningPopup,
              child: ShopText('Close Account', style: TextStyle(color: theme.colorScheme.error))),
        ]);
      }),
    );
  }

  Widget _info(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ShopText(label, style: const TextStyle(fontSize: 12)), const SizedBox(height: 8),
        SelectableText(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ]));
}
