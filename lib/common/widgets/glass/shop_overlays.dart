import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'shop_glass.dart';

const shopLightOverlaySettings = LiquidGlassSettings(
  blur: 18, thickness: 18, frost: 0, glassColor: Color(0xD9FAFAFB),
);
const shopDarkOverlaySettings = LiquidGlassSettings(
  blur: 18, thickness: 18, frost: 0, glassColor: Color(0xD91C211F),
);

/// One readable glass surface for dialogs and sheets on both platforms.
class ShopOverlaySurface extends StatelessWidget {
  const ShopOverlaySurface({super.key, required this.child, this.dark = false, this.borderless = false});
  final Widget child;
  final bool dark;
  final bool borderless;

  @override
  Widget build(BuildContext context) {
    final isDark = dark || Theme.of(context).brightness == Brightness.dark;
    if (borderless) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: ColoredBox(color: isDark ? const Color(0xD91C211F) : const Color(0xD9FAFAFB),
            child: Material(type: MaterialType.transparency, child: child))),
      );
    }
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      clipBehavior: Clip.antiAlias,
      shape: const LiquidRoundedSuperellipse(borderRadius: 28),
      settings: isDark ? shopDarkOverlaySettings : shopLightOverlaySettings,
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

Future<T?> showShopBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool showDragHandle = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool dark = false,
  bool borderless = false,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  useSafeArea: useSafeArea,
  isDismissible: isDismissible,
  enableDrag: enableDrag,
  showDragHandle: false,
  backgroundColor: Colors.transparent,
  shape: borderless ? const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ) : null,
  barrierColor: Colors.black.withValues(alpha: 0.24),
  elevation: 0,
  builder: (sheet) => Theme(
    data: dark ? Theme.of(sheet).copyWith(brightness: Brightness.dark) : Theme.of(sheet),
    child: ShopOverlaySurface(dark: dark, borderless: borderless, child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDragHandle) Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(width: 36, height: 4, decoration: BoxDecoration(
            color: dark ? Colors.white38 : Colors.black26,
            borderRadius: BorderRadius.circular(4),
          )),
        ),
        Flexible(child: Builder(builder: builder)),
      ],
    )),
  ),
);

class ShopGlassDialog extends StatelessWidget {
  const ShopGlassDialog({super.key, required this.child,
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 28, vertical: 24)});
  final Widget child;
  final EdgeInsets insetPadding;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    insetPadding: insetPadding,
    child: ShopOverlaySurface(child: child),
  );
}

class ShopGlassAlertDialog extends StatelessWidget {
  const ShopGlassAlertDialog({super.key, this.title, this.content, this.actions = const []});
  final Widget? title, content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => ShopGlassDialog(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) DefaultTextStyle.merge(
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700), child: title!),
        if (content != null) ...[
          const SizedBox(height: 16),
          Flexible(child: SingleChildScrollView(child: content!)),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Wrap(alignment: WrapAlignment.end, spacing: 8, children: [
            for (final action in actions)
              if (action is TextButton) GlassButton.custom(
                height: 40,
                useOwnLayer: true,
                enabled: action.onPressed != null,
                onTap: action.onPressed ?? () {},
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: action.child),
              ) else action,
          ]),
        ],
      ],
    ),
  ));
}
