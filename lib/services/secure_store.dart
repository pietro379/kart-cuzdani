import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Uygulamanın kullandığı anahtar-değer deposu soyutlaması.
/// Testlerde bellek içi bir sürümle değiştirilebilsin diye arayüz olarak tanımlı.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);

  /// Uygulamanın sakladığı her şeyi kalıcı olarak siler.
  Future<void> deleteAll();
}

/// Tüm verileri cihaz üzerinde şifreli tutan depo.
///
/// - Android: Veriler AES-GCM ile şifrelenir, anahtar Android Keystore'da
///   (donanım destekli) RSA-OAEP ile korunur.
/// - iOS: Keychain'de, yalnızca cihaz kilidi açıkken erişilebilir ve
///   `this_device` olduğu için iCloud'a / başka cihaza taşınmaz.
///
/// Hiçbir veri ağ üzerinden gönderilmez.
class SecureKeyValueStore implements KeyValueStore {
  SecureKeyValueStore()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.unlocked_this_device,
          synchronizable: false,
        ),
      );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
