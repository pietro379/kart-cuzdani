import 'package:add_card_app/services/pin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/in_memory_store.dart';
import 'helpers/test_hasher.dart';

void main() {
  testWidgets('ilk açılışta PIN oluşturulur ve ana ekrana geçilir', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    await pumpApp(tester, store);

    expect(find.text('PIN Oluştur'), findsOneWidget);
    await enterPin(tester, '482916');
    expect(find.text('PIN\'i Onayla'), findsOneWidget);
    await enterPin(tester, '482916');

    expect(find.text('Kartlarınızı'), findsOneWidget);
    expect(await PinService(store, hasher: testHasher).hasPin(), isTrue);
  });

  testWidgets('zayıf PIN ve eşleşmeyen onay reddedilir', (tester) async {
    await pumpApp(tester, InMemoryKeyValueStore());

    await enterPin(tester, '123456');
    expect(find.textContaining('kolay tahmin'), findsOneWidget);
    expect(find.text('PIN Oluştur'), findsOneWidget);

    await enterPin(tester, '482916');
    await enterPin(tester, '482917');
    expect(find.textContaining('eşleşmedi'), findsOneWidget);
    expect(find.text('PIN Oluştur'), findsOneWidget);
  });

  testWidgets('PIN varsa kilit ekranı açılır; hatalı PIN reddedilir', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    await PinService(store, hasher: testHasher).setPin('482916');
    await pumpApp(tester, store);

    expect(find.text('Cüzdan Kilitli'), findsOneWidget);
    await enterPin(tester, '000001');
    expect(find.textContaining('Kalan deneme hakkı: 4'), findsOneWidget);
    expect(find.text('Kartlarınızı'), findsNothing);

    await enterPin(tester, '482916');
    expect(find.text('Kartlarınızı'), findsOneWidget);
    expect(find.text('Cüzdan Kilitli'), findsNothing);
  });

  testWidgets('uygulama arka plana gidince yeniden kilitlenir', (tester) async {
    final store = InMemoryKeyValueStore();
    await PinService(store, hasher: testHasher).setPin('482916');
    await pumpApp(tester, store);
    await enterPin(tester, '482916');
    expect(find.text('Kartlarınızı'), findsOneWidget);

    // Arka plana git ve geri dön (hidden iken Flutter kare çizmez).
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();

    expect(find.text('Cüzdan Kilitli'), findsOneWidget);
    expect(find.text('Kartlarınızı'), findsNothing);
  });

  testWidgets('bildirim paneli gibi geçici kesintiler kilitlemez', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    await PinService(store, hasher: testHasher).setPin('482916');
    await pumpApp(tester, store);
    await enterPin(tester, '482916');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Kartlarınızı'), findsOneWidget);
  });

  testWidgets('ana ekrandaki Kilitle düğmesi ile manuel kilitlenir', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    await PinService(store, hasher: testHasher).setPin('482916');
    await pumpApp(tester, store);
    await enterPin(tester, '482916');

    await tester.tap(find.byTooltip('Kilitle'));
    await tester.pumpAndSettle();
    expect(find.text('Cüzdan Kilitli'), findsOneWidget);
  });

  testWidgets('alt navigasyon sekmeler arasında geçiş yapar', (tester) async {
    await pumpUnlockedApp(tester);
    expect(find.byKey(const ValueKey('wallet_tab_bar')), findsOneWidget);

    await openTab(tester, 'Kart Ekle');
    expect(find.text('KART EKLE'), findsOneWidget);

    await openTab(tester, 'Ayarlar');
    expect(find.text('AYARLAR'), findsOneWidget);
    expect(find.text('Koyu tema'), findsOneWidget);

    await openTab(tester, 'Kartlarım');
    expect(find.text('Kartlarınızı'), findsOneWidget);
  });

  group('Ayarlar', () {
    testWidgets('koyu/açık tema anahtarı temayı değiştirir ve kaydeder', (
      tester,
    ) async {
      final store = await pumpUnlockedApp(tester);
      await openTab(tester, 'Ayarlar');

      final themeSwitch = find.byKey(const ValueKey('settings_dark_theme'));
      await tester.tap(themeSwitch);
      await tester.pumpAndSettle();
      expect(store.values['pref.theme_mode'], 'dark');
      expect(Theme.of(tester.element(themeSwitch)).brightness, Brightness.dark);

      await tester.tap(themeSwitch);
      await tester.pumpAndSettle();
      expect(store.values['pref.theme_mode'], 'light');
      expect(
        Theme.of(tester.element(themeSwitch)).brightness,
        Brightness.light,
      );
    });

    testWidgets('kart gizleme varsayılan açık; kapatınca numara okunur', (
      tester,
    ) async {
      final store = await pumpUnlockedApp(tester);
      await openTab(tester, 'Ayarlar');

      expect(find.text('**** **** **** 4242'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('settings_mask_cards')));
      await tester.pumpAndSettle();
      expect(find.text('4242 4242 4242 4242'), findsOneWidget);
      expect(store.values['pref.mask_card_numbers'], 'false');
    });

    testWidgets('profil adı düzenlenir, kaydedilir ve karta yansır', (
      tester,
    ) async {
      final store = await pumpUnlockedApp(tester);
      await openTab(tester, 'Ayarlar');
      expect(find.text('İsim belirtilmedi'), findsOneWidget);

      await tester.tap(find.byTooltip('Profili düzenle'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('profile_name_field')),
        '  ayşe yılmaz  ',
      );
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('ayşe yılmaz'), findsOneWidget);
      expect(find.text('AY'), findsOneWidget);
      expect(store.values['profile.user_name'], 'ayşe yılmaz');

      await openTab(tester, 'Kartlarım');
      expect(find.text('AYŞE YILMAZ'), findsOneWidget);
    });

    testWidgets('profil düzenlemede İptal hiçbir şeyi değiştirmez', (
      tester,
    ) async {
      final store = await pumpUnlockedApp(tester);
      await openTab(tester, 'Ayarlar');

      await tester.tap(find.byTooltip('Profili düzenle'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('profile_name_field')),
        'Deneme',
      );
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      expect(find.text('İsim belirtilmedi'), findsOneWidget);
      expect(store.values, isNot(contains('profile.user_name')));
    });

    testWidgets('Vazgeç denirse veriler silinmez', (tester) async {
      final store = await pumpUnlockedApp(tester);
      await openTab(tester, 'Ayarlar');

      final wipe = find.byKey(const ValueKey('settings_wipe_all'));
      await tester.ensureVisible(wipe);
      await tester.tap(wipe);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      expect(store.values, contains('auth.pin_hash'));
      expect(find.text('AYARLAR'), findsOneWidget);
    });

    testWidgets('tüm veriler silinince depo boşalır ve PIN kurulumu açılır', (
      tester,
    ) async {
      final store = await pumpUnlockedApp(tester);
      await openTab(tester, 'Ayarlar');

      // Silinecek veri olsun diye birkaç ayar değiştir.
      await tester.tap(find.byKey(const ValueKey('settings_mask_cards')));
      await tester.tap(find.byKey(const ValueKey('settings_dark_theme')));
      await tester.pumpAndSettle();
      expect(store.values, isNotEmpty);

      final wipe = find.byKey(const ValueKey('settings_wipe_all'));
      await tester.ensureVisible(wipe);
      await tester.tap(wipe);
      await tester.pumpAndSettle();
      expect(find.text('Tüm veriler silinsin mi?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirm_wipe_all')));
      await tester.pumpAndSettle();

      expect(store.values, isEmpty);
      expect(find.text('PIN Oluştur'), findsOneWidget);
      expect(find.text('AYARLAR'), findsNothing);

      // Yeni PIN ile baştan kurulunca ayarlar varsayılana dönmüş olmalı.
      await enterPin(tester, '482916');
      await enterPin(tester, '482916');
      await openTab(tester, 'Ayarlar');
      expect(find.text('**** **** **** 4242'), findsOneWidget);
      expect(find.text('Kartlarınızı'), findsNothing);
    });
  });
}
