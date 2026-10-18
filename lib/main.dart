import 'package:flutter/material.dart';

import 'app.dart';
import 'services/biometric_authenticator.dart';
import 'services/card_repository.dart';
import 'services/pin_service.dart';
import 'services/secure_store.dart';
import 'state/cards_controller.dart';
import 'state/settings_controller.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = SecureKeyValueStore();
  final themeController = ThemeController(store);
  final settings = SettingsController(store);
  await Future.wait([themeController.load(), settings.load()]);

  runApp(
    CardWalletApp(
      store: store,
      pinService: PinService(store),
      biometrics: LocalBiometricAuthenticator(),
      themeController: themeController,
      settings: settings,
      // Kartlar burada değil, kilit ilk açıldığında yüklenir.
      cards: CardsController(CardRepository(store)),
    ),
  );
}
