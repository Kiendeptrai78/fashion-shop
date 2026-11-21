import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/features/shop/models/brand_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class AdminBrandsView extends StatefulWidget {
  const AdminBrandsView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminBrandsView> createState() => _AdminBrandsViewState();
}

class _AdminBrandsViewState extends State<AdminBrandsView> {
  String _query = '';

  Future<void> _openEditor({BrandModel? existing}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final imageCtrl = TextEditingController(text: existing?.image ?? '');
    bool isFeatured = existing?.isFeatured ?? true;
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: AdminColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            existing == null
                                ? 'Thêm thương hiệu mới'
                                : 'Chỉnh sửa thương hiệu',
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
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: nameCtrl,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên thương hiệu' : null,
                      decoration: adminInputDecoration(
                        label: 'Tên thương hiệu *',
                        hint: 'Ví dụ: Nike, Adidas, New Balance...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    AdminImageUploadField(
                      label: 'Logo / Ảnh đại diện thương hiệu',
                      controller: imageCtrl,
                      previewWidth: 88,
                      previewHeight: 88,
                      onUploadBytes: (bytes, name) =>
                          widget.controller.uploadImage(bytes, name, 'Brands/Images'),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AdminColors.forest,
                      title: const Text('Hiển thị thương hiệu nổi bật',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                      subtitle: const Text(
                        'Xuất hiện ưu tiên trong bộ lọc và trang Cửa hàng trên app.',
                        style: TextStyle(fontSize: 12, color: AdminColors.inkMuted),
                      ),
                      value: isFeatured,
                      onChanged: (v) => setModalState(() => isFeatured = v),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: saving ? null : () => Navigator.of(context).pop(),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 10),
                        AdminPrimaryButton(
                          label: existing == null ? 'Tạo thương hiệu' : 'Lưu thay đổi',
                          icon: Iconsax.tick_circle,
                          loading: saving,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => saving = true);
                            final count = existing != null
                                ? widget.controller.productCountForBrand(existing.id)
                                : 0;
                            final ok = await widget.controller.saveBrand(
                              BrandModel(
                                id: existing?.id ?? '',
                                name: nameCtrl.text.trim(),
                                image: imageCtrl.text.trim(),
                                isFeatured: isFeatured,
                                productsCount: count,
                              ),
                              isNew: existing == null,
                            );
                            if (!context.mounted) return;
                            setModalState(() => saving = false);
                            if (ok) Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    nameCtrl.dispose();
    imageCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Obx(() {
      final q = _query.trim().toLowerCase();
      final filtered = widget.controller.brands.where((b) {
        if (q.isEmpty) return true;
        return b.name.toLowerCase().contains(q) || b.id.toLowerCase().contains(q);
      }).toList();

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Quản lý Thương hiệu (${widget.controller.brands.length})',
                  subtitle:
                      'Quản lý logo, trạng thái nổi bật và theo dõi số lượng mẫu giày theo từng hãng.',
                  actions: [
                    AdminSearchField(
                      hint: 'Tìm thương hiệu...',
                      width: 240,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    AdminPrimaryButton(
                      label: 'Thêm thương hiệu',
                      icon: Iconsax.add_circle,
                      onPressed: () => _openEditor(),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                if (filtered.isEmpty)
                  AdminCard(
                    child: AdminEmptyState(
                      icon: Iconsax.award,
                      title: 'Chưa có thương hiệu phù hợp',
                      subtitle: 'Thêm các thương hiệu giày để phân loại sản phẩm trên ứng dụng.',
                      action: AdminPrimaryButton(
                        label: 'Thêm thương hiệu đầu tiên',
                        onPressed: () => _openEditor(),
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth >= 1100
                          ? 3
                          : constraints.maxWidth >= 680
                              ? 2
                              : 1;
                      final cardWidth =
                          (constraints.maxWidth - (cols - 1) * 16) / cols;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: filtered.map((brand) {
                          final liveCount =
                              widget.controller.productCountForBrand(brand.id);
                          return SizedBox(
                            width: cardWidth,
                            child: AdminCard(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  AdminImageThumb(
                                    url: brand.image,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.contain,
                                    borderRadius: 14,
                                    placeholderIcon: Iconsax.award,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                brand.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AdminColors.ink,
                                                ),
                                              ),
                                            ),
                                            if (brand.isFeatured == true)
                                              const AdminBadge(
                                                label: 'Nổi bật',
                                                color: AdminColors.forest,
                                                bgColor: AdminColors.sageSoft,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$liveCount sản phẩm đang bán',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AdminColors.inkSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => _openEditor(existing: brand),
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 6),
                                                foregroundColor: AdminColors.forest,
                                              ),
                                              icon: const Icon(Iconsax.edit_2, size: 15),
                                              label: const Text('Sửa', style: TextStyle(fontSize: 12)),
                                            ),
                                            TextButton.icon(
                                              onPressed: () async {
                                                final ok = await showAdminConfirmDialog(
                                                  context,
                                                  title: 'Xóa thương hiệu "${brand.name}"?',
                                                  message:
                                                      'Thương hiệu sẽ bị xóa khỏi danh mục Brands trên Firestore.',
                                                );
                                                if (ok) {
                                                  await widget.controller.deleteBrand(brand);
                                                }
                                              },
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 6),
                                                foregroundColor: AdminColors.rose,
                                              ),
                                              icon: const Icon(Iconsax.trash, size: 15),
                                              label: const Text('Xóa', style: TextStyle(fontSize: 12)),
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
