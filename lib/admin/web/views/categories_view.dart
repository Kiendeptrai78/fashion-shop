import 'package:fashion_business_app/admin/web/controllers/admin_web_controller.dart';
import 'package:fashion_business_app/admin/web/theme/admin_theme.dart';
import 'package:fashion_business_app/features/shop/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class AdminCategoriesView extends StatefulWidget {
  const AdminCategoriesView({super.key, required this.controller});

  final AdminWebController controller;

  @override
  State<AdminCategoriesView> createState() => _AdminCategoriesViewState();
}

class _AdminCategoriesViewState extends State<AdminCategoriesView> {
  String _query = '';

  Future<void> _openEditor({CategoryModel? existing}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final imageCtrl = TextEditingController(text: existing?.image ?? '');
    String parentId = existing?.parentId ?? '';
    bool isFeatured = existing?.isFeatured ?? true;
    bool saving = false;

    final availableParents = widget.controller.categories
        .where((c) => c.id != existing?.id)
        .toList();

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
                            existing == null ? 'Thêm danh mục mới' : 'Chỉnh sửa danh mục',
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
                          (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên danh mục' : null,
                      decoration: adminInputDecoration(
                        label: 'Tên danh mục *',
                        hint: 'Ví dụ: Running, Lifestyle, Basketball...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: availableParents.any((c) => c.id == parentId) ? parentId : '',
                      decoration: adminInputDecoration(label: 'Danh mục cha (tùy chọn)'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Không có (Danh mục gốc)')),
                        ...availableParents.map(
                          (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => parentId = v ?? ''),
                    ),
                    const SizedBox(height: 16),
                    AdminImageUploadField(
                      label: 'Ảnh đại diện danh mục',
                      controller: imageCtrl,
                      previewWidth: 88,
                      previewHeight: 88,
                      onUploadBytes: (bytes, name) =>
                          widget.controller.uploadImage(bytes, name, 'Categories/Images'),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AdminColors.forest,
                      title: const Text('Hiển thị nổi bật trên Trang chủ',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
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
                          label: existing == null ? 'Tạo danh mục' : 'Lưu thay đổi',
                          icon: Iconsax.tick_circle,
                          loading: saving,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => saving = true);
                            final ok = await widget.controller.saveCategory(
                              CategoryModel(
                                id: existing?.id ?? '',
                                name: nameCtrl.text.trim(),
                                image: imageCtrl.text.trim(),
                                parentId: parentId,
                                isFeatured: isFeatured,
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
      final all = widget.controller.categories;
      final q = _query.trim().toLowerCase();
      final filtered = all.where((c) {
        if (q.isEmpty) return true;
        return c.name.toLowerCase().contains(q) || c.id.toLowerCase().contains(q);
      }).toList();
      final nameById = {for (final c in all) c.id: c.name};

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 700 ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionToolbar(
                  title: 'Quản lý Danh mục (${all.length})',
                  subtitle:
                      'Tổ chức bộ sưu tập giày và các danh mục hiển thị trên thanh điều hướng app.',
                  actions: [
                    AdminSearchField(
                      hint: 'Tìm danh mục...',
                      width: 240,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    AdminPrimaryButton(
                      label: 'Thêm danh mục',
                      icon: Iconsax.add_circle,
                      onPressed: () => _openEditor(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                AdminCard(
                  padding: EdgeInsets.zero,
                  child: filtered.isEmpty
                      ? AdminEmptyState(
                          icon: Iconsax.category,
                          title: 'Chưa có danh mục nào',
                          subtitle: 'Thêm danh mục để khách hàng dễ dàng lọc sản phẩm.',
                          action: AdminPrimaryButton(
                            label: 'Thêm danh mục',
                            onPressed: () => _openEditor(),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 820),
                            child: DataTable(
                              headingRowColor:
                                  WidgetStateProperty.all(AdminColors.surfaceMuted),
                              dataRowMinHeight: 62,
                              dataRowMaxHeight: 68,
                              columns: const [
                                DataColumn(label: Text('Danh mục', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Danh mục cha', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Số sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Hiển thị', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                              ],
                              rows: filtered.map((cat) {
                                final count =
                                    widget.controller.productCountForCategory(cat.id);
                                return DataRow(
                                  cells: [
                                    DataCell(Row(
                                      children: [
                                        AdminImageThumb(
                                          url: cat.image,
                                          width: 46,
                                          height: 46,
                                          fit: BoxFit.contain,
                                          placeholderIcon: Iconsax.category,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cat.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            Text(
                                              cat.id,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AdminColors.inkMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )),
                                    DataCell(Text(
                                      cat.parentId.isEmpty
                                          ? 'Danh mục gốc'
                                          : (nameById[cat.parentId] ?? cat.parentId),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AdminColors.inkSecondary,
                                      ),
                                    )),
                                    DataCell(Text(
                                      '$count sản phẩm',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    )),
                                    DataCell(AdminBadge(
                                      label: cat.isFeatured ? 'Nổi bật' : 'Thường',
                                      color: cat.isFeatured
                                          ? AdminColors.emerald
                                          : AdminColors.inkSecondary,
                                      bgColor: cat.isFeatured
                                          ? AdminColors.emeraldBg
                                          : AdminColors.surfaceMuted,
                                    )),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Chỉnh sửa',
                                          onPressed: () => _openEditor(existing: cat),
                                          icon: const Icon(Iconsax.edit_2,
                                              size: 18, color: AdminColors.forest),
                                        ),
                                        IconButton(
                                          tooltip: 'Xóa danh mục',
                                          onPressed: () async {
                                            final ok = await showAdminConfirmDialog(
                                              context,
                                              title: 'Xóa danh mục "${cat.name}"?',
                                              message:
                                                  'Danh mục này sẽ bị gỡ khỏi collection Categories.',
                                            );
                                            if (ok) {
                                              await widget.controller.deleteCategory(cat);
                                            }
                                          },
                                          icon: const Icon(Iconsax.trash,
                                              size: 18, color: AdminColors.rose),
                                        ),
                                      ],
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
