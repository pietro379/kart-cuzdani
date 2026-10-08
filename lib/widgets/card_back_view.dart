import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../theme/card_swatches.dart';
import 'credit_card_view.dart';

/// Kartın arka yüzü (gerçek kartlardaki gibi):
/// siyah manyetik şerit, desenli beyaz imza şeridi ve şeridin sağ ucunda CVV.
/// Kart için şifre belirlenmişse altında gösterilir.
class CardBackView extends StatelessWidget {
  const CardBackView({
    super.key,
    required this.background,
    required this.cvvText,
    this.pinText,
    this.brand = CardBrand.unknown,
  });

  final CardSwatch background;
  final String cvvText;

  /// Null ise "şifre belirlenmedi" yazar.
  final String? pinText;
  final CardBrand brand;

  @override
  Widget build(BuildContext context) {
    final fg = background.foreground;
    final muted = fg.withValues(alpha: 0.68);
    final small = TextStyle(color: muted, fontSize: 10, letterSpacing: 1.2);

    return Material(
      type: MaterialType.transparency,
      child: AspectRatio(
        aspectRatio: CreditCardView.aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            return CardSurface(
              background: background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: h * 0.09),
                  // Manyetik şerit
                  Container(height: h * 0.19, color: const Color(0xFF121212)),
                  SizedBox(height: h * 0.07),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('CVV', style: small),
                        const SizedBox(height: 3),
                        _SignatureStrip(height: h * 0.17, cvvText: cvvText),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('KART ŞİFRESİ', style: small),
                              const SizedBox(height: 2),
                              Text(
                                pinText ?? 'Belirlenmedi',
                                style: TextStyle(
                                  color: pinText == null ? muted : fg,
                                  fontSize: pinText == null ? 13 : 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: pinText == null ? 0.4 : 4,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          brand.label,
                          style: TextStyle(
                            color: fg,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Beyaz imza şeridi; sağ ucunda CVV yazılı kutu.
class _SignatureStrip extends StatelessWidget {
  const _SignatureStrip({required this.height, required this.cvvText});

  final double height;
  final String cvvText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Expanded(child: CustomPaint(painter: _SignaturePattern())),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Text(
              cvvText,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                letterSpacing: 2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gerçek imza şeritlerindeki ince çapraz güvenlik deseni.
class _SignaturePattern extends CustomPainter {
  const _SignaturePattern();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1A3A6EA5)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SignaturePattern old) => false;
}
