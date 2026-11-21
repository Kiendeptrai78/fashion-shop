import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/data/admin_web_models.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/features/shop/models/banner_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class AdminBannersView extends StatefulWidget {
  const AdminBannersView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminBannersView> createState() => _AdminBannersViewState();
}

class _AdminBannersViewState extends State<AdminBannersView> {
  Future<void> _openEditor({AdminBannerRecord? existing}) async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: existing?.banner.title ?? '');
    final subtitleCtrl = TextEditingController(text: existing?.banner.subtitle ?? '');
    final imageCtrl = TextEditingController(text: existing?.banner.imageUrl ?? '');
    final videoCtrl = TextEditingController(text: existing?.banner.videoUrl ?? '');
    final sortCtrl = TextEditingController(
      text: (existing?.banner.sortOrder ?? widget.controller.banners.length).toString(),
    );
    String targetScreen = existing?.banner.targetScreen.isNotEmpty == true
        ? existing!.banner.targetScreen
        : '/all-products';
    String categoryId = existing?.banner.categoryId ?? '';
    String brandId = existing?.banner.brandId ?? '';
    bool active = existing?.banner.active ?? true;
    bool saving = false;

    final categories = widget.controller.categories;
    final brands = widget.controller.brands;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: AdminColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 780),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AdminColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          existing == null
                              ? 'Tạo Banner / Chiến dịch mới'
                              : 'Chỉnh sửa Banner',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: saving ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdminImageUploadField(
                            label: 'Ảnh Banner / Poster *',
                            controller: imageCtrl,
                            previewWidth: 150,
                            previewHeight: 92,
                            onUploadBytes: (bytes, name) =>
                                widget.controller.uploadImage(bytes, name, 'Banners/Images'),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: videoCtrl,
                            decoration: adminInputDecoration(
                              label: 'Video URL (tùy chọn — MP4 Lookbook)',
                              hint: 'https://res.cloudinary.com/.../video.mp4',
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: titleCtrl,
                                  decoration: adminInputDecoration(
                                    label: 'Tiêu đề chiến dịch',
                                    hint: 'Ví dụ: Bộ sưu tập Chạy bộ 2026',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: sortCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: adminInputDecoration(
                                    label: 'Thứ tự',
                                    hint: '0',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: subtitleCtrl,
                            decoration: adminInputDecoration(
                              label: 'Mô tả ngắn (Subtitle)',
                              hint: 'Ví dụ: Khám phá ưu đãi giảm đến 30%',
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: categories.any((c) => c.id == categoryId)
                                      ? categoryId
                                      : '',
                                  decoration: adminInputDecoration(
                                    label: 'Liên kết Danh mục (tùy chọn)',
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: '', child: Text('Không lọc danh mục')),
                                    ...categories.map((c) => DropdownMenuItem(
                                          value: c.id,
                                          child: Text(c.name),
                                        )),
                                  ],
                                  onChanged: (v) => setModalState(() => categoryId = v ?? ''),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: brands.any((b) => b.id == brandId) ? brandId : '',
                                  decoration: adminInputDecoration(
                                    label: 'Liên kết Thương hiệu (tùy chọn)',
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: '', child: Text('Không lọc hãng')),
                                    ...brands.map((b) => DropdownMenuItem(
                                          value: b.id,
                                          child: Text(b.name),
                                        )),
                                  ],
                                  onChanged: (v) => setModalState(() => brandId = v ?? ''),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: [
                              '/all-products',
                              '/store',
                              '/brand',
                              '/order',
                            ].contains(targetScreen)
                                ? targetScreen
                                : '/all-products',
                            decoration: adminInputDecoration(label: 'Màn hình đích khi nhấn'),
                            items: const [
                              DropdownMenuItem(
                                  value: '/all-products',
                                  child: Text('Danh sách sản phẩm (/all-products)')),
                              DropdownMenuItem(value: '/store', child: Text('Cửa hàng (/store)')),
                              DropdownMenuItem(value: '/brand', child: Text('Thương hiệu (/brand)')),
                              DropdownMenuItem(value: '/order', child: Text('Đơn hàng (/order)')),
                            ],
                            onChanged: (v) =>
                                setModalState(() => targetScreen = v ?? '/all-products'),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: AdminColors.forest,
                            title: const Text('Đang kích hoạt (hiển thị trên Trang chủ)',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                            value: active,
                            onChanged: (v) => setModalState(() => active = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AdminColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: saving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 10),
                      AdminPrimaryButton(
                        label: existing == null ? 'Tạo Banner' : 'Lưu thay đổi',
                        icon: Iconsax.tick_circle,
                        loading: saving,
                        onPressed: () async {
                          if (imageCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng nhập hoặc tải lên ảnh banner.')),
                            );
                            return;
                          }
                          setModalState(() => saving = true);
                          final ok = await widget.controller.saveBanner(
                            BannerModel(
                              imageUrl: imageCtrl.text.trim(),
                              videoUrl: videoCtrl.text.trim(),
                              targetScreen: targetScreen,
                              active: active,
                              title: titleCtrl.text.trim(),
                              subtitle: subtitleCtrl.text.trim(),
                              categoryId: categoryId.isNotEmpty ? categoryId : null,
                              brandId: brandId.isNotEmpty ? brandId : null,
                              sortOrder: int.tryParse(sortCtrl.text.trim()) ?? 0,
                            ),
                            docId: existing?.docId,
                          );
                          if (!context.mounted) return;
                          setModalState(() => saving = false);
                          if (ok) Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    titleCtrl.dispose();
    subtitleCtrl.dispose();
    imageCtrl.dispose();
    videoCtrl.dispose();
    sortCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Obx(() {
      final banners = widget.controller.banners;
      final brandNames = {for (final b in widget.controller.brands) b.id: b.name};
      final categoryNames = {for (final c in widget.controller.categories) c.id: c.name};

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Quản lý Banner & Chiến dịch (${banners.length})',
                  subtitle:
                      'Quản lý slider hình ảnh và video lookbook trên trang chủ ứng dụng di động.',
                  actions: [
                    AdminPrimaryButton(
                      label: 'Thêm Banner mới',
                      icon: Iconsax.add_circle,
                      onPressed: () => _openEditor(),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                if (banners.isEmpty)
                  AdminCard(
                    child: AdminEmptyState(
                      icon: Iconsax.gallery,
                      title: 'Chưa có banner nào',
                      subtitle: 'Tạo banner khuyến mãi hoặc chiến dịch video để thu hút khách hàng.',
                      action: AdminPrimaryButton(
                        label: 'Tạo Banner đầu tiên',
                        onPressed: () => _openEditor(),
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth >= 1060
                          ? 2
                          : 1;
                      final cardWidth =
                          (constraints.maxWidth - (cols - 1) * 18) / cols;
                      return Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        children: banners.map((record) {
                          final b = record.banner;
                          final hasVideo = b.videoUrl.trim().isNotEmpty;
                          return SizedBox(
                            width: cardWidth,
                            child: AdminCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Visual banner preview
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(15),
                                        ),
                                        child: AspectRatio(
                                          aspectRatio: 16 / 7.5,
                                          child: Container(
                                            color: AdminColors.forestDark,
                                            child: b.imageUrl.isEmpty
                                                ? const Center(
                                                    child: Icon(Iconsax.gallery,
                                                        size: 40, color: Colors.white54),
                                                  )
                                                : Image.network(
                                                    b.imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Center(
                                                      child: Icon(Iconsax.gallery_slash,
                                                          size: 36, color: Colors.white54),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Wrap(
                                          spacing: 6,
                                          children: [
                                            AdminBadge(
                                              label: 'Thứ tự #${b.sortOrder}',
                                              color: Colors.white,
                                              bgColor: Colors.black.withValues(alpha: 0.6),
                                            ),
                                            if (hasVideo)
                                              const AdminBadge(
                                                label: 'Video Lookbook',
                                                color: AdminColors.sage,
                                                bgColor: AdminColors.forestDark,
                                                icon: Iconsax.video_play,
                                              ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 12,
                                        child: AdminBadge(
                                          label: b.active ? 'Đang hiển thị' : 'Đang ẩn',
                                          color: b.active
                                              ? AdminColors.emerald
                                              : AdminColors.inkSecondary,
                                          bgColor: b.active
                                              ? AdminColors.emeraldBg
                                              : Colors.white.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    b.title.isNotEmpty
                                                        ? b.title
                                                        : 'Banner không tiêu đề',
                                                    style: const TextStyle(
                                                      fontSize: 15.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: AdminColors.ink,
                                                    ),
                                                  ),
                                                  if (b.subtitle.isNotEmpty) ...[
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      b.subtitle,
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                        color: AdminColors.inkSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Switch(
                                              value: b.active,
                                              activeColor: AdminColors.forest,
                                              onChanged: (v) => widget.controller
                                                  .toggleBannerActive(record, v),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            AdminBadge(
                                              label: 'Route: ${b.targetScreen}',
                                              color: AdminColors.inkSecondary,
                                              bgColor: AdminColors.surfaceMuted,
                                            ),
                                            if (b.categoryId != null && b.categoryId!.isNotEmpty)
                                              AdminBadge(
                                                label:
                                                    'Danh mục: ${categoryNames[b.categoryId] ?? b.categoryId}',
                                                color: AdminColors.forest,
                                                bgColor: AdminColors.sageSoft,
                                              ),
                                            if (b.brandId != null && b.brandId!.isNotEmpty)
                                              AdminBadge(
                                                label:
                                                    'Hãng: ${brandNames[b.brandId] ?? b.brandId}',
                                                color: AdminColors.sky,
                                                bgColor: AdminColors.skyBg,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => _openEditor(existing: record),
                                              icon: const Icon(Iconsax.edit_2, size: 16),
                                              label: const Text('Chỉnh sửa'),
                                            ),
                                            const SizedBox(width: 6),
                                            TextButton.icon(
                                              onPressed: () async {
                                                final ok = await showAdminConfirmDialog(
                                                  context,
                                                  title: 'Xóa banner này?',
                                                  message:
                                                      'Banner sẽ bị gỡ khỏi trang chủ ứng dụng ngay lập tức.',
                                                );
                                                if (ok) {
                                                  await widget.controller.deleteBanner(record);
                                                }
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: AdminColors.rose,
                                              ),
                                              icon: const Icon(Iconsax.trash, size: 16),
                                              label: const Text('Xóa'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
