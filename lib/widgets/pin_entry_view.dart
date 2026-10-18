import 'package:flutter/material.dart';

import '../services/pin_service.dart';
import '../theme/wallet_palette.dart';
import 'pin_dots.dart';
import 'pin_pad.dart';
import 'app_background.dart';

/// PIN oluşturma ve kilit ekranlarının ortak görünümü.
class PinEntryView extends StatelessWidget {
  const PinEntryView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.message,
    this.isError = false,
    this.errorTick = 0,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int filled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final String? message;
  final bool isError;
  final int errorTick;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GlowBadge(icon: icon),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    PinDots(
                      length: PinService.pinLength,
                      filled: filled,
                      isError: isError,
                      errorTick: errorTick,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      child: message == null
                          ? null
                          : Text(
                              message!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isError
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    PinPad(
                      onDigit: onDigit,
                      onBackspace: onBackspace,
                      onBiometric: onBiometric,
                      enabled: enabled,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowBadge extends StatelessWidget {
  const _GlowBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainer,
        border: Border.all(color: scheme.primary, width: 1.5),
        boxShadow: [
          BoxShadow(color: palette.glow, blurRadius: 36, spreadRadius: 2),
        ],
      ),
      child: ShaderMask(
        shaderCallback: palette.accentGradient.createShader,
        child: Icon(icon, size: 40, color: Colors.white),
      ),
    );
  }
}
