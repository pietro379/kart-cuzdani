import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ColorScheme'in karşılamadığı görsel öğeler için (arka plan gradyanı,
/// ışık lekeleri, parıltı, alt sekme renkleri) temaya eklenen renk seti.
@immutable
class WalletPalette extends ThemeExtension<WalletPalette> {
  const WalletPalette({
    required this.accentGradient,
    required this.glow,
    required this.backgroundColors,
    required this.blobPrimary,
    required this.blobSecondary,
    required this.sheen,
    required this.navSelected,
    required this.navUnselected,
  });

  final LinearGradient accentGradient;
  final Color glow;

  /// Arka planın yukarıdan aşağıya yumuşak gradyanı (3 renk).
  final List<Color> backgroundColors;

  /// Arka plandaki bulanık ışık lekeleri.
  final Color blobPrimary;
  final Color blobSecondary;

  /// Fırçalanmış metal hissi veren çapraz parlama bandının rengi.
  final Color sheen;

  /// Alt sekme çubuğu: seçili ve seçili olmayan ikon/yazı rengi.
  final Color navSelected;
  final Color navUnselected;

  static const dark = WalletPalette(
    accentGradient: LinearGradient(
      colors: [AppColors.darkAccent, AppColors.darkAccentMuted],
    ),
    glow: Color(0x24FFFFFF),
    backgroundColors: [Color(0xFF14171D), Color(0xFF0E1013), Color(0xFF0A0B0E)],
    // Arka planda neon mavi ışıklar (arayüz öğeleri beyaz kalır)
    blobPrimary: Color(0x3300D9FF),
    blobSecondary: Color(0x2E2F6BFF),
    sheen: Color(0x08FFFFFF),
    navSelected: AppColors.darkAccent,
    navUnselected: Color(0xFF7D8590),
  );

  static const light = WalletPalette(
    accentGradient: LinearGradient(
      colors: [AppColors.metallicSteel, AppColors.metallicGray],
    ),
    glow: Color(0x264B5563),
    // Düz beyaz yerine üstten alta soğuk gümüş geçiş
    backgroundColors: [Color(0xFFF8F9FB), Color(0xFFECEFF3), Color(0xFFDCE1E8)],
    // Sağ üstte çelik mavisi, sol altta gümüş-lila ışık
    blobPrimary: Color(0x80B4C8DE),
    blobSecondary: Color(0x66C9C6DA),
    sheen: Color(0x9EFFFFFF),
    navSelected: AppColors.lightText,
    navUnselected: Color(0xFF7B8390),
  );

  @override
  WalletPalette copyWith({
    LinearGradient? accentGradient,
    Color? glow,
    List<Color>? backgroundColors,
    Color? blobPrimary,
    Color? blobSecondary,
    Color? sheen,
    Color? navSelected,
    Color? navUnselected,
  }) => WalletPalette(
    accentGradient: accentGradient ?? this.accentGradient,
    glow: glow ?? this.glow,
    backgroundColors: backgroundColors ?? this.backgroundColors,
    blobPrimary: blobPrimary ?? this.blobPrimary,
    blobSecondary: blobSecondary ?? this.blobSecondary,
    sheen: sheen ?? this.sheen,
    navSelected: navSelected ?? this.navSelected,
    navUnselected: navUnselected ?? this.navUnselected,
  );

  @override
  WalletPalette lerp(WalletPalette? other, double t) {
    if (other == null) return this;
    return WalletPalette(
      accentGradient: LinearGradient.lerp(
        accentGradient,
        other.accentGradient,
        t,
      )!,
      glow: Color.lerp(glow, other.glow, t)!,
      backgroundColors: [
        for (var i = 0; i < backgroundColors.length; i++)
          Color.lerp(backgroundColors[i], other.backgroundColors[i], t)!,
      ],
      blobPrimary: Color.lerp(blobPrimary, other.blobPrimary, t)!,
      blobSecondary: Color.lerp(blobSecondary, other.blobSecondary, t)!,
      sheen: Color.lerp(sheen, other.sheen, t)!,
      navSelected: Color.lerp(navSelected, other.navSelected, t)!,
      navUnselected: Color.lerp(navUnselected, other.navUnselected, t)!,
    );
  }
}

extension WalletPaletteContext on BuildContext {
  WalletPalette get palette => Theme.of(this).extension<WalletPalette>()!;
}
