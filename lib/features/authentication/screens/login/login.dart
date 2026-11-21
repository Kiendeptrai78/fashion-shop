import 'package:fashion_business_app/admin/login/login_admin_screen.dart';
import 'package:fashion_business_app/utils/constants/admin_config.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _showAdminPortalOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cổng quản trị VELORA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Trang quản trị được thiết kế tối ưu cho Flutter Web (${AdminConfig.adminWebUrl}).',
                style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    final uri = Uri.parse(AdminConfig.adminWebUrl);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Mở trang Quản trị Web'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Get.to(() => const LoginAdminScreen());
                  },
                  child: const Text('Đăng nhập quản trị ngay trên thiết bị này'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('VELORA', style: TextStyle(fontSize: 14, letterSpacing: 3, fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary)),
      const SizedBox(height: 24),
      ClipRRect(borderRadius: BorderRadius.circular(18), child: AspectRatio(aspectRatio: 2.2,
          child: Image.asset('assets/images/banners/banner4.jpg', fit: BoxFit.cover))),
      const SizedBox(height: 28),
      const ShopText('Welcome back', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600,
          height: 1.2, letterSpacing: -1)),
      const SizedBox(height: 10),
      ShopText('Your favorites, your next pair, all in one place.', style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.7)),
      const TLoginForm(),
      Center(child: TextButton(onPressed: () => _showAdminPortalOptions(context),
          child: const ShopText('Staff access', style: TextStyle(fontSize: 12)))),
    ]),
  )));
}
