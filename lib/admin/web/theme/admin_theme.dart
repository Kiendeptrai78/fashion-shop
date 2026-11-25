import 'dart:typed_data';

import 'package:fashion_business_app/utils/constants/enums.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AdminColors {
  AdminColors._();

  static const Color forestDark = Color(0xFF102B23);
  static const Color forest = Color(0xFF173E32);
  static const Color forestLight = Color(0xFF2D594D);
  static const Color sage = Color(0xFFDDEABB);
  static const Color sageSoft = Color(0xFFEAF2EE);

  static const Color canvas = Color(0xFFF4F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FAF9);
  static const Color border = Color(0xFFE2EAE6);
  static const Color borderStrong = Color(0xFFCBD8D2);

  static const Color ink = Color(0xFF111C18);
  static const Color inkSecondary = Color(0xFF5A6B64);
  static const Color inkMuted = Color(0xFF8A9B94);

  static const Color emerald = Color(0xFF15803D);
  static const Color emeraldBg = Color(0xFFDCFCE7);
  static const Color amber = Color(0xFFB45309);
  static const Color amberBg = Color(0xFFFEF3C7);
  static const Color sky = Color(0xFF0369A1);
  static const Color skyBg = Color(0xFFE0F2FE);
  static const Color rose = Color(0xFFBE123C);
  static const Color roseBg = Color(0xFFFFE4E6);
  static const Color violet = Color(0xFF6D28D9);
  static const Color violetBg = Color(0xFFEDE9FE);
}

class AdminOrderStatusMeta {
  const AdminOrderStatusMeta({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  static AdminOrderStatusMeta of(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const AdminOrderStatusMeta(
          label: 'Chờ xác nhận',
          color: AdminColors.amber,
          bgColor: AdminColors.amberBg,
          icon: Iconsax.clock,
        );
      case OrderStatus.processing:
        return const AdminOrderStatusMeta(
          label: 'Đang đóng gói',
          color: AdminColors.violet,
          bgColor: AdminColors.violetBg,
          icon: Iconsax.box_time,
        );
      case OrderStatus.shipped:
        return const AdminOrderStatusMeta(
          label: 'Đang vận chuyển',
          color: AdminColors.sky,
          bgColor: AdminColors.skyBg,
          icon: Iconsax.truck_fast,
        );
      case OrderStatus.received:
        return const AdminOrderStatusMeta(
          label: 'Giao thành công',
          color: AdminColors.emerald,
          bgColor: AdminColors.emeraldBg,
          icon: Iconsax.tick_circle,
        );
      case OrderStatus.cancelled:
        return const AdminOrderStatusMeta(
          label: 'Đã hủy đơn',
          color: AdminColors.rose,
          bgColor: AdminColors.roseBg,
          icon: Iconsax.close_circle,
        );
    }
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AdminColors.surface,
    this.borderRadius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: AdminColors.forestDark.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.accentBg,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color accentBg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AdminCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: AdminColors.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.ink,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              softWrap: true,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.25,
                color: AdminColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminBadge extends StatelessWidget {
  const AdminBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color bgColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSectionToolbar extends StatelessWidget {
  const AdminSectionToolbar({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runAlignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AdminColors.ink,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AdminColors.inkSecondary,
              ),
            ),
          ],
        ),
        if (actions.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: actions,
          ),
      ],
    );
  }
}

class AdminPrimaryButton extends StatelessWidget {
  const AdminPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AdminColors.forest,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      icon: loading
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon ?? Icons.add_rounded, size: 17),
      label: Text(label),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
    this.width = 300,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: AdminColors.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: AdminColors.inkMuted),
          prefixIcon: const Icon(Iconsax.search_normal_1, size: 17, color: AdminColors.inkMuted),
          filled: true,
          fillColor: AdminColors.surfaceMuted,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AdminColors.forest, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class AdminImageThumb extends StatelessWidget {
  const AdminImageThumb({
    super.key,
    required this.url,
    this.width = 48,
    this.height = 48,
    this.borderRadius = 10,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Iconsax.image,
  });

  final String url;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AdminColors.sageSoft,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AdminColors.border),
      ),
      child: trimmed.isEmpty
          ? Icon(placeholderIcon, size: width * 0.42, color: AdminColors.inkMuted)
          : Image.network(
              trimmed,
              fit: fit,
              errorBuilder: (_, __, ___) => Icon(
                placeholderIcon,
                size: width * 0.42,
                color: AdminColors.inkMuted,
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.8),
                  ),
                );
              },
            ),
    );
  }
}

class AdminImageUploadField extends StatefulWidget {
  const AdminImageUploadField({
    super.key,
    required this.label,
    required this.controller,
    required this.onUploadBytes,
    this.previewHeight = 110,
    this.previewWidth = 110,
  });

  final String label;
  final TextEditingController controller;
  final Future<String> Function(Uint8List bytes, String filename) onUploadBytes;
  final double previewHeight;
  final double previewWidth;

  @override
  State<AdminImageUploadField> createState() => _AdminImageUploadFieldState();
}

class _AdminImageUploadFieldState extends State<AdminImageUploadField> {
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    setState(() => _error = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        setState(() => _error = 'Không đọc được dữ liệu ảnh.');
        return;
      }
      setState(() => _uploading = true);
      final url = await widget.onUploadBytes(bytes, file.name);
      widget.controller.text = url;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AdminColors.inkSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (_, value, __) {
            final hasImage = value.text.trim().isNotEmpty;
            return InkWell(
              onTap: _uploading ? null : _pickAndUpload,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasImage ? AdminColors.borderStrong : AdminColors.border,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    AdminImageThumb(
                      url: value.text,
                      width: widget.previewWidth,
                      height: widget.previewHeight,
                      borderRadius: 12,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _uploading
                                ? 'Đang tải ảnh lên...'
                                : hasImage
                                    ? 'Đã có ảnh • Nhấn để thay đổi'
                                    : 'Nhấn để chọn ảnh từ máy tính',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Hỗ trợ JPG, PNG, WEBP • Tự động lưu trên đám mây',
                            style: TextStyle(fontSize: 11.5, color: AdminColors.inkMuted),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _uploading ? null : _pickAndUpload,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AdminColors.forest,
                                  backgroundColor: AdminColors.surface,
                                  side: const BorderSide(color: AdminColors.borderStrong),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: _uploading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Iconsax.document_upload, size: 15),
                                label: Text(hasImage ? 'Đổi ảnh khác' : 'Chọn ảnh từ máy'),
                              ),
                              if (hasImage)
                                TextButton.icon(
                                  onPressed: _uploading
                                      ? null
                                      : () {
                                          widget.controller.clear();
                                          setState(() {});
                                        },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AdminColors.rose,
                                  ),
                                  icon: const Icon(Iconsax.trash, size: 15),
                                  label: const Text('Xóa ảnh', style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _error!,
                              style: const TextStyle(fontSize: 12, color: AdminColors.rose),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Visual multi-photo uploader for products: pick 1 or many photos at once,
/// preview as clean tiles, click the star to set the cover photo, or remove any photo.
class AdminMultiImageUploader extends StatefulWidget {
  const AdminMultiImageUploader({
    super.key,
    required this.images,
    required this.thumbnailUrl,
    required this.onChanged,
    required this.onUploadBytes,
  });

  final List<String> images;
  final String thumbnailUrl;
  final void Function(List<String> images, String thumbnailUrl) onChanged;
  final Future<String> Function(Uint8List bytes, String filename) onUploadBytes;

  @override
  State<AdminMultiImageUploader> createState() => _AdminMultiImageUploaderState();
}

class _AdminMultiImageUploaderState extends State<AdminMultiImageUploader> {
  bool _uploading = false;
  int _uploadedCount = 0;
  int _totalToUpload = 0;
  String? _error;

  Future<void> _pickMultiple() async {
    setState(() => _error = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final validFiles =
          result.files.where((f) => f.bytes != null && f.bytes!.isNotEmpty).toList();
      if (validFiles.isEmpty) {
        setState(() => _error = 'Không đọc được dữ liệu ảnh đã chọn.');
        return;
      }

      setState(() {
        _uploading = true;
        _uploadedCount = 0;
        _totalToUpload = validFiles.length;
      });

      final updated = List<String>.from(widget.images);
      String nextThumb = widget.thumbnailUrl;

      for (final file in validFiles) {
        final url = await widget.onUploadBytes(file.bytes!, file.name);
        if (!updated.contains(url)) {
          updated.add(url);
        }
        if (nextThumb.trim().isEmpty) {
          nextThumb = url;
        }
        if (mounted) {
          setState(() => _uploadedCount++);
        }
      }

      widget.onChanged(updated, nextThumb);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadedCount = 0;
          _totalToUpload = 0;
        });
      }
    }
  }

  void _setAsThumbnail(String url) {
    final reordered = List<String>.from(widget.images)
      ..remove(url)
      ..insert(0, url);
    widget.onChanged(reordered, url);
  }

  void _removeImage(String url) {
    final updated = List<String>.from(widget.images)..remove(url);
    final nextThumb = widget.thumbnailUrl == url
        ? (updated.isNotEmpty ? updated.first : '')
        : widget.thumbnailUrl;
    widget.onChanged(updated, nextThumb);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hình ảnh sản phẩm *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Chọn một hoặc nhiều ảnh từ máy tính. Nhấn biểu tượng ngôi sao để chọn làm ảnh đại diện.',
                    style: TextStyle(fontSize: 11.5, color: AdminColors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickMultiple,
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminColors.forest,
                backgroundColor: AdminColors.sageSoft.withValues(alpha: 0.6),
                side: const BorderSide(color: AdminColors.forest),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              icon: _uploading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AdminColors.forest,
                      ),
                    )
                  : const Icon(Iconsax.gallery_add, size: 17),
              label: Text(
                _uploading
                    ? 'Đang tải $_uploadedCount/$_totalToUpload ảnh...'
                    : 'Thêm ảnh từ máy',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.images.isEmpty)
          InkWell(
            onTap: _uploading ? null : _pickMultiple,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: AdminColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.borderStrong),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AdminColors.sageSoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Iconsax.gallery_add,
                        size: 24, color: AdminColors.forest),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nhấn vào đây để chọn ảnh sản phẩm (có thể chọn nhiều ảnh cùng lúc)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ảnh đầu tiên sẽ tự động làm ảnh đại diện hiển thị ngoài trang chủ',
                    style: TextStyle(fontSize: 11.5, color: AdminColors.inkMuted),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final url in widget.images) ...[
                Builder(builder: (_) {
                  final isMain = url == widget.thumbnailUrl;
                  return Stack(
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: isMain ? AdminColors.forest : AdminColors.border,
                            width: isMain ? 2 : 1,
                          ),
                        ),
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Iconsax.image, color: AdminColors.inkMuted),
                          ),
                        ),
                      ),
                      if (isMain)
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AdminColors.forest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Ảnh chính',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          left: 6,
                          top: 6,
                          child: Tooltip(
                            message: 'Đặt làm ảnh chính',
                            child: InkWell(
                              onTap: () => _setAsThumbnail(url),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star_outline_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Tooltip(
                          message: 'Xóa ảnh này',
                          child: InkWell(
                            onTap: () => _removeImage(url),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AdminColors.rose.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
              // Quick "+ Thêm ảnh" tile
              InkWell(
                onTap: _uploading ? null : _pickMultiple,
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AdminColors.borderStrong),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_uploading)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AdminColors.forest,
                          ),
                        )
                      else
                        const Icon(Iconsax.add_circle,
                            size: 24, color: AdminColors.forest),
                      const SizedBox(height: 6),
                      Text(
                        _uploading ? '$_uploadedCount/$_totalToUpload' : 'Thêm ảnh',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.forest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(fontSize: 12, color: AdminColors.rose),
          ),
        ],
      ],
    );
  }
}

class AdminVideoUploadField extends StatefulWidget {
  const AdminVideoUploadField({
    super.key,
    required this.label,
    required this.controller,
    required this.onUploadBytes,
  });

  final String label;
  final TextEditingController controller;
  final Future<String> Function(Uint8List bytes, String filename) onUploadBytes;

  @override
  State<AdminVideoUploadField> createState() => _AdminVideoUploadFieldState();
}

class _AdminVideoUploadFieldState extends State<AdminVideoUploadField> {
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    setState(() => _error = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        setState(() => _error = 'Không đọc được tệp video.');
        return;
      }
      setState(() => _uploading = true);
      final url = await widget.onUploadBytes(bytes, file.name);
      widget.controller.text = url;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AdminColors.inkSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (_, value, __) {
            final hasVideo = value.text.trim().isNotEmpty;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AdminColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hasVideo ? AdminColors.forest : AdminColors.sageSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Iconsax.video_play,
                      size: 20,
                      color: hasVideo ? AdminColors.sage : AdminColors.forest,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _uploading
                              ? 'Đang tải video lên Cloudinary...'
                              : hasVideo
                                  ? 'Đã gắn video Lookbook (MP4)'
                                  : 'Chưa có video (tùy chọn)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AdminColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasVideo
                              ? 'Video tự động phát không tiếng trên banner trang chủ.'
                              : 'Tải lên video ngắn MP4 từ máy nếu muốn làm banner chuyển động.',
                          style: const TextStyle(fontSize: 11.5, color: AdminColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickAndUpload,
                    icon: _uploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Iconsax.document_upload, size: 15),
                    label: Text(hasVideo ? 'Đổi video' : 'Tải video'),
                  ),
                  if (hasVideo)
                    IconButton(
                      tooltip: 'Gỡ video',
                      onPressed: _uploading
                          ? null
                          : () {
                              widget.controller.clear();
                              setState(() {});
                            },
                      icon: const Icon(Iconsax.trash, size: 16, color: AdminColors.rose),
                    ),
                ],
              ),
            );
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: const TextStyle(fontSize: 12, color: AdminColors.rose)),
        ],
      ],
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AdminColors.sageSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: AdminColors.forest),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AdminColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AdminColors.inkSecondary),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

InputDecoration adminInputDecoration({
  String? label,
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AdminColors.surfaceMuted,
    labelStyle: const TextStyle(fontSize: 13, color: AdminColors.inkSecondary),
    hintStyle: const TextStyle(fontSize: 13, color: AdminColors.inkMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AdminColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AdminColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AdminColors.forest, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AdminColors.rose),
    ),
  );
}

Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Xác nhận xóa',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AdminColors.ink),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(
          message,
          style: const TextStyle(fontSize: 13.5, color: AdminColors.inkSecondary, height: 1.5),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminColors.inkSecondary,
            side: const BorderSide(color: AdminColors.borderStrong),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? AdminColors.rose : AdminColors.forest,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}
