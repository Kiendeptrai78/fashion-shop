import 'package:flutter/material.dart';

class TImagePlaceholder extends StatelessWidget {
  const TImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Image unavailable',
      child: ColoredBox(
        color: colors.surfaceContainerHighest.withOpacity(0.4),
        child: Center(
          child: Icon(Icons.image_outlined, size: 28, color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}
