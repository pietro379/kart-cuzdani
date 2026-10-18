import 'dart:async';

import 'package:flutter/material.dart';

import '../services/biometric_authenticator.dart';
import '../services/pin_service.dart';
import '../state/settings_controller.dart';
import '../widgets/pin_entry_view.dart';

/// Uygulamaya her girişte gösterilen PIN kilit ekranı.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.pinService,
    required this.biometrics,
    required this.settings,
    required this.onUnlocked,
  });

  final PinService pinService;
  final BiometricAuthenticator biometrics;
  final SettingsController settings;
  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _input = '';
  String? _error;
  int _errorTick = 0;
  bool _busy = false;
  bool _biometricReady = false;
  bool _authenticating = false;

  /// Her doğrulama denemesine bir numara verilir; uygulama arka plana alınınca
  /// numara ilerler ve eski denemenin gecikmiş sonucu kilidi açamaz.
  int _biometricSession = 0;
  late final AppLifecycleListener _lifecycle;
  Duration _lockout = Duration.zero;
  Timer? _countdown;

  bool get _lockedOut => _lockout > Duration.zero;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: () => _biometricSession++);
    _restoreLockout();
    _prepareBiometric();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _countdown?.cancel();
    super.dispose();
  }

  /// Biyometrik kilit açma açık ve cihazda kullanılabilirse düğmeyi gösterir ve
  /// ekran açılır açılmaz bir kez doğrulama penceresi çıkarır. PIN her zaman geçerlidir.
  Future<void> _prepareBiometric() async {
    if (!widget.settings.biometricUnlock) return;
    if (!await widget.biometrics.isAvailable() || !mounted) return;
    setState(() => _biometricReady = true);
    await _authenticateWithBiometrics();
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_authenticating || _busy) return;
    _authenticating = true;
    final session = ++_biometricSession;
    final ok = await widget.biometrics.authenticate(
      'Cüzdanın kilidini açmak için kimliğinizi doğrulayın',
    );
    _authenticating = false;
    // Sonuç yalnızca bu ekran hâlâ görünürse ve deneme sırasında uygulama
    // arka plana alınmadıysa kabul edilir.
    if (!ok || !mounted || session != _biometricSession) return;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return;
    widget.onUnlocked();
  }

  /// Uygulama kapatılıp açılsa bile süren kilidi geri yükler.
  Future<void> _restoreLockout() async {
    final remaining = await widget.pinService.lockoutRemaining();
    if (mounted) _startLockout(remaining);
  }

  void _startLockout(Duration remaining) {
    _countdown?.cancel();
    setState(() => _lockout = remaining);
    if (!_lockedOut) return;
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = _lockout - const Duration(seconds: 1);
      setState(() {
        if (left > Duration.zero) {
          _lockout = left;
        } else {
          timer.cancel();
          _lockout = Duration.zero;
          _error = null;
        }
      });
    });
  }

  void _onDigit(String digit) {
    if (_busy || _lockedOut || _input.length >= PinService.pinLength) return;
    setState(() {
      _input += digit;
      _error = null;
    });
    if (_input.length == PinService.pinLength) _submit();
  }

  void _onBackspace() {
    if (_busy || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final result = await widget.pinService.verify(_input);
    if (!mounted) return;

    switch (result.result) {
      case PinCheckResult.success:
        widget.onUnlocked();
      case PinCheckResult.wrong:
        setState(() {
          _busy = false;
          _input = '';
          _errorTick++;
          _error =
              'Hatalı PIN. Kalan deneme hakkı: ${result.remainingAttempts}';
        });
      case PinCheckResult.lockedOut:
        setState(() {
          _busy = false;
          _input = '';
          _errorTick++;
          _error = null;
        });
        _startLockout(result.lockoutRemaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (_lockout.inMilliseconds / 1000).ceil();
    return PinEntryView(
      icon: _lockedOut ? Icons.lock_clock_outlined : Icons.lock_outline,
      title: 'Cüzdan Kilitli',
      subtitle:
          'Devam etmek için ${PinService.pinLength} haneli PIN\'inizi girin.',
      filled: _input.length,
      message: _lockedOut
          ? 'Çok fazla hatalı deneme.\n$seconds saniye sonra tekrar deneyin.'
          : _error,
      isError: _lockedOut || _error != null,
      errorTick: _errorTick,
      enabled: !_busy && !_lockedOut,
      onDigit: _onDigit,
      onBackspace: _onBackspace,
      onBiometric: _biometricReady ? _authenticateWithBiometrics : null,
    );
  }
}
