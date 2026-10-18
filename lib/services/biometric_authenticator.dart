import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

/// Parmak izi / yüz tanıma doğrulaması için ince bir arayüz.
///
/// Ekranlar `local_auth`'a doğrudan bağlanmaz; testlerde sahte bir uygulama
/// verilebilsin diye bu arayüz kullanılır.
abstract class BiometricAuthenticator {
  /// Cihazda biyometrik doğrulama destekleniyor ve en az bir kayıt var mı?
  Future<bool> isAvailable();

  /// Sistem doğrulama penceresini açar; yalnızca biyometri kabul edilir
  /// (cihaz PIN'i/deseni kabul edilmez). Başarısızlıkta, iptalde ve her
  /// hatada `false` döner: uygulama PIN ile devam edebilir.
  Future<bool> authenticate(String reason);
}

class LocalBiometricAuthenticator implements BiometricAuthenticator {
  LocalBiometricAuthenticator([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Kimliğinizi doğrulayın',
            signInHint: 'Parmak izi veya yüz',
            cancelButton: 'PIN kullan',
          ),
          IOSAuthMessages(cancelButton: 'PIN kullan'),
        ],
        biometricOnly: true,
      );
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }
}
