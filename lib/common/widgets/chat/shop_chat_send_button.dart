import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../glass/shop_glass.dart';

/// Solid action inside the glass composer, with readable resting and busy states.
class ShopChatSendButton extends StatelessWidget {
  const ShopChatSendButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => GlassIconButton(
    size: 42,
    iconSize: 21,
    useOwnLayer: true,
    surfaceStyle: GlassSurfaceStyle.solid,
    color: const Color(0xFF173E32),
    iconColor: Colors.white,
    glowColor: Colors.transparent,
    semanticLabel: Localizations.localeOf(context).languageCode == 'en' ? 'Send message' : 'Gửi tin nhắn',
    onPressed: onPressed,
    icon: onPressed == null
        ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 21),
  );
}
