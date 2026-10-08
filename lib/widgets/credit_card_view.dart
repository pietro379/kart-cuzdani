import 'dart:math';

import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../theme/card_swatches.dart';

/// Gerçek kart oranında (ISO/IEC 7810 ID-1) cüzdan kartı.
///
/// Tasarım: seçilen kart renginde (düz veya gradyan) zemin; ortasından
/// akan üç katmanlı "ipek şerit" ve üzerinde ince kontur çizgileri,
/// seçilen desen renginde. Gösterilecek metinler hazır verilir; maskeleme
/// kararı çağıranındır.
class CreditCardView extends StatelessWidget {
  const CreditCardView({
    super.key,
    required this.background,
    required this.accent,
    required this.name,
    required this.numberText,
    required this.expiryText,
    required this.holderName,
    this.brand = CardBrand.unknown,
  });

  static const aspectRatio = 85.6 / 53.98;

  final CardSwatch background;
  final CardSwatch accent;
  final String name;
  final String numberText;
  final String expiryText;
  final String holderName;
  final CardBrand brand;

  @override
  Widget build(BuildContext context) {
    final fg = background.foreground;
    final muted = fg.withValues(alpha: 0.68);
    final small = TextStyle(
      color: muted,
      fontSize: 11,
      letterSpacing: 1.1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    // Hero/çevirme animasyonlarında metinler Material dışında kalmasın diye.
    return Material(
      type: MaterialType.transparency,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: CardSurface(
          background: background,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: SilkWavePainter(accent)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _TwoToneName(name: name, color: fg),
                        ),
                        BrandMark(brand: brand, color: fg),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      holderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small,
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              numberText,
                              style: TextStyle(
                                color: fg,
                                fontSize: 30,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                                height: 1,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.contactless_outlined,
                              color: fg.withValues(alpha: 0.85),
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text('SKT $expiryText', style: small),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartın ön ve arka yüzünün ortak zemini: renk, köşe, kenar ve gölge.
class CardSurface extends StatelessWidget {
  const CardSurface({super.key, required this.background, required this.child});

  final CardSwatch background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background.isGradient ? null : background.colors.single,
        gradient: background.isGradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: background.colors,
              )
            : null,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: background.foreground.withValues(alpha: 0.10),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// "Maaş Kartı" → **Maaş** Kartı (ilk kelime kalın, devamı ince)
class _TwoToneName extends StatelessWidget {
  const _TwoToneName({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final space = name.indexOf(' ');
    final first = space == -1 ? name : name.substring(0, space);
    final rest = space == -1 ? '' : name.substring(space);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: first,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: rest,
            style: TextStyle(
              fontWeight: FontWeight.w300,
              color: color.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 17, letterSpacing: -0.2),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.brand, required this.color});

  final CardBrand brand;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (brand == CardBrand.mastercard) {
      // İç içe geçmiş iki daire
      return SizedBox(
        width: 30,
        height: 18,
        child: Stack(
          children: [
            _dot(color.withValues(alpha: 0.85), left: 0),
            _dot(color.withValues(alpha: 0.45), left: 12),
          ],
        ),
      );
    }
    return Text(
      brand.label,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _dot(Color color, {required double left}) => Positioned(
    left: left,
    child: Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}

/// Kartın ortasından akan üç katmanlı ipek şerit + üzerinde ince kontur
/// çizgileri. Numara ve yazıların bulunduğu üst ve alt bölgeler boş kalır.
class SilkWavePainter extends CustomPainter {
  const SilkWavePainter(this.accent);

  final CardSwatch accent;

  static const _ribbonOpacity = [0.32, 0.6, 0.95];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Arkadan öne: en soluk şerit önce çizilir.
    for (var k = 2; k >= 0; k--) {
      final base = h * (0.40 + k * 0.07);
      final amp = h * (0.09 - k * 0.015);
      final phase = k * 0.9;
      final freq = 1.15 + k * 0.15;
      final thickness = h * (0.14 - k * 0.025);

      double top(double x) => base + amp * sin(2 * pi * freq * x / w + phase);
      double bottom(double x) =>
          top(x) +
          thickness * (0.55 + 0.45 * sin(2 * pi * 0.8 * x / w + phase + 1.3));

      final path = Path()..moveTo(0, top(0));
      for (var x = 0.0; x <= w; x += 3) {
        path.lineTo(x, top(x));
      }
      for (var x = w; x >= 0; x -= 3) {
        path.lineTo(x, bottom(x));
      }
      path.close();
      canvas.drawPath(
        path,
        accent.paintFor(rect, opacity: _ribbonOpacity[2 - k]),
      );
    }

    // Şeritlerin altında, onları izleyen ince kontur çizgileri
    // (üstteki isim satırının okunurluğunu bozmamak için aşağıda)
    for (var i = 0; i < 5; i++) {
      final base = h * (0.66 + i * 0.026);
      final amp = h * 0.06 * (1 - i * 0.12);
      final line = Path()..moveTo(0, base + amp * sin(0));
      for (var x = 0.0; x <= w; x += 3) {
        line.lineTo(x, base + amp * sin(2 * pi * 1.15 * x / w + i * 0.12));
      }
      canvas.drawPath(
        line,
        accent.paintFor(rect, opacity: 0.38 - i * 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(SilkWavePainter old) => old.accent != accent;
}
