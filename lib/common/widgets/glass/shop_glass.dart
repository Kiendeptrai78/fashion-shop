import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

export 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Shared VELORA Liquid Glass surface powered by `liquid_glass_widgets`.
class ShopGlass extends StatelessWidget {
  static const pageBackground = Color(0xFFFAFAFB);

  /// Avoid custom glass shaders that fault Metal on physical iOS devices.
  /// Minimal keeps the glass controls, translucency and backdrop blur.
  static GlassAdaptiveScopeConfig get adaptiveConfig =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
          ? const GlassAdaptiveScopeConfig(
              initialQuality: GlassQuality.minimal,
              maxQuality: GlassQuality.minimal,
              allowStepUp: false,
            )
          : const GlassAdaptiveScopeConfig();
  const ShopGlass({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.width,
    this.height,
    this.dark,
    this.refraction = true,
    this.useOwnLayer = true,
    this.quality,
    this.color,
    this.surfaceStyle = GlassSurfaceStyle.glass,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool? dark;
  final bool refraction;
  final bool useOwnLayer;
  final GlassQuality? quality;
  final Color? color;
  final GlassSurfaceStyle surfaceStyle;

  /// Material-compatible brightness resolver for Flutter 3.29+.
  static Brightness? resolveBrightness(BuildContext context) =>
      Theme.of(context).brightness;

  /// Shared neutral optics; brand colour stays in selected labels and buttons.
  static const GlassThemeData themeData = GlassThemeData(
    style: GlassStyle.ios27,
    light: GlassThemeVariant(
      settings: GlassThemeSettings(blur: 10),
      glowColors: GlassGlowColors(primary: Colors.transparent),
    ),
    dark: GlassThemeVariant(
      settings: GlassThemeSettings(blur: 12),
      glowColors: GlassGlowColors(primary: Colors.transparent),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = dark ?? Theme.of(context).brightness == Brightness.dark;
    final accessible = MediaQuery.highContrastOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    if (accessible) {
      return GlassAccessibilityScope(
        reduceTransparency: true,
        reduceMotion: true,
        child: Container(
          width: width,
          height: height,
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? (isDark ? const Color(0xFF16291F) : Colors.white),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isDark ? Colors.white38 : const Color(0xFFCBD5CF),
            ),
          ),
          child: child,
        ),
      );
    }

    if (surfaceStyle == GlassSurfaceStyle.solid) {
      return GlassContainer.card(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        color: color,
        surfaceStyle: GlassSurfaceStyle.solid,
        shape: LiquidRoundedSuperellipse(borderRadius: radius),
        child: child,
      );
    }

    final effectiveQuality = !refraction ? GlassQuality.minimal : quality;
    final glassTint = color ??
        (isDark
            ? const Color(0x38162D22)
            : const Color(0x47FFFFFF));

    return GlassContainer(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      useOwnLayer: useOwnLayer,
      quality: effectiveQuality,
      clipBehavior: Clip.antiAlias,
      shape: LiquidRoundedSuperellipse(borderRadius: radius),
      settings: LiquidGlassSettings(
        blur: 10,
        thickness: 14,
        glassColor: glassTint,
        lightIntensity: 1.08,
        ambientStrength: isDark ? 0.42 : 0.14,
      ),
      child: child,
    );
  }
}

/// Opaque page background and an isolated glass layer scope.
class ShopGlassBackground extends StatelessWidget {
  const ShopGlassBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final wallpaper = !kIsWeb && !dark ? const ColoredBox(color: ShopGlass.pageBackground) : Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: dark
              ? const Color(0xFF0D1913)
              : (kIsWeb ? const Color(0xFFF1F6F3) : const Color(0xFFECF4EE)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-1.05, -0.88),
              radius: 1.65,
              colors: [
                dark
                    ? const Color(0xFF234B38)
                    : (kIsWeb
                        ? const Color(0xFFDCEBE1)
                        : const Color(0xFFD3E9D8)),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1.08, 0.42),
              radius: 1.35,
              colors: [
                dark
                    ? const Color(0xFF2E3220)
                    : (kIsWeb
                        ? const Color(0xFFF3ECE0)
                        : const Color(0xFFF4E9D2)),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: GlassPage(
      background: wallpaper,
      enableBackgroundSampling: !kIsWeb,
      transitionCornerRadius: 0.0,
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
      ),
    );
  }
}

/// Translucent liquid-frost decoration for list cards & rows without nested shader cost.
class ShopGlassDecoration extends BoxDecoration {
  ShopGlassDecoration({
    Color? color,
    DecorationImage? image,
    BoxBorder? border,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
    BlendMode? backgroundBlendMode,
    BoxShape shape = BoxShape.rectangle,
  }) : super(
          color: _neutralLight(color, image, gradient) ||
                  _neutralDark(color, image, gradient)
              ? null
              : color,
          image: image,
          border: border ??
              (_neutralLight(color, image, gradient)
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.92),
                      width: 1.1,
                    )
                  : _neutralDark(color, image, gradient)
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                          width: 1.0,
                        )
                      : null),
          borderRadius: borderRadius,
          boxShadow: boxShadow ??
              (_neutralLight(color, image, gradient)
                  ? const [
                      BoxShadow(
                        color: Color(0x0D173E32),
                        blurRadius: 22,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : _neutralDark(color, image, gradient)
                      ? const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ]
                      : null),
          gradient: gradient ??
              (_neutralLight(color, image, gradient)
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xEDFFFFFF), Color(0xD9FFFFFF)],
                    )
                  : _neutralDark(color, image, gradient)
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xD61E3128), Color(0xAD13211B)],
                        )
                      : null),
          backgroundBlendMode: backgroundBlendMode,
          shape: shape,
        );

  static bool _neutralLight(
    Color? color,
    DecorationImage? image,
    Gradient? gradient,
  ) {
    if (color == null || image != null || gradient != null) return false;
    final value = color.toARGB32();
    final r = (value >> 16) & 255, g = (value >> 8) & 255, b = value & 255;
    final minimum = r < g ? (r < b ? r : b) : (g < b ? g : b);
    final maximum = r > g ? (r > b ? r : b) : (g > b ? g : b);
    return (value >> 24) > 180 && minimum >= 220 && maximum - minimum < 25;
  }

  static bool _neutralDark(
    Color? color,
    DecorationImage? image,
    Gradient? gradient,
  ) {
    if (color == null || image != null || gradient != null) return false;
    final value = color.toARGB32();
    final r = (value >> 16) & 255, g = (value >> 8) & 255, b = value & 255;
    final maximum = r > g ? (r > b ? r : b) : (g > b ? g : b);
    return (value >> 24) > 180 && maximum <= 62 && (g >= r);
  }
}
