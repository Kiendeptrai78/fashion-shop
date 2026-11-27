import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'shop_glass.dart';

/// Each moving route owns an opaque wallpaper and its glass capture scope.
class ShopPageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final route = ModalRoute.of(context)! as PageRoute<dynamic>;
    return const PageTransitionsTheme().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      ShopGlassBackground(child: child),
    );
  }
}
