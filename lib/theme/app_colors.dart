import 'package:flutter/material.dart';

abstract final class AppColors {
  // Koyu tema: koyu gri + beyaz/gümüş vurgu (açık temadaki siyahın karşılığı)
  static const darkBackground = Color(0xFF0E1013);
  static const darkSurface = Color(0xFF171A1F);
  static const darkSurfaceHigh = Color(0xFF22262D);
  static const darkOutline = Color(0xFF2F353E);
  static const darkAccent = Color(0xFFF4F6F8);
  static const darkAccentMuted = Color(0xFFB4BCC8);
  static const darkText = Color(0xFFE8EDF2);
  static const darkTextMuted = Color(0xFF8A94A3);
  static const darkError = Color(0xFFFF4D6A);

  // Açık tema: temiz beyaz + metalik gri
  static const lightBackground = Color(0xFFF6F7F9);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFECEEF1);
  static const lightOutline = Color(0xFFD3D7DD);
  static const metallicSteel = Color(0xFF4B5563);
  static const metallicGray = Color(0xFF8E96A3);
  static const metallicSilver = Color(0xFFC5CBD3);
  static const lightText = Color(0xFF15181D);
  static const lightTextMuted = Color(0xFF6B7380);
  static const lightError = Color(0xFFD62C47);
}
