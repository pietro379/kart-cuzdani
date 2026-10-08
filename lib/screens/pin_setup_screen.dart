import 'package:flutter/material.dart';

import '../services/pin_service.dart';
import '../widgets/pin_entry_view.dart';

/// İlk açılışta PIN oluşturma (gir + onayla) ekranı.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({
    super.key,
    required this.pinService,
    required this.onCompleted,
  });

  final PinService pinService;
  final VoidCallback onCompleted;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _input = '';
  String? _firstPin;
  String? _error;
  int _errorTick = 0;
  bool _busy = false;

  bool get _confirming => _firstPin != null;

  void _onDigit(String digit) {
    if (_busy || _input.length >= PinService.pinLength) return;
    setState(() {
      _input += digit;
      _error = null;
    });
    if (_input.length == PinService.pinLength) _onPinEntered();
  }

  void _onBackspace() {
    if (_busy || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _onPinEntered() async {
    if (!_confirming) {
      if (PinService.isWeakPin(_input)) {
        _fail('Bu PIN kolay tahmin edilir. Farklı bir PIN seçin.');
        return;
      }
      setState(() {
        _firstPin = _input;
        _input = '';
      });
      return;
    }

    if (_input != _firstPin) {
      _firstPin = null;
      _fail('PIN\'ler eşleşmedi. Baştan deneyin.');
      return;
    }

    setState(() => _busy = true);
    await widget.pinService.setPin(_input);
    if (!mounted) return;
    widget.onCompleted();
  }

  void _fail(String message) {
    setState(() {
      _input = '';
      _error = message;
      _errorTick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PinEntryView(
      icon: Icons.shield_outlined,
      title: _confirming ? 'PIN\'i Onayla' : 'PIN Oluştur',
      subtitle: _confirming
          ? 'Aynı PIN\'i tekrar girin.'
          : 'Cüzdanınızı korumak için ${PinService.pinLength} haneli bir PIN belirleyin.',
      filled: _input.length,
      message: _error,
      isError: _error != null,
      errorTick: _errorTick,
      enabled: !_busy,
      onDigit: _onDigit,
      onBackspace: _onBackspace,
    );
  }
}
