import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/pin_setup_screen.dart';
import 'services/biometric_authenticator.dart';
import 'services/pin_service.dart';
import 'services/secure_store.dart';
import 'state/cards_controller.dart';
import 'state/settings_controller.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/app_background.dart';

enum _AuthGate { loading, setup, locked, unlocked }

class CardWalletApp extends StatefulWidget {
  const CardWalletApp({
    super.key,
    required this.store,
    required this.pinService,
    required this.biometrics,
    required this.themeController,
    required this.settings,
    required this.cards,
  });

  final KeyValueStore store;
  final PinService pinService;
  final BiometricAuthenticator biometrics;
  final ThemeController themeController;
  final SettingsController settings;
  final CardsController cards;

  @override
  State<CardWalletApp> createState() => _CardWalletAppState();
}

class _CardWalletAppState extends State<CardWalletApp> {
  _AuthGate _gate = _AuthGate.loading;
  bool _unlockedOnce = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Uygulama arka plana alındığında (ana ekrana dönme, uygulama değiştirme,
    // ekranı kapatma) cüzdan kilitlenir; geri gelindiğinde PIN istenir.
    _lifecycle = AppLifecycleListener(onHide: _lock);
    _resolveInitialGate();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _resolveInitialGate() async {
    final hasPin = await widget.pinService.hasPin();
    if (!mounted) return;
    setState(() => _gate = hasPin ? _AuthGate.locked : _AuthGate.setup);
  }

  void _lock() {
    if (_gate == _AuthGate.unlocked) setState(() => _gate = _AuthGate.locked);
  }

  void _unlock() {
    // Kart verisi, PIN doğrulanmadan önce belleğe hiç alınmaz.
    if (!_unlockedOnce) widget.cards.load();
    setState(() {
      _gate = _AuthGate.unlocked;
      _unlockedOnce = true;
    });
  }

  /// Depodaki her şeyi (PIN, profil, ayarlar, kartlar) siler ve
  /// uygulamayı ilk açılıştaki PIN oluşturma ekranına döndürür.
  Future<void> _wipeAllData() async {
    await widget.store.deleteAll();
    widget.themeController.reset();
    widget.settings.reset();
    widget.cards.reset();
    if (!mounted) return;
    setState(() {
      _gate = _AuthGate.setup;
      // Ana ekran ağacı (açık diyaloglar dahil) tamamen atılır.
      _unlockedOnce = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      pinService: widget.pinService,
      biometrics: widget.biometrics,
      themeController: widget.themeController,
      settings: widget.settings,
      cards: widget.cards,
      onLock: _lock,
      onWipeAllData: _wipeAllData,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: widget.themeController,
        builder: (context, mode, _) => MaterialApp(
          title: 'Kart Cüzdanı',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const HomeScreen(),
          // Kilit ekranı navigasyonun üstünde durur: kilitliyken alttaki
          // içerik hiç çizilmez, kilit açılınca kullanıcı kaldığı yerden devam eder.
          builder: (context, child) {
            final unlocked = _gate == _AuthGate.unlocked;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (_unlockedOnce && child != null)
                  Offstage(
                    offstage: !unlocked,
                    child: TickerMode(enabled: unlocked, child: child),
                  ),
                if (!unlocked) _buildGate(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGate() => switch (_gate) {
    _AuthGate.loading => const AppBackground(child: SizedBox.expand()),
    _AuthGate.setup => PinSetupScreen(
      pinService: widget.pinService,
      onCompleted: _unlock,
    ),
    _AuthGate.locked || _AuthGate.unlocked => LockScreen(
      pinService: widget.pinService,
      biometrics: widget.biometrics,
      settings: widget.settings,
      onUnlocked: _unlock,
    ),
  };
}
