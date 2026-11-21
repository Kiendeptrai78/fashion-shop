import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fashion_business_app/utils/localization/shop_locale.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const background = Color(0xFF173E32);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 650));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) { _intro.value = 1; }
    else { _intro.forward(); }
  }
  @override
  void dispose() { _intro.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(backgroundColor: SplashScreen.background, body: SafeArea(
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _SplashLines())),
        Center(child: FadeTransition(opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
          child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('S', style: TextStyle(fontSize: 86, height: 1,
                  fontWeight: FontWeight.w700, color: Color(0xFFDDEABB), letterSpacing: -5)),
              const SizedBox(height: 26),
              const Text('SNEAKERS', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600,
                  color: Colors.white, letterSpacing: 5)),
              const SizedBox(height: 16),
              const ShopText('Find your next favorite pair.', style: TextStyle(color: Colors.white70,
                  fontSize: 13, letterSpacing: 0.3)),
            ]),
          ),
        )),
        Positioned(left: 24, right: 24, bottom: 32, child: Column(children: [
          SizedBox(width: 76, child: LinearProgressIndicator(minHeight: 2, value: MediaQuery.disableAnimationsOf(context) ? 0.65 : null,
              color: Color(0xFFDDEABB), backgroundColor: Colors.white12)),
          SizedBox(height: 18),
          ShopText('Getting things ready...', style: TextStyle(fontSize: 11, color: Colors.white54)),
        ])),
      ]),
    )),
  );
}

class _SplashLines extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke..strokeWidth = 1;
    for (var index = 0; index < 3; index++) {
      canvas.drawCircle(Offset(size.width * 1.1, size.height * 0.2), size.width * (0.75 + index * 0.23), paint);
    }
  }
  @override
  bool shouldRepaint(_SplashLines oldDelegate) => false;
}
