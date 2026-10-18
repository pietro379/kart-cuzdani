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
  static const _biometricUnlockKey = 'pref.biometric_unlock';

  final KeyValueStore _store;

  String _userName = '';
  bool _maskCardNumbers = true;
  bool _biometricUnlock = false;

  String get userName => _userName;

  /// Açıkken kart numaraları `**** **** **** 1234` şeklinde gösterilir.
  /// Güvenlik için varsayılan olarak açıktır.
  bool get maskCardNumbers => _maskCardNumbers;

  /// Açıkken kilit ekranı parmak izi / yüz ile açılabilir. PIN her zaman geçerlidir.
  /// Varsayılan olarak kapalıdır; açmak için doğrulama gerekir.
  bool get biometricUnlock => _biometricUnlock;

  Future<void> load() async {
    _userName = await _store.read(_userNameKey) ?? '';
    _maskCardNumbers = await _store.read(_maskCardNumbersKey) != 'false';
    _biometricUnlock = await _store.read(_biometricUnlockKey) == 'true';
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

  Future<void> setBiometricUnlock(bool value) async {
    _biometricUnlock = value;
    notifyListeners();
    await _store.write(_biometricUnlockKey, '$value');
  }

  /// Tüm veriler silindikten sonra bellekteki durumu da varsayılana döndürür.
  void reset() {
    _userName = '';
    _maskCardNumbers = true;
    _biometricUnlock = false;
    notifyListeners();
  }
}
