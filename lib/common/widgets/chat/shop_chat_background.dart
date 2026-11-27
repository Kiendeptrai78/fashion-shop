import 'package:flutter/material.dart';

/// A tonal sneaker wallpaper shared by AI and customer support conversations.
class ShopChatBackground extends StatelessWidget {
  const ShopChatBackground({super.key, required this.child});
  static const lightColor = Color(0xFFE8EFE8);
  static const darkColor = Color(0xFF14201C);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: dark ? darkColor : lightColor,
      child: CustomPaint(
        painter: _ChatPaper(dark),
        child: child,
      ),
    );
  }
}

class _ChatPaper extends CustomPainter {
  const _ChatPaper(this.dark);
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = dark ? const Color(0x245DD0A1) : const Color(0x2E567461)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final shoe = Path()
      ..moveTo(-20, 4)..lineTo(-18, -7)..lineTo(-10, -4)..lineTo(-5, -9)
      ..quadraticBezierTo(0, -1, 10, 0)..quadraticBezierTo(21, 1, 22, 7)
      ..lineTo(22, 11)..lineTo(-19, 11)..close()
      ..moveTo(-19, 7)..lineTo(21, 7)
      ..moveTo(-5, -4)..lineTo(-8, 1)
      ..moveTo(0, -2)..lineTo(-3, 3)
      ..moveTo(5, 0)..lineTo(2, 4);
    var row = 0;
    for (double y = -28; y < size.height + 80; y += 112, row++) {
      for (double x = (row.isEven ? -10 : -76); x < size.width + 70; x += 132) {
        canvas.save();
        canvas.translate(x + 32, y + 32);
        canvas.rotate(-0.3);
        canvas.drawPath(shoe, ink);
        canvas.restore();
        final bubble = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 81, y + 73, 19, 14), const Radius.circular(5));
        canvas.drawRRect(bubble, ink);
        canvas.drawPath(Path()..moveTo(x + 85, y + 87)
          ..lineTo(x + 84, y + 91)..lineTo(x + 91, y + 87), ink);
        canvas.drawCircle(Offset(x + 82, y + 30), 1, ink);
      }
    }
  }

  @override
  bool shouldRepaint(_ChatPaper oldDelegate) => dark != oldDelegate.dark;
}
