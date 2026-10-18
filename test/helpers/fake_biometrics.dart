import 'package:add_card_app/services/biometric_authenticator.dart';

/// Testlerde gerçek sensör yerine kullanılan sahte biyometrik doğrulayıcı.
class FakeBiometrics implements BiometricAuthenticator {
  FakeBiometrics({this.available = true, this.succeeds = true});

  bool available;
  bool succeeds;

  /// `authenticate` kaç kez çağrıldı ve son gösterilen gerekçe.
  int attempts = 0;
  String? lastReason;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    attempts++;
    lastReason = reason;
    return succeeds;
  }
}
