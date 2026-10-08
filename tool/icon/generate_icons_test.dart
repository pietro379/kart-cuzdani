// Uygulama ikonunu (Android + iOS) Flutter'ın kendi çizim motoruyla üretir.
// Yeni bir paket gerektirmez. Proje kökünden çalıştırın:
//
//   flutter test tool/icon/generate_icons_test.dart
//
// Üretilenler:
// - Android: mipmap-*/ic_launcher.png (eski cihazlar),
//   ic_launcher_foreground/background/monochrome.png (adaptif + temalı ikon)
// - iOS: AppIcon.appiconset içindeki tüm boyutlar (Contents.json'dan okunur)
// - Önizleme: build/icon_preview.png
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _androidRes = 'android/app/src/main/res';
const _iosIconSet = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

/// Eski tip ikon (dp=48) ve adaptif katman (dp=108) yoğunlukları.
const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

// --- Renkler (uygulamanın koyu temasıyla aynı) ------------------------------
const _bgTop = Color(0xFF1B1F27);
const _bgBottom = Color(0xFF0A0B0E);
const _neon = Color(0xFF00D9FF);
const _deepBlue = Color(0xFF2F6BFF);

/// Zemin: koyu grafit gradyan + sağ üstte neon mavi, sol altta koyu mavi ışık.
void paintBackground(Canvas canvas, Size size) {
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_bgTop, _bgBottom],
      ).createShader(rect),
  );
  void glow(Offset center, double radius, Color color) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  final s = size.width;
  glow(Offset(s * 0.88, s * 0.10), s * 0.80, _neon.withValues(alpha: 0.45));
  glow(Offset(s * 0.08, s * 0.95), s * 0.70, _deepBlue.withValues(alpha: 0.35));
}

/// Üst üste iki kart: arkada neon mavi gradyan, önde grafit kart üzerinde
/// beyaz ipek şerit ve gümüş çip. [box]: içeriğin sığacağı kare alan.
void paintCards(Canvas canvas, Rect box, {bool monochrome = false}) {
  final c = box.width;
  final w = c * 0.80;
  final h = w / 1.586;
  final radius = Radius.circular(c * 0.085);

  void card(Offset center, double angle, void Function(RRect r) paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    paint(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        radius,
      ),
    );
    canvas.restore();
  }

  // Arka kart
  card(box.topLeft + Offset(c * 0.56, c * 0.40), -0.24, (r) {
    canvas.drawRRect(
      r,
      Paint()
        ..shader = monochrome
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_neon, _deepBlue],
              ).createShader(r.outerRect)
        ..color = const Color(0xFFFFFFFF)
            .withValues(alpha: monochrome ? 0.55 : 1),
    );
  });

  // Ön kart
  card(box.topLeft + Offset(c * 0.47, c * 0.60), -0.06, (r) {
    if (!monochrome) {
      canvas.drawRRect(
        r.shift(Offset(0, c * 0.025)),
        Paint()
          ..color = const Color(0x66000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, c * 0.03),
      );
    }
    canvas.drawRRect(
      r,
      Paint()
        ..shader = monochrome
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E3440), Color(0xFF12151B)],
              ).createShader(r.outerRect)
        ..color = const Color(0xFFFFFFFF),
    );
    if (monochrome) return;

    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = c * 0.008
        ..color = const Color(0x33FFFFFF),
    );

    canvas.save();
    canvas.clipRRect(r);
    final rect = r.outerRect;

    // İpek şeritler
    for (final (offset, thickness, alpha) in [
      (0.20, 0.16, 0.45),
      (0.05, 0.20, 1.0),
    ]) {
      final path = Path();
      double top(double x) =>
          rect.center.dy +
          rect.height * offset +
          rect.height * 0.16 * sin((x - rect.left) / rect.width * 2 * pi * 0.9);
      path.moveTo(rect.left, top(rect.left));
      for (var x = rect.left; x <= rect.right; x += rect.width / 60) {
        path.lineTo(x, top(x));
      }
      for (var x = rect.right; x >= rect.left; x -= rect.width / 60) {
        path.lineTo(
          x,
          top(x) +
              rect.height *
                  thickness *
                  (0.6 + 0.4 * sin((x - rect.left) / rect.width * 2 * pi)),
        );
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: alpha),
      );
    }

    // Çip
    final chip = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.left + rect.width * 0.10,
        rect.top + rect.height * 0.18,
        rect.width * 0.17,
        rect.height * 0.20,
      ),
      Radius.circular(c * 0.018),
    );
    canvas.drawRRect(
      chip,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE6E9EE), Color(0xFF9AA3AF)],
        ).createShader(chip.outerRect),
    );
    canvas.restore();
  });
}

Future<void> writePng(
  String path,
  int size,
  void Function(Canvas canvas, Size size) draw,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  draw(canvas, Size(size.toDouble(), size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// Eski Android cihazlar için: yuvarlatılmış kare, köşeler şeffaf.
void legacyIcon(Canvas canvas, Size size) {
  final rrect = RRect.fromRectAndRadius(
    Offset.zero & size,
    Radius.circular(size.width * 0.22),
  );
  canvas.save();
  canvas.clipRRect(rrect);
  paintBackground(canvas, size);
  paintCards(canvas, _contentBox(size, 0.80));
  canvas.restore();
}

/// iOS: tam dolu kare (iOS köşeleri kendisi yuvarlar; şeffaflık olmamalı).
void iosIcon(Canvas canvas, Size size) {
  paintBackground(canvas, size);
  paintCards(canvas, _contentBox(size, 0.80));
}

/// Adaptif ikonun ön katmanı: içerik, maskelerin kesmediği güvenli alanda.
void adaptiveForeground(Canvas canvas, Size size) =>
    paintCards(canvas, _contentBox(size, 0.58));

void adaptiveMonochrome(Canvas canvas, Size size) =>
    paintCards(canvas, _contentBox(size, 0.58), monochrome: true);

Rect _contentBox(Size size, double fraction) => Rect.fromCenter(
  center: size.center(Offset.zero),
  width: size.width * fraction,
  height: size.height * fraction,
);

void main() {
  test('uygulama ikonlarını üret', () async {
    for (final MapEntry(key: density, value: scale) in _densities.entries) {
      final dir = '$_androidRes/mipmap-$density';
      await writePng('$dir/ic_launcher.png', (48 * scale).round(), legacyIcon);
      final layer = (108 * scale).round();
      await writePng(
        '$dir/ic_launcher_foreground.png',
        layer,
        adaptiveForeground,
      );
      await writePng('$dir/ic_launcher_background.png', layer, paintBackground);
      await writePng(
        '$dir/ic_launcher_monochrome.png',
        layer,
        adaptiveMonochrome,
      );
    }

    File('$_androidRes/mipmap-anydpi-v26/ic_launcher.xml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<!-- tool/icon/generate_icons_test.dart tarafından üretildi -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
''');

    final contents = jsonDecode(
      File('$_iosIconSet/Contents.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final image in contents['images'] as List<dynamic>) {
      final entry = image as Map<String, dynamic>;
      final points = double.parse((entry['size'] as String).split('x').first);
      final scale = double.parse(
        (entry['scale'] as String).replaceAll('x', ''),
      );
      await writePng(
        '$_iosIconSet/${entry['filename']}',
        (points * scale).round(),
        iosIcon,
      );
    }

    await writePng('build/icon_preview.png', 512, legacyIcon);
    await writePng('build/icon_preview_adaptive.png', 432, (canvas, size) {
      // Android'in dairesel maskesiyle nasıl görüneceği
      canvas.clipPath(Path()..addOval(Offset.zero & size));
      paintBackground(canvas, size);
      adaptiveForeground(canvas, size);
    });
  });
}
