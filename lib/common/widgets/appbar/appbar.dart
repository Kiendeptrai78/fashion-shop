import 'package:fashion_business_app/common/widgets/glass/shop_glass.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/device/device_utility.dart';
import 'package:fashion_business_app/utils/helpers/helper_funtions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;

const shopAppbarTitleStyle = TextStyle(
  fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2,
);

/// Inset belongs to scroll content, so it scrolls away beneath the glass toolbar.
EdgeInsets shopAppbarContentPadding(BuildContext context, [EdgeInsets padding = EdgeInsets.zero]) {
  final scaffold = Scaffold.maybeOf(context)?.widget;
  // Scaffold's extended body already includes the toolbar in padding.top,
  // while viewPadding.top has been removed from this subtree.
  final insideExtendedBody = scaffold?.appBar != null && scaffold!.extendBodyBehindAppBar;
  final top = MediaQuery.paddingOf(context).top + (insideExtendedBody ? 0 : kToolbarHeight);
  return padding.copyWith(top: padding.top + top);
}

/// Lets filter headers and their lists scroll underneath the same toolbar.
class ShopScrollUnderHeader extends StatelessWidget {
  const ShopScrollUnderHeader({super.key, required this.header, required this.body});
  final Widget header, body;

  @override
  Widget build(BuildContext context) => NestedScrollView(
    headerSliverBuilder: (context, _) => [SliverToBoxAdapter(child: Padding(
      padding: shopAppbarContentPadding(context), child: header,
    ))],
    body: body,
  );
}

/// Shared Liquid Glass settings for toolbar back buttons, icon buttons, and pills.
LiquidGlassSettings shopToolbarGlassSettings(
  BuildContext context, {
  bool onDark = false,
}) {
  final isDark = onDark || THelperFunctions.isDarkMode(context);
  final preset = isDark ? LiquidGlassSettings.ios27Dark : LiquidGlassSettings.ios27Light;
  return preset.copyWith(
    frost: 0,
    blur: 8,
    thickness: 16,
    glassColor: isDark ? const Color(0x38222D29) : const Color(0x38FFFFFF),
  );
}

/// Circular Liquid Glass back button used across app bars and custom headers.
class ShopGlassBackButton extends StatelessWidget {
  const ShopGlassBackButton({
    super.key,
    this.onPressed,
    this.icon,
    this.iconColor,
    this.size = 44,
    this.iconSize = 26,
    this.onDark = false,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final bool onDark;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = onDark || THelperFunctions.isDarkMode(context);
    final resolvedColor =
        iconColor ?? (isDark ? TColors.white : const Color(0xFF17201C));
    final label = tooltip ??
        Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        )?.backButtonTooltip ??
        'Back';

    final button = GlassButton(
      width: size,
      height: size,
      iconSize: iconSize,
      useOwnLayer: true,
      style: GlassButtonStyle.filled,
      settings: shopToolbarGlassSettings(context, onDark: onDark),
      iconColor: resolvedColor,
      label: label,
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: Icon(
        icon ?? CupertinoIcons.back,
        color: resolvedColor,
        size: iconSize,
      ),
    );

    return Tooltip(message: label, child: button);
  }
}

/// Circular Liquid Glass icon action button for app bars and custom headers.
class ShopGlassIconButton extends StatelessWidget {
  const ShopGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.size = 40,
    this.iconSize = 20,
    this.onDark = false,
    this.tooltip,
  }) : iconWidget = null;

  const ShopGlassIconButton.widget({
    super.key,
    required Widget this.iconWidget,
    required this.onPressed,
    this.iconColor,
    this.size = 40,
    this.iconSize = 20,
    this.onDark = false,
    this.tooltip,
  }) : icon = null;

  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final bool onDark;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = onDark || THelperFunctions.isDarkMode(context);
    final resolvedColor =
        iconColor ?? (isDark ? TColors.white : const Color(0xFF17201C));

    final button = GlassIconButton(
      size: size,
      iconSize: iconSize,
      useOwnLayer: true,
      style: GlassButtonStyle.filled,
      settings: shopToolbarGlassSettings(context, onDark: onDark),
      iconColor: resolvedColor,
      semanticLabel: tooltip,
      glowColor: Colors.transparent,
      onPressed: onPressed,
      icon: iconWidget ??
          Icon(
            icon,
            color: resolvedColor,
            size: iconSize,
          ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Pill-shaped Liquid Glass action button for text+icon app bar actions.
class ShopGlassPillButton extends StatelessWidget {
  const ShopGlassPillButton({
    super.key,
    required this.child,
    required this.onTap,
    this.height = 38,
    this.onDark = false,
    this.tooltip,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double height;
  final bool onDark;
  final String? tooltip;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final button = GlassButton.custom(
      useOwnLayer: true,
      height: height,
      style: GlassButtonStyle.filled,
      enabled: onTap != null,
      settings: shopToolbarGlassSettings(context, onDark: onDark),
      shape: LiquidRoundedSuperellipse(borderRadius: height / 2),
      label: tooltip ?? '',
      onTap: onTap ?? () {},
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class TAppbar extends StatelessWidget implements PreferredSizeWidget {
  const TAppbar({
    super.key,
    this.title,
    this.showBackArrow = false,
    this.leading,
    this.leadingIcon,
    this.actions,
    this.leadingOnPressed,
    this.onDarkSurface = false,
    this.backgroundColor,
    this.centerTitle = false,
    this.bottom,
  });

  final Widget? title;
  final bool showBackArrow;
  final Widget? leading;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final VoidCallback? leadingOnPressed;
  final bool onDarkSurface;
  final Color? backgroundColor;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  Widget _upgradeAction(BuildContext context, Widget action, Color iconColor) {
    if (action is IconButton) {
      return ShopGlassIconButton.widget(
        onPressed: action.onPressed,
        iconColor: iconColor,
        onDark: onDarkSurface,
        tooltip: action.tooltip,
        iconWidget: IconTheme.merge(
          data: IconThemeData(color: iconColor, size: 20),
          child: action.icon,
        ),
      );
    }
    return action;
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final effectiveOnDark = onDarkSurface ||
        (backgroundColor != null &&
            ThemeData.estimateBrightnessForColor(backgroundColor!) ==
                Brightness.dark);
    final isDarkText = effectiveOnDark || dark;
    final iconColor = isDarkText ? TColors.white : const Color(0xFF17201C);

    Widget? leadingWidget;
    if (leading != null) {
      if (leading is IconButton) {
        final btn = leading! as IconButton;
        leadingWidget = ShopGlassIconButton.widget(
          onPressed: btn.onPressed,
          iconColor: iconColor,
          onDark: effectiveOnDark,
          tooltip: btn.tooltip,
          iconWidget: IconTheme.merge(
            data: IconThemeData(color: iconColor, size: 20),
            child: btn.icon,
          ),
        );
      } else {
        leadingWidget = leading;
      }
    } else if (showBackArrow) {
      leadingWidget = ShopGlassBackButton(
        onPressed: leadingOnPressed,
        iconColor: iconColor,
        onDark: effectiveOnDark,
      );
    } else if (leadingIcon != null) {
      leadingWidget = ShopGlassIconButton(
        icon: leadingIcon!,
        onPressed: leadingOnPressed,
        iconColor: iconColor,
        onDark: effectiveOnDark,
      );
    }

    return GlassAppBar(
      surfaceStyle: GlassAppBarSurfaceStyle.fullBlur,
      backdropBlurSigma: 14,
      backdropTint: isDarkText ? const Color(0x38212523) : const Color(0x38FAFAFB),
      groupBackdrop: false,
      centerTitle: centerTitle,
      toolbarHeight: TDeviceUtils.getAppBarHeight(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      backgroundColor: backgroundColor ?? Colors.transparent,
      buttonSettings: shopToolbarGlassSettings(context, onDark: effectiveOnDark),
      leading: leadingWidget,
      title: title == null ? null : DefaultTextStyle(
        style: shopAppbarTitleStyle.copyWith(color: iconColor, fontFamily: 'BeVietnamPro'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: title!,
      ),
      bottom: bottom,
      actions: actions == null ? null : [
        for (final action in actions!) Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(child: _upgradeAction(context, action, iconColor)),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        TDeviceUtils.getAppBarHeight() + (bottom?.preferredSize.height ?? 0),
      );
}
