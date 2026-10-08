import 'pin_hasher.dart';
import 'secure_store.dart';

enum PinCheckResult { success, wrong, lockedOut }

class PinVerification {
  const PinVerification(
    this.result, {
    this.remainingAttempts = 0,
    this.lockoutRemaining = Duration.zero,
  });

  final PinCheckResult result;
  final int remainingAttempts;
  final Duration lockoutRemaining;
}

/// PIN oluşturma, doğrulama ve kaba kuvvet (brute-force) korumasını yönetir.
///
/// PIN'in kendisi saklanmaz; yalnızca tuzlu PBKDF2 özeti ([PinHasher]) şifreli
/// depoda tutulur. Art arda [maxAttempts] hatalı denemeden sonra giriş
/// [lockoutDuration] boyunca kilitlenir; kilit süresi de depoda tutulduğu için
/// uygulamayı kapatıp açmak kilidi sıfırlamaz.
class PinService {
  PinService(this._store, {PinHasher? hasher, DateTime Function()? clock})
    : _hasher = hasher ?? const PinHasher(),
      _clock = clock ?? DateTime.now;

  static const pinLength = 6;
  static const maxAttempts = 5;
  static const lockoutDuration = Duration(seconds: 30);

  static const _pinHashKey = 'auth.pin_hash';
  // İlk sürümde PIN özetlenmeden saklanıyordu; bulunursa özete taşınır.
  static const _legacyPinKey = 'auth.pin';
  static const _failedAttemptsKey = 'auth.failed_attempts';
  static const _lockedUntilKey = 'auth.locked_until';

  static final _pinPattern = RegExp('^\\d{$pinLength}\$');

  final KeyValueStore _store;
  final PinHasher _hasher;
  final DateTime Function() _clock;

  static bool isValidFormat(String pin) => _pinPattern.hasMatch(pin);

  /// 111111, 123456, 987654 gibi kolay tahmin edilen PIN'leri yakalar.
  static bool isWeakPin(String pin) {
    final digits = pin.codeUnits.map((c) => c - 48).toList();
    bool hasStep(int step) {
      for (var i = 1; i < digits.length; i++) {
        if (digits[i] - digits[i - 1] != step) return false;
      }
      return true;
    }

    return hasStep(0) || hasStep(1) || hasStep(-1);
  }

  Future<bool> hasPin() async =>
      await _store.read(_pinHashKey) != null ||
      await _store.read(_legacyPinKey) != null;

  Future<void> setPin(String pin) async {
    if (!isValidFormat(pin)) {
      throw ArgumentError.value(pin, 'pin', '$pinLength haneli olmalı');
    }
    await _store.write(_pinHashKey, await _hasher.hash(pin));
    await _store.delete(_legacyPinKey);
    await _resetAttempts();
  }

  Future<Duration> lockoutRemaining() async {
    final raw = await _store.read(_lockedUntilKey);
    final lockedUntil = raw == null ? null : DateTime.tryParse(raw);
    if (lockedUntil == null) return Duration.zero;
    final remaining = lockedUntil.difference(_clock());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<PinVerification> verify(String pin) async {
    final lockout = await lockoutRemaining();
    if (lockout > Duration.zero) {
      return PinVerification(
        PinCheckResult.lockedOut,
        lockoutRemaining: lockout,
      );
    }

    if (await _matches(pin)) {
      await _resetAttempts();
      return const PinVerification(PinCheckResult.success);
    }

    final failed =
        (int.tryParse(await _store.read(_failedAttemptsKey) ?? '') ?? 0) + 1;
    if (failed >= maxAttempts) {
      await _store.write(
        _lockedUntilKey,
        _clock().add(lockoutDuration).toIso8601String(),
      );
      await _store.write(_failedAttemptsKey, '0');
      return const PinVerification(
        PinCheckResult.lockedOut,
        lockoutRemaining: lockoutDuration,
      );
    }

    await _store.write(_failedAttemptsKey, '$failed');
    return PinVerification(
      PinCheckResult.wrong,
      remainingAttempts: maxAttempts - failed,
    );
  }

  Future<bool> _matches(String pin) async {
    final record = await _store.read(_pinHashKey);
    if (record != null) return _hasher.verify(pin, record);

    final legacy = await _store.read(_legacyPinKey);
    if (legacy == null) throw StateError('Henüz PIN oluşturulmadı');
    final matches = PinHasher.constantTimeEquals(
      pin.codeUnits,
      legacy.codeUnits,
    );
    // Doğru girildiğinde düz kayıt silinip yerine özet yazılır.
    if (matches) await setPin(pin);
    return matches;
  }

  Future<void> _resetAttempts() async {
    await _store.delete(_failedAttemptsKey);
    await _store.delete(_lockedUntilKey);
  }
}
