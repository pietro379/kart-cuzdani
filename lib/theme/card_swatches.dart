import 'package:flutter/material.dart';

/// Kart tasarımında seçilebilen tek bir renk: düz renk (1 renk) veya gradyan.
@immutable
class CardSwatch {
  const CardSwatch({
    required this.id,
    required this.name,
    required this.colors,
  });

  /// Kartla birlikte saklanan kalıcı kimlik; değiştirilmemeli.
  final String id;
  final String name;
  final List<Color> colors;

  bool get isGradient => colors.length > 1;

  /// Boyanacak alana göre fırça (düz renk veya çapraz gradyan).
  Paint paintFor(Rect rect, {double opacity = 1}) {
    final paint = Paint();
    if (isGradient) {
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [for (final c in colors) c.withValues(alpha: c.a * opacity)],
      ).createShader(rect);
    } else {
      paint.color = colors.single.withValues(alpha: colors.single.a * opacity);
    }
    return paint;
  }

  Decoration get decoration => isGradient
      ? BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        )
      : BoxDecoration(color: colors.single);

  /// Zeminin üzerindeki yazı rengi: açık zeminde koyu, koyu zeminde beyaz.
  Color get foreground {
    final luminance =
        colors.map((c) => c.computeLuminance()).reduce((a, b) => a + b) /
        colors.length;
    final light = (luminance + 0.05) * (luminance + 0.05) > 0.15;
    return light ? const Color(0xFF15181D) : Colors.white;
  }
}

abstract final class CardSwatches {
  // --- Kart (zemin) renkleri ---------------------------------------------

  static const defaultBackgroundId = 'graphite';

  static const backgroundGradients = [
    CardSwatch(
      id: 'neon',
      name: 'Neon Mavi',
      colors: [Color(0xFF2F6BFF), Color(0xFF0B1A3A)],
    ),
    CardSwatch(
      id: 'midnight',
      name: 'Gece Moru',
      colors: [Color(0xFF2C1B69), Color(0xFF0F0A24)],
    ),
    CardSwatch(
      id: 'emerald',
      name: 'Zümrüt',
      colors: [Color(0xFF0B6E4F), Color(0xFF06281D)],
    ),
    CardSwatch(
      id: 'sunset',
      name: 'Gün Batımı',
      colors: [Color(0xFFE52E71), Color(0xFF4A0D2E)],
    ),
    CardSwatch(
      id: 'graphite',
      name: 'Grafit',
      colors: [Color(0xFF1F2937), Color(0xFF0B0F14)],
    ),
    CardSwatch(
      id: 'gold',
      name: 'Altın',
      colors: [Color(0xFFC99A2E), Color(0xFF5C4210)],
    ),
    CardSwatch(
      id: 'rose',
      name: 'Gül',
      colors: [Color(0xFFD45D79), Color(0xFF4A1C2A)],
    ),
    CardSwatch(
      id: 'silver',
      name: 'Gümüş',
      colors: [Color(0xFFC5CBD3), Color(0xFF8E96A3)],
    ),
  ];

  static const backgroundSolids = [
    CardSwatch(id: 'bg_black', name: 'Siyah', colors: [Color(0xFF111317)]),
    CardSwatch(id: 'bg_navy', name: 'Lacivert', colors: [Color(0xFF14213D)]),
    CardSwatch(id: 'bg_burgundy', name: 'Bordo', colors: [Color(0xFF5A1426)]),
    CardSwatch(id: 'bg_forest', name: 'Orman', colors: [Color(0xFF1E4D3A)]),
    CardSwatch(
      id: 'bg_terracotta',
      name: 'Kiremit',
      colors: [Color(0xFFB4532A)],
    ),
    CardSwatch(id: 'bg_slate', name: 'Arduvaz', colors: [Color(0xFF6B7280)]),
    CardSwatch(id: 'bg_cream', name: 'Krem', colors: [Color(0xFFF1E9DA)]),
    CardSwatch(id: 'bg_white', name: 'Beyaz', colors: [Color(0xFFF7F7F5)]),
  ];

  static const backgrounds = [...backgroundGradients, ...backgroundSolids];

  // --- Desen renkleri ----------------------------------------------------

  static const defaultAccentId = 'ac_white';

  static const accentGradients = [
    CardSwatch(
      id: 'aurora',
      name: 'Kutup Işığı',
      colors: [Color(0xFF00C896), Color(0xFF00D9FF)],
    ),
    CardSwatch(
      id: 'electric',
      name: 'Elektrik',
      colors: [Color(0xFF00D9FF), Color(0xFF7F5AF0)],
    ),
    CardSwatch(
      id: 'flame',
      name: 'Alev',
      colors: [Color(0xFFFF8A00), Color(0xFFE52E71)],
    ),
    CardSwatch(
      id: 'peach',
      name: 'Şeftali',
      colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
    ),
    CardSwatch(
      id: 'holo',
      name: 'Hologram',
      colors: [Color(0xFFA1C4FD), Color(0xFFC2E9FB), Color(0xFFFBC2EB)],
    ),
    CardSwatch(
      id: 'ice',
      name: 'Buz',
      colors: [Color(0xFFE0EAFC), Color(0xFF9FB4D0)],
    ),
  ];

  static const accentSolids = [
    CardSwatch(id: 'ac_white', name: 'Beyaz', colors: [Color(0xFFFFFFFF)]),
    CardSwatch(id: 'ac_black', name: 'Siyah', colors: [Color(0xFF111111)]),
    CardSwatch(id: 'ac_cyan', name: 'Neon Mavi', colors: [Color(0xFF00D9FF)]),
    CardSwatch(id: 'ac_mint', name: 'Mint', colors: [Color(0xFF00C896)]),
    CardSwatch(id: 'ac_orange', name: 'Turuncu', colors: [Color(0xFFFF6B35)]),
    CardSwatch(id: 'ac_pink', name: 'Pembe', colors: [Color(0xFFFF4D8D)]),
    CardSwatch(id: 'ac_gold', name: 'Altın', colors: [Color(0xFFD4AF37)]),
    CardSwatch(id: 'ac_purple', name: 'Mor', colors: [Color(0xFF7F5AF0)]),
    CardSwatch(id: 'ac_steel', name: 'Çelik', colors: [Color(0xFF9CA3AF)]),
  ];

  static const accents = [...accentGradients, ...accentSolids];

  /// Eski sürümde tek renk seçimi (colorId) vardı; o kartların desen rengi.
  static const legacyAccentFor = {
    'neon': 'ac_cyan',
    'midnight': 'ac_purple',
    'emerald': 'ac_mint',
    'sunset': 'ac_orange',
    'graphite': 'ac_steel',
    'gold': 'ac_gold',
    'rose': 'ac_pink',
    'silver': 'ac_white',
  };

  /// Bilinmeyen kimlikte varsayılana döner.
  static CardSwatch background(String id) => backgrounds.firstWhere(
    (s) => s.id == id,
    orElse: () => backgrounds.first,
  );

  static CardSwatch accent(String id) =>
      accents.firstWhere((s) => s.id == id, orElse: () => accents.first);
}
