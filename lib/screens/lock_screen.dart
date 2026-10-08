import 'dart:async';

import 'package:flutter/material.dart';

import '../services/pin_service.dart';
import '../widgets/pin_entry_view.dart';

/// Uygulamaya her girişte gösterilen PIN kilit ekranı.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.pinService,
    required this.onUnlocked,
  });

  final PinService pinService;
  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _input = '';
  String? _error;
  int _errorTick = 0;
  bool _busy = false;
  Duration _lockout = Duration.zero;
  Timer? _countdown;

  bool get _lockedOut => _lockout > Duration.zero;

  @override
  void initState() {
    super.initState();
    _restoreLockout();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
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
    );
  }
}
