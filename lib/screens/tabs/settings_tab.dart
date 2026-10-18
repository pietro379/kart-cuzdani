import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../state/settings_controller.dart';
import '../../theme/wallet_palette.dart';
import '../../utils/card_number_format.dart';
import '../../utils/text_format.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  /// Kart gizleme anahtarının altında gösterilen örnek numara.
  static const _previewNumber = '4242424242424242';

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final themeController = scope.themeController;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        const _SectionLabel('PROFİL'),
        ListenableBuilder(
          listenable: settings,
          builder: (context, _) => _ProfileCard(settings: settings),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('GÖRÜNÜM'),
        Card(
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeController,
            builder: (context, mode, _) {
              final isDark =
                  mode == ThemeMode.dark ||
                  (mode == ThemeMode.system &&
                      MediaQuery.platformBrightnessOf(context) ==
                          Brightness.dark);
              return SwitchListTile(
                key: const ValueKey('settings_dark_theme'),
                secondary: Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                ),
                title: const Text('Koyu tema'),
                subtitle: Text(
                  mode == ThemeMode.system
                      ? 'Şu an sistem ayarı kullanılıyor'
                      : isDark
                      ? 'Koyu gri & beyaz'
                      : 'Beyaz & metalik gri',
                ),
                value: isDark,
                onChanged: themeController.setDark,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('GİZLİLİK'),
        Card(
          child: Column(
            children: [
              ListenableBuilder(
                listenable: settings,
                builder: (context, _) => SwitchListTile(
                  key: const ValueKey('settings_mask_cards'),
                  secondary: Icon(
                    settings.maskCardNumbers
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  title: const Text('Kart bilgilerini gizle'),
                  subtitle: Text(
                    formatCardNumber(
                      _previewNumber,
                      masked: settings.maskCardNumbers,
                    ),
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                      letterSpacing: 1.2,
                    ),
                  ),
                  value: settings.maskCardNumbers,
                  onChanged: settings.setMaskCardNumbers,
                ),
              ),
              const Divider(height: 1),
              const _BiometricTile(),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const _SectionLabel('TEHLİKELİ BÖLGE'),
        const _WipeDataButton(),
      ],
    );
  }
}

/// Parmak izi / yüz ile kilit açma anahtarı. Cihazda biyometri kurulu değilse pasiftir;
/// açmak için bir kez doğrulama gerekir, böylece özellik gerçekten çalışmadan etkinleşmez.
class _BiometricTile extends StatefulWidget {
  const _BiometricTile();

  @override
  State<_BiometricTile> createState() => _BiometricTileState();
}

class _BiometricTileState extends State<_BiometricTile> {
  Future<bool>? _available;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Parmak izi kaydı sistem ayarlarında yapılır; uygulamaya dönüldüğünde
    // durum yeniden sorgulanır ki anahtar eski haliyle pasif kalmasın.
    _lifecycle = AppLifecycleListener(onResume: _refreshAvailability);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refreshAvailability() {
    if (!mounted) return;
    final available = AppScope.of(context).biometrics.isAvailable();
    setState(() {
      _available = available;
    });
  }

  Future<void> _toggle(bool value) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (value) {
      final ok = await scope.biometrics.authenticate(
        'Parmak izi ile açmayı etkinleştirmek için kimliğinizi doğrulayın',
      );
      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Doğrulama yapılamadı, ayar değişmedi.'),
          ),
        );
        return;
      }
    }
    await scope.settings.setBiometricUnlock(value);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    _available ??= scope.biometrics.isAvailable();
    return FutureBuilder<bool>(
      future: _available,
      builder: (context, snapshot) {
        final available = snapshot.data ?? false;
        return ListenableBuilder(
          listenable: scope.settings,
          builder: (context, _) => SwitchListTile(
            key: const ValueKey('settings_biometric'),
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Parmak izi ile aç'),
            subtitle: Text(
              available
                  ? 'Kilit ekranında PIN yerine kullanılabilir. PIN her zaman geçerlidir.'
                  : 'Bu cihazda parmak izi veya yüz tanıma kurulu değil.',
            ),
            value: available && scope.settings.biometricUnlock,
            onChanged: available ? _toggle : null,
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasName = settings.userName.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: context.palette.accentGradient,
                boxShadow: [
                  BoxShadow(color: context.palette.glow, blurRadius: 16),
                ],
              ),
              child: hasName
                  ? Text(
                      initialsOf(settings.userName),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.onPrimary,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasName ? settings.userName : 'İsim belirtilmedi',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kartlarda kart sahibi adı olarak görünür',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Profili düzenle',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editName(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _EditNameDialog(initial: settings.userName),
    );
    if (name != null) await settings.setUserName(name);
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initial});

  final String initial;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profili Düzenle'),
      content: TextField(
        key: const ValueKey('profile_name_field'),
        controller: _controller,
        autofocus: true,
        maxLength: SettingsController.maxUserNameLength,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(
          labelText: 'Kullanıcı adı',
          hintText: 'Örn. Ayşe Yılmaz',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Kaydet')),
      ],
    );
  }
}

class _WipeDataButton extends StatelessWidget {
  const _WipeDataButton();

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return OutlinedButton.icon(
      key: const ValueKey('settings_wipe_all'),
      style: OutlinedButton.styleFrom(
        foregroundColor: error,
        side: BorderSide(color: error, width: 1.5),
        backgroundColor: error.withValues(alpha: 0.08),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.delete_forever_outlined),
      label: const Text('Hesabı ve Tüm Verileri Sil'),
      onPressed: () => _confirmAndWipe(context),
    );
  }

  Future<void> _confirmAndWipe(BuildContext context) async {
    final scope = AppScope.of(context);
    final error = Theme.of(context).colorScheme.error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: error, size: 36),
        title: const Text('Tüm veriler silinsin mi?'),
        content: const Text(
          'PIN\'iniz, profiliniz, ayarlarınız ve kayıtlı tüm kartlarınız '
          'bu cihazdan kalıcı olarak silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const ValueKey('confirm_wipe_all'),
            style: FilledButton.styleFrom(
              backgroundColor: error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kalıcı Olarak Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true) await scope.onWipeAllData();
  }
}
