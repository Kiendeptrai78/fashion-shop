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
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFDDEABB).withValues(alpha: 0.28), width: 1.5),
                ),
                child: const Text('V', style: TextStyle(fontSize: 58, height: 1,
                    fontWeight: FontWeight.w700, color: Color(0xFFDDEABB), letterSpacing: -2)),
              ),
              const SizedBox(height: 24),
              const Text('VELORA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: 6)),
              const SizedBox(height: 12),
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
