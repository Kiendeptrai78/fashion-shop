import 'package:fashion_business_app/common/widgets/glass/shop_overlays.dart';
import 'package:fashion_business_app/common/widgets/appbar/appbar.dart';
import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/common/widgets/images/circular_image.dart';
import 'package:fashion_business_app/common/widgets/loaders/loader.dart';
import 'package:fashion_business_app/common/widgets/shimmer/shimmer.dart';
import 'package:fashion_business_app/data/repositories/users/user_repository.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';
import 'package:fashion_business_app/utils/validators/validation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'widgets/change_name.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editPhoneNumber(BuildContext context, UserController controller) async {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    var phoneNumber = controller.user.value.phoneNumber;
    final formKey = GlobalKey<FormState>();
    var saving = false;

    await showShopBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Update phone number' : 'Cập nhật số điện thoại',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  isEn
                      ? 'Used for delivery coordination and order support.'
                      : 'Dùng để shipper liên hệ giao hàng và hỗ trợ đổi trả nhanh chóng.',
                  style: TextStyle(fontSize: 12.5, color: Theme.of(ctx).hintColor),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: phoneNumber,
                  onChanged: (value) => phoneNumber = value,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  validator: TValidator.validatePhoneNumber,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Iconsax.mobile),
                    labelText: isEn ? 'Phone Number' : 'Số điện thoại',
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF173E32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => saving = true);
                            try {
                              final next = phoneNumber.trim();
                              await UserRepository.instance
                                  .updateSingleField({'PhoneNumber': next});
                              controller.user.value.phoneNumber = next;
                              controller.user.refresh();
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              Future.delayed(const Duration(milliseconds: 120), () {
                                TLoaders.successSnackBar(
                                  title: isEn ? 'Success' : 'Thành công',
                                  message: isEn
                                      ? 'Phone number updated successfully!'
                                      : 'Đã cập nhật số điện thoại thành công!',
                                );
                              });
                            } catch (e) {
                              setModalState(() => saving = false);
                              TLoaders.errorSnackBar(
                                title: isEn ? 'Error' : 'Lỗi',
                                message: e.toString(),
                              );
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEn ? 'Save phone number' : 'Lưu số điện thoại',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final cardColor = dark ? const Color(0xFF19251F) : Colors.white;
    final borderColor =
        dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE4EAE4);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
      extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: TAppbar(
          showBackArrow: true,
          title: Text(isEn ? 'Edit Profile' : 'Hồ sơ cá nhân', style: shopAppbarTitleStyle),
        ),
        body: Obx(() {
          final user = controller.user.value;
          final displayName = user.fullName.trim().isEmpty
              ? (isEn ? 'VELORA Customer' : 'Khách hàng VELORA')
              : user.fullName.trim();

          return SingleChildScrollView(
        padding: shopAppbarContentPadding(context),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // 1. Luxury Dark-Emerald Profile Hero Banner
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0C231C),
                        Color(0xFF163D31),
                        Color(0xFF215243),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 16, 26),
                      child: Column(
                        children: [
                          // Avatar + floating camera button
                          GestureDetector(
                            onTap: controller.uploadUserProfilePicture,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3.5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFDDEABB),
                                      width: 2.2,
                                    ),
                                  ),
                                  child: controller.imageUploading.value
                                      ? const TShimmerEffect(
                                          width: 92,
                                          height: 92,
                                          radius: 46,
                                        )
                                      : TCircularImage(
                                          image: user.profilePicture.isEmpty
                                              ? TImages.user
                                              : user.profilePicture,
                                          width: 92,
                                          height: 92,
                                          padding: 0,
                                          fit: BoxFit.cover,
                                          isNetworkImage:
                                              user.profilePicture.isNotEmpty,
                                        ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDDEABB),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF163D31),
                                        width: 2.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Iconsax.camera,
                                      size: 16,
                                      color: Color(0xFF102B23),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            displayName,
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: controller.uploadUserProfilePicture,
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.12),
                              foregroundColor: const Color(0xFFDDEABB),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            icon: const Icon(Iconsax.gallery_edit, size: 15),
                            label: Text(
                              isEn ? 'Change photo' : 'Đổi ảnh đại diện',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Clean Grouped Profile Form Cards
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                        context,
                        isEn ? 'Personal Information' : 'Thông tin cá nhân',
                      ),
                      const SizedBox(height: 8),
                      _groupCard(
                        cardColor: cardColor,
                        borderColor: borderColor,
                        children: [
                          _ProfileDetailRow(
                            icon: Iconsax.user,
                            iconColor: const Color(0xFF173E32),
                            iconBg: dark
                                ? const Color(0xFF1E352B)
                                : const Color(0xFFEAF2EE),
                            label: isEn ? 'Full Name' : 'Họ và tên',
                            value: user.fullName.trim().isEmpty
                                ? '—'
                                : user.fullName.trim(),
                            actionLabel: isEn ? 'Edit' : 'Sửa',
                            onTap: () async {
                              await Get.to(() => const ChangeName());
                              controller.user.refresh();
                            },
                          ),
                          _divider(borderColor),
                          _ProfileDetailRow(
                            icon: Iconsax.personalcard,
                            iconColor: const Color(0xFF4F46E5),
                            iconBg: dark
                                ? const Color(0xFF1E1D3B)
                                : const Color(0xFFE0E7FF),
                            label: isEn ? 'Username' : 'Tên tài khoản',
                            value: user.username.isEmpty
                                ? '—'
                                : '@${user.username}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      _sectionTitle(
                        context,
                        isEn ? 'Contact Information' : 'Thông tin liên hệ',
                      ),
                      const SizedBox(height: 8),
                      _groupCard(
                        cardColor: cardColor,
                        borderColor: borderColor,
                        children: [
                          _ProfileDetailRow(
                            icon: Iconsax.sms,
                            iconColor: const Color(0xFF0284C7),
                            iconBg: dark
                                ? const Color(0xFF122C38)
                                : const Color(0xFFE0F2FE),
                            label: 'Email',
                            value: user.email.isEmpty ? '—' : user.email,
                            badgeText: isEn ? 'Verified' : 'Đã xác thực',
                          ),
                          _divider(borderColor),
                          _ProfileDetailRow(
                            icon: Iconsax.call,
                            iconColor: const Color(0xFF059669),
                            iconBg: dark
                                ? const Color(0xFF132E24)
                                : const Color(0xFFD1FAE5),
                            label: isEn ? 'Phone Number' : 'Số điện thoại',
                            value: user.phoneNumber.trim().isEmpty
                                ? (isEn ? 'Not added yet' : 'Chưa cập nhật')
                                : user.phoneNumber.trim(),
                            actionLabel: isEn ? 'Edit' : 'Sửa',
                            onTap: () => _editPhoneNumber(context, controller),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      _sectionTitle(
                        context,
                        isEn ? 'Account & Security' : 'Định danh & Bảo mật',
                      ),
                      const SizedBox(height: 8),
                      _groupCard(
                        cardColor: cardColor,
                        borderColor: borderColor,
                        children: [
                          _ProfileDetailRow(
                            icon: Iconsax.key,
                            iconColor: const Color(0xFFD97706),
                            iconBg: dark
                                ? const Color(0xFF332613)
                                : const Color(0xFFFEF3C7),
                            label: isEn ? 'Account ID' : 'Mã tài khoản',
                            value: user.id.isEmpty ? '—' : user.id,
                            monospaceValue: true,
                            actionLabel: isEn ? 'Copy' : 'Sao chép',
                            onTap: user.id.isEmpty
                                ? null
                                : () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: user.id),
                                    );
                                    TLoaders.successSnackBar(
                                      title: isEn ? 'Copied' : 'Đã sao chép',
                                      message: isEn
                                          ? 'Account ID copied to clipboard.'
                                          : 'Đã sao chép mã tài khoản của bạn.',
                                    );
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Danger zone: Close account
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: controller.deleteAccountWarningPopup,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC62828),
                            backgroundColor: dark
                                ? const Color(0xFF281717)
                                : const Color(0xFFFFF5F5),
                            side: BorderSide(
                              color: const Color(0xFFC62828)
                                  .withValues(alpha: 0.28),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Iconsax.user_remove, size: 19),
                          label: const ShopText(
                            'Close Account',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).hintColor,
              ),
        ),
      );

  Widget _groupCard({
    required Color cardColor,
    required Color borderColor,
    required List<Widget> children,
  }) =>
      Container(
        decoration: ShopGlassDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );

  Widget _divider(Color color) =>
      Divider(height: 1, indent: 66, endIndent: 16, color: color);
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.actionLabel,
    this.badgeText,
    this.monospaceValue = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String? actionLabel;
  final String? badgeText;
  final bool monospaceValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: monospaceValue ? 12.5 : 14.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: monospaceValue ? 'monospace' : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (badgeText != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF132E24)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText!,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: dark
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFF15803D),
                  ),
                ),
              ),
            if (actionLabel != null && onTap != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: ShopGlassDecoration(
                  color: dark
                      ? const Color(0xFF22362D)
                      : const Color(0xFFEEF4F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: dark
                        ? const Color(0xFFDDEABB)
                        : const Color(0xFF173E32),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
