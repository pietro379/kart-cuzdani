import 'package:flutter/material.dart';

import '../services/secure_store.dart';

/// Seçili tema modunu (sistem / açık / koyu) tutar ve cihazda saklar.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController(this._store) : super(ThemeMode.system);

  static const _key = 'pref.theme_mode';

  final KeyValueStore _store;

  Future<void> load() async {
    final saved = await _store.read(_key);
    value = ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    await _store.write(_key, mode.name);
  }

  /// Ayarlar'daki Koyu/Açık anahtarı için.
  Future<void> setDark(bool dark) =>
      setMode(dark ? ThemeMode.dark : ThemeMode.light);

  /// Tüm veriler silindikten sonra bellekteki durumu varsayılana döndürür.
  void reset() => value = ThemeMode.system;
}
