# VELORA Liquid Glass (`liquid_glass_widgets`)

VELORA uses [`liquid_glass_widgets`](https://pub.dev/packages/liquid_glass_widgets) (v1.21.0, vendored in `third_party/liquid_glass_widgets` with Flutter 3.29.3 compatibility patches) across both the Mobile App and the Admin Web Portal.

## Architecture

1. **Initialization & Theme (`lib/main.dart`, `lib/app.dart`)**:
   - `LiquidGlassWidgets.initialize()` preloads fragment shader bytecode in parallel at startup.
   - `LiquidGlassWidgets.wrap(...)` configures `adaptiveQuality: true`, `respectSystemAccessibility: true`, `brightnessResolver: ShopGlass.resolveBrightness`, and `ShopGlass.themeData` (`GlassStyle.ios27` with VELORA botanical glow colors).
   - `ShopPageTransition` wraps each GetX page in its own `ShopGlassBackground` before applying the platform's native transition. Each moving page has an opaque wallpaper and its own glass capture scope, so transparent scaffolds do not reveal the previous page. The outer app scope also supplies glass to popup routes.

2. **Floating Chrome vs. Scrolling Content**:
   - **Floating navigation & interactive controls** use `liquid_glass_widgets` components: `GlassTabBar.bottom` (`NavigationMenu`), `GlassContainer` (`ShopGlass`, `TAppbar`, `TTabBar`, `TSearchContainer`, bottom Cart/Checkout/Add-to-Bag/Chat docks, Admin Web topbar & login platter), `GlassButton` / `GlassIconButton` (toolbar icons, AI Stylist FAB, category & quick-shortcut pills, `AdminPrimaryButton`), `GlassSegmentedControl` (Admin Web VI/EN & VND/USD switchers), `GlassDialog` (`showVeloraConfirmDialog` & `showAdminConfirmDialog`), and `GlassProgressIndicator` (`TFullScreenLoader`).
   - **Scrolling content cards & list rows** use `ShopGlassDecoration` / `GlassSurfaceStyle.solid` so list cards stay legible at 60fps without nested double-refraction.
   - Mobile pages use an opaque white background in light mode. The bottom `GlassTabBar` uses a clear lens (`frost: 0`), 1.01 press scale, 1.02 glyph magnification, and a bottom gap of `max(12, viewPadding.bottom - 10)`. All tabs keep the same outer body extent; Chat reserves composer space inside its body. Switching tabs clears input focus. A keyed repaint boundary isolates each tab's body.
   - Home, Featured, Store, Orders, and Returns use `ShopFilterTabs`, backed by `GlassSegmentedControl.scrollable`, retaining red count badges. `SegmentDragBehavior.scroll` scrolls the strip without selecting a different filter; taps select. There are no paging arrows.
   - Back controls use `GlassButton` with `CupertinoIcons.back`, following the package's GlassAppBar example. The shared light toolbar tint is translucent white.
   - Featured video fills the viewport behind the top controls and bottom navigation; both regions are transparent with light foregrounds. Other mobile pages retain white backgrounds.

## Flutter 3.29 iOS compatibility

The iOS deployment target is 15.0, matching the vendored plugin's podspec.
Flutter 3.29's `FlutterPluginRegistrar` does not expose `viewController`.
`LiquidGlassWidgetsPlugin.observe()` gets the root view through Runner's existing
`FlutterAppDelegate.window` instead. The reserved-region observer is unchanged.
This fallback follows this app's single-window FlutterAppDelegate setup.

The geometry shader omits the unused `uSize` uniform, and the Dart renderer writes
the compact 119-float layout on every backend. Keeping the unused uniform made
Metal expose 119 floats while Dart wrote 121. Retaining it with a bounds check
clipped translated geometry because fragment coordinates are in scene space,
not the capture texture's local bounds. The regression test paints a translated
glass shape and checks its right edge. Check the compiled GPU layout with:

```sh
python3 tool/check_glass_geometry_shader.py /path/to/flutter/bin/cache/artifacts/engine/darwin-x64/impellerc
```

This check also compiles Vulkan; widget tests alone exercise SkSL and do not
reproduce Metal's uniform elimination.
