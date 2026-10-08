import 'package:flutter/foundation.dart';

import '../services/secure_store.dart';

/// Uygulama genelindeki kullanıcı tercihleri (global state).
///
/// Dinleyen tüm ekranlar (örn. kart listesi) değişiklikte otomatik yeniden çizilir.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store);

  static const maxUserNameLength = 40;

  static const _userNameKey = 'profile.user_name';
  static const _maskCardNumbersKey = 'pref.mask_card_numbers';

  final KeyValueStore _store;

  String _userName = '';
  bool _maskCardNumbers = true;

  String get userName => _userName;

  /// Açıkken kart numaraları `**** **** **** 1234` şeklinde gösterilir.
  /// Güvenlik için varsayılan olarak açıktır.
  bool get maskCardNumbers => _maskCardNumbers;

  Future<void> load() async {
    _userName = await _store.read(_userNameKey) ?? '';
    _maskCardNumbers = await _store.read(_maskCardNumbersKey) != 'false';
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    _userName = trimmed.length > maxUserNameLength
        ? trimmed.substring(0, maxUserNameLength)
        : trimmed;
    notifyListeners();
    await _store.write(_userNameKey, _userName);
  }

  Future<void> setMaskCardNumbers(bool value) async {
    _maskCardNumbers = value;
    notifyListeners();
    await _store.write(_maskCardNumbersKey, '$value');
  }

  /// Tüm veriler silindikten sonra bellekteki durumu da varsayılana döndürür.
  void reset() {
    _userName = '';
    _maskCardNumbers = true;
    notifyListeners();
  }
}
