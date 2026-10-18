import 'package:add_card_app/app.dart';
import 'package:add_card_app/screens/tabs/settings_tab.dart';
import 'package:add_card_app/services/card_repository.dart';
import 'package:add_card_app/services/pin_service.dart';
import 'package:add_card_app/state/cards_controller.dart';
import 'package:add_card_app/state/settings_controller.dart';
import 'package:add_card_app/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_biometrics.dart';
import 'in_memory_store.dart';
import 'test_hasher.dart';

const testPin = '482916';

Future<void> enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(ValueKey('pin_key_$digit')));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> pumpApp(
  WidgetTester tester,
  InMemoryKeyValueStore store, {
  FakeBiometrics? biometrics,
}) async {
  // Telefon boyutunda bir ekran
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final themeController = ThemeController(store);
  final settings = SettingsController(store);
  await themeController.load();
  await settings.load();

  await tester.pumpWidget(
    CardWalletApp(
      store: store,
      pinService: PinService(store, hasher: testHasher),
      // Varsayılan: cihazda biyometri yok (mevcut testler PIN ile ilerler).
      biometrics: biometrics ?? FakeBiometrics(available: false),
      themeController: themeController,
      settings: settings,
      cards: CardsController(CardRepository(store)),
    ),
  );
  await tester.pumpAndSettle();
}

/// PIN'i kayıtlı bir cüzdanı açıp ana ekrana geçer.
Future<InMemoryKeyValueStore> pumpUnlockedApp(
  WidgetTester tester, {
  InMemoryKeyValueStore? store,
  FakeBiometrics? biometrics,
}) async {
  store ??= InMemoryKeyValueStore();
  await PinService(store, hasher: testHasher).setPin(testPin);
  await pumpApp(tester, store, biometrics: biometrics);
  await enterPin(tester, testPin);
  return store;
}

/// Ayarlar listesi tembel çizildiği için alttaki öğeye kaydırarak ulaşır.
Future<void> scrollSettingsTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find
        .descendant(
          of: find.byType(SettingsTab),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(ValueKey('tab_$label')));
  await tester.pumpAndSettle();
}
