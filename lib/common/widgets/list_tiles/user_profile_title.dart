import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_business_app/common/widgets/images/circular_image.dart';
import 'package:fashion_business_app/common/widgets/shimmer/shimmer.dart';
import 'package:fashion_business_app/features/personalization/controllers/user_controller.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';

class TUserProfileTile extends StatelessWidget {
  const TUserProfileTile({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    return Obx(() => ListTile(
      leading: controller.imageUploading.value
          ? const TShimmerEffect(width: 50, height: 50, radius: 50)
          : TCircularImage(
              image: controller.user.value.profilePicture.isNotEmpty
                  ? controller.user.value.profilePicture : TImages.user,
              width: 50, height: 50, fit: BoxFit.cover,
              isNetworkImage: controller.user.value.profilePicture.isNotEmpty,
            ),
      title: Text(
        controller.user.value.fullName.trim().isEmpty
            ? 'Your account' : controller.user.value.fullName,
        style: const TextStyle(fontSize: 16, color: TColors.white),
      ),
      subtitle: Text(
        controller.user.value.email,
        style: const TextStyle(fontSize: 12, color: TColors.white),
      ),
      trailing: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Iconsax.edit,
          color: TColors.white,
        ),
      ),
    ));
  }
}
