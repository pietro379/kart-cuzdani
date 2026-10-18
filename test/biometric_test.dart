import 'dart:async';

import 'package:add_card_app/services/pin_service.dart';
import 'package:add_card_app/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/fake_biometrics.dart';
import 'helpers/in_memory_store.dart';
import 'helpers/test_hasher.dart';

const _biometricKey = 'pref.biometric_unlock';

/// PIN'i kurulu, kilitli bir cüzdanla uygulamayı açar.
Future<InMemoryKeyValueStore> pumpLocked(
  WidgetTester tester,
  FakeBiometrics biometrics, {
  bool enabled = true,
}) async {
  final store = InMemoryKeyValueStore();
  await PinService(store, hasher: testHasher).setPin(testPin);
  if (enabled) store.values[_biometricKey] = 'true';
  await pumpApp(tester, store, biometrics: biometrics);
  return store;
}

final _lockTitle = find.text('Cüzdan Kilitli');
final _biometricButton = find.byKey(const ValueKey('pin_key_biometric'));
final _homeTabBar = find.byKey(const ValueKey('wallet_tab_bar'));

void main() {
  group('SettingsController', () {
    test('biyometrik kilit varsayılan olarak kapalıdır ve kalıcıdır', () async {
      final store = InMemoryKeyValueStore();
      final settings = SettingsController(store);
      await settings.load();
      expect(settings.biometricUnlock, isFalse);

      await settings.setBiometricUnlock(true);
      expect(store.values[_biometricKey], 'true');

      final reloaded = SettingsController(store);
      await reloaded.load();
      expect(reloaded.biometricUnlock, isTrue);

      reloaded.reset();
      expect(reloaded.biometricUnlock, isFalse);
    });
  });

  group('kilit ekranı', () {
    testWidgets('doğrulama başarılıysa PIN girmeden açılır', (tester) async {
      final biometrics = FakeBiometrics();
      await pumpLocked(tester, biometrics);

      expect(biometrics.attempts, 1);
      expect(_lockTitle, findsNothing);
      expect(_homeTabBar, findsOneWidget);
    });

    testWidgets('doğrulama başarısızsa kilitli kalır, PIN yine çalışır', (
      tester,
    ) async {
      final biometrics = FakeBiometrics(succeeds: false);
      await pumpLocked(tester, biometrics);

      expect(biometrics.attempts, 1);
      expect(_lockTitle, findsOneWidget);
      expect(_biometricButton, findsOneWidget);

      await enterPin(tester, testPin);
      expect(_lockTitle, findsNothing);
      expect(_homeTabBar, findsOneWidget);
    });

    testWidgets('parmak izi düğmesi doğrulamayı yeniden dener', (tester) async {
      final biometrics = FakeBiometrics(succeeds: false);
      await pumpLocked(tester, biometrics);
      expect(_lockTitle, findsOneWidget);

      biometrics.succeeds = true;
      await tester.tap(_biometricButton);
      await tester.pumpAndSettle();

      expect(biometrics.attempts, 2);
      expect(_lockTitle, findsNothing);
    });

    testWidgets('uygulama arka plana alınırsa gecikmiş başarı kilidi açmaz', (
      tester,
    ) async {
      final biometrics = FakeBiometrics()..pending = Completer<bool>();
      await pumpLocked(tester, biometrics);
      expect(_lockTitle, findsOneWidget);

      // Doğrulama sürerken uygulama arka plana gider ve geri gelir.
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();

      // Eski denemenin sonucu şimdi "başarılı" olarak gelir: kabul edilmemeli.
      biometrics.pending!.complete(true);
      await tester.pumpAndSettle();
      expect(_lockTitle, findsOneWidget);
      expect(_homeTabBar, findsNothing);

      // PIN yine çalışır.
      await enterPin(tester, testPin);
      expect(_homeTabBar, findsOneWidget);
    });

    testWidgets('ayar kapalıyken düğme yok ve doğrulama istenmez', (
      tester,
    ) async {
      final biometrics = FakeBiometrics();
      await pumpLocked(tester, biometrics, enabled: false);

      expect(biometrics.attempts, 0);
      expect(_biometricButton, findsNothing);
      expect(_lockTitle, findsOneWidget);
    });

    testWidgets('cihazda biyometri yoksa ayar açık olsa da düğme çıkmaz', (
      tester,
    ) async {
      final biometrics = FakeBiometrics(available: false);
      await pumpLocked(tester, biometrics);

      expect(biometrics.attempts, 0);
      expect(_biometricButton, findsNothing);
      expect(_lockTitle, findsOneWidget);
    });
  });

  group('ayarlar', () {
    final tile = find.byKey(const ValueKey('settings_biometric'));

    Future<void> openSettings(WidgetTester tester) async {
      await openTab(tester, 'Ayarlar');
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
    }

    testWidgets('açmak için doğrulama gerekir ve ayar kaydedilir', (
      tester,
    ) async {
      final biometrics = FakeBiometrics();
      final store = await pumpUnlockedApp(tester, biometrics: biometrics);
      await openSettings(tester);

      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(biometrics.attempts, 1);
      expect(biometrics.lastReason, contains('etkinleştirmek'));
      expect(store.values[_biometricKey], 'true');
      expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    });

    testWidgets('doğrulama başarısızsa ayar açılmaz', (tester) async {
      final biometrics = FakeBiometrics(succeeds: false);
      final store = await pumpUnlockedApp(tester, biometrics: biometrics);
      await openSettings(tester);

      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(store.values[_biometricKey], isNull);
      expect(tester.widget<SwitchListTile>(tile).value, isFalse);
      expect(
        find.text('Doğrulama yapılamadı, ayar değişmedi.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('cihazda biyometri yoksa anahtar pasiftir', (tester) async {
      final biometrics = FakeBiometrics(available: false);
      await pumpUnlockedApp(tester, biometrics: biometrics);
      await openSettings(tester);

      expect(tester.widget<SwitchListTile>(tile).onChanged, isNull);
      expect(find.textContaining('kurulu değil'), findsOneWidget);
    });

    testWidgets('sistem ayarlarından dönünce kullanılabilirlik yenilenir', (
      tester,
    ) async {
      final biometrics = FakeBiometrics(available: false);
      await pumpUnlockedApp(tester, biometrics: biometrics);
      await openSettings(tester);
      expect(tester.widget<SwitchListTile>(tile).onChanged, isNull);

      // Kullanıcı sistem ayarlarında parmak izi kaydeder ve uygulamaya döner.
      biometrics.available = true;
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      await enterPin(tester, testPin); // arka plana alınınca cüzdan kilitlenir
      await openSettings(tester);

      expect(tester.widget<SwitchListTile>(tile).onChanged, isNotNull);
    });

    testWidgets('kapatmak doğrulama istemez', (tester) async {
      final biometrics = FakeBiometrics();
      // Ayar açık olduğu için uygulama doğrulamayla kendiliğinden açılır.
      final store = await pumpLocked(tester, biometrics);
      await openSettings(tester);
      final before = biometrics.attempts;

      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(biometrics.attempts, before);
      expect(store.values[_biometricKey], 'false');
    });
  });
}
