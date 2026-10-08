import 'package:flutter/material.dart';

import '../theme/wallet_palette.dart';

/// Sade, modern arka plan: yumuşak dikey gradyan ve üzerinde iki büyük,
/// bulanık ışık lekesi (sağ üstte ve sol altta).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.backgroundColors,
        ),
      ),
      child: CustomPaint(
        painter: _GlowPainter(
          primary: palette.blobPrimary,
          secondary: palette.blobSecondary,
          sheen: palette.sheen,
        ),
        child: child,
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter({
    required this.primary,
    required this.secondary,
    required this.sheen,
  });

  final Color primary;
  final Color secondary;
  final Color sheen;

  @override
  void paint(Canvas canvas, Size size) {
    void blob(Offset center, double radius, Color color) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(rect),
      );
    }

    final s = size.shortestSide;
    blob(Offset(size.width * 0.95, size.height * 0.08), s * 0.9, primary);
    blob(Offset(size.width * 0.05, size.height * 0.88), s * 0.85, secondary);

    // Sol üstten sağ alta uzanan, fırçalanmış metal gibi ince parlama bandı
    final transparent = sheen.withValues(alpha: 0);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [transparent, sheen, transparent, sheen, transparent],
          stops: const [0.18, 0.34, 0.46, 0.58, 0.78],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.primary != primary ||
      old.secondary != secondary ||
      old.sheen != sheen;
}
