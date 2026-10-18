import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Uygulamaya özel sayısal tuş takımı.
/// Sistem klavyesi kullanılmadığı için üçüncü parti klavyeler PIN'i göremez.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// Doluysa sol alttaki boş yerde parmak izi düğmesi gösterilir.
  final VoidCallback? onBiometric;
  final bool enabled;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          _PadRow(children: [for (final d in row) _digit(d)]),
        _PadRow(
          children: [
            if (onBiometric == null)
              const SizedBox(width: _PadButton.size, height: _PadButton.size)
            else
              _PadButton(
                key: const ValueKey('pin_key_biometric'),
                semanticLabel: 'Parmak izi ile aç',
                onTap: enabled ? onBiometric : null,
                child: const Icon(Icons.fingerprint, size: 30),
              ),
            _digit('0'),
            _PadButton(
              key: const ValueKey('pin_key_backspace'),
              semanticLabel: 'Sil',
              onTap: enabled ? onBackspace : null,
              child: const Icon(Icons.backspace_outlined, size: 22),
            ),
          ],
        ),
      ],
    );
  }

  Widget _digit(String d) => _PadButton(
    key: ValueKey('pin_key_$d'),
    semanticLabel: d,
    onTap: enabled ? () => onDigit(d) : null,
    child: Builder(
      builder: (context) => Text(
        d,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
  );
}

class _PadRow extends StatelessWidget {
  const _PadRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: children,
    ),
  );
}

class _PadButton extends StatelessWidget {
  const _PadButton({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
  });

  static const size = 72.0;

  final Widget child;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.55),
          shape: CircleBorder(side: BorderSide(color: scheme.outline)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
            splashColor: scheme.primary.withValues(alpha: 0.25),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
