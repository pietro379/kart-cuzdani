import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wallet_palette.dart';

/// Girilen PIN hanelerini nokta olarak gösterir.
/// [errorTick] her arttığında noktalar sallanır (hatalı giriş geri bildirimi).
class PinDots extends StatefulWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.isError = false,
    this.errorTick = 0,
  });

  final int length;
  final int filled;
  final bool isError;
  final int errorTick;

  @override
  State<PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<PinDots> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(PinDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorTick != oldWidget.errorTick) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glow = context.palette.glow;
    final active = widget.isError ? scheme.error : scheme.primary;

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Semantics(
        label: '${widget.filled} / ${widget.length} hane girildi',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 9),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < widget.filled ? active : Colors.transparent,
                  border: Border.all(
                    color: i < widget.filled ? active : scheme.outline,
                    width: 1.5,
                  ),
                  boxShadow: i < widget.filled
                      ? [BoxShadow(color: glow, blurRadius: 12)]
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
