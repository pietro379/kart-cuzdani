import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// PIN'i rastgele tuz ile PBKDF2-HMAC-SHA256 kullanarak özetler.
///
/// PIN'in kendisi hiçbir yerde saklanmaz; yalnızca şu formatta bir kayıt tutulur:
/// `pbkdf2-sha256$<iterasyon>$<tuz (base64)>$<özet (base64)>`
/// İterasyon sayısı kayıtla birlikte saklandığı için ileride artırılabilir.
class PinHasher {
  const PinHasher({
    this.iterations = defaultIterations,
    this.runInBackground = true,
  });

  static const defaultIterations = 100000;

  static const _scheme = 'pbkdf2-sha256';
  static const _saltLength = 16;
  static const _hashBits = 256;

  final int iterations;

  /// Hesaplama ayrı bir isolate'te yapılır ki arayüz donmasın.
  /// Widget testleri gerçek isolate bekleyemediği için orada kapatılır.
  final bool runInBackground;

  Future<String> hash(String pin) async {
    final random = Random.secure();
    final salt = List<int>.generate(_saltLength, (_) => random.nextInt(256));
    final digest = await _derive(pin, salt, iterations);
    return [
      _scheme,
      '$iterations',
      base64Encode(salt),
      base64Encode(digest),
    ].join(r'$');
  }

  /// Kayıt bozuksa veya tanınmıyorsa `false` döner.
  Future<bool> verify(String pin, String record) async {
    final parts = record.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds <= 0) return false;

    final List<int> salt;
    final List<int> expected;
    try {
      salt = base64Decode(parts[2]);
      expected = base64Decode(parts[3]);
    } on FormatException {
      return false;
    }

    final actual = await _derive(pin, salt, rounds);
    return constantTimeEquals(actual, expected);
  }

  Future<List<int>> _derive(String pin, List<int> salt, int rounds) {
    Future<List<int>> compute() => _pbkdf2(pin, salt, rounds);
    return runInBackground ? Isolate.run(compute) : compute();
  }

  static Future<List<int>> _pbkdf2(
    String pin,
    List<int> salt,
    int rounds,
  ) async {
    final key = await Pbkdf2.hmacSha256(
      iterations: rounds,
      bits: _hashBits,
    ).deriveKeyFromPassword(password: pin, nonce: salt);
    return key.extractBytes();
  }

  /// Karşılaştırma süresinden bilgi sızmaması için
  /// ilk farklı baytta erken çıkmayan karşılaştırma.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
