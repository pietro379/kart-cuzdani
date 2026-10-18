import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/in_memory_store.dart';

Finder scrollableOf(String listKey) => find.descendant(
  of: find.byKey(ValueKey(listKey)),
  matching: find.byType(Scrollable),
);

/// Liste tembel oluşturulduğu için öğe önce görünür olana kadar kaydırılır.
Future<void> scrollFormTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: scrollableOf('add_card_list').first,
  );
  await tester.pumpAndSettle();
}

/// [palette]: 'bg' (kart rengi) veya 'accent' (desen rengi)
Future<void> selectSwatch(
  WidgetTester tester,
  String palette,
  String swatchId,
) async {
  final swatch = find.byKey(ValueKey('${palette}_$swatchId'));
  await scrollFormTo(tester, find.byKey(ValueKey('${palette}_palette')));
  await tester.scrollUntilVisible(
    swatch,
    80,
    scrollable: scrollableOf('${palette}_palette'),
  );
  await tester.ensureVisible(swatch);
  await tester.pumpAndSettle();
  await tester.tap(swatch);
  await tester.pump();
}

Future<void> fillField(WidgetTester tester, String key, String text) async {
  final field = find.byKey(ValueKey(key));
  await scrollFormTo(tester, field);
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> tapSave(WidgetTester tester) async {
  final save = find.byKey(const ValueKey('add_card_save'));
  await scrollFormTo(tester, save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

Map<String, dynamic>? savedCards(InMemoryKeyValueStore store) {
  final raw = store.values['cards.v1'];
  return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
}

void main() {
  testWidgets(
    'geçerli kart şifreli depoya kaydedilir ve Kartlarım\'da görünür',
    (tester) async {
      final store = await pumpUnlockedApp(tester);
      await openTab(tester, 'Kart Ekle');

      // Paletler yatayda kaydırılabilir; kart rengi (düz) ve desen rengi
      // (gradyan) ayrı ayrı seçilir.
      await selectSwatch(tester, 'bg', 'bg_cream');
      await selectSwatch(tester, 'accent', 'holo');

      await fillField(tester, 'add_card_name', 'Maaş Kartı');
      await fillField(tester, 'add_card_number', '4242424242424242');
      await fillField(tester, 'add_card_expiry', '1230');
      await fillField(tester, 'add_card_cvv', '123');
      await fillField(tester, 'add_card_pin', '9876');

      // Yazarken biçimlendirme ve canlı önizleme
      expect(find.text('4242 4242 4242 4242'), findsWidgets);
      expect(find.text('12/30'), findsWidgets);

      await tapSave(tester);

      final cards = savedCards(store)!['cards'] as List<dynamic>;
      expect(cards, hasLength(1));
      final card = cards.single as Map<String, dynamic>;
      expect(card['name'], 'Maaş Kartı');
      expect(card['number'], '4242424242424242');
      expect(card['expiryMonth'], 12);
      expect(card['expiryYear'], 2030);
      expect(card['cvv'], '123');
      expect(card['pin'], '9876');
      expect(card['backgroundId'], 'bg_cream');
      expect(card['accentId'], 'holo');
      expect(card.containsKey('colorId'), isFalse);

      // Kaydedince Kartlarım'a geçilir; numara varsayılan olarak maskelidir.
      expect(find.text('Kartlarınızı'), findsOneWidget);
      expect(find.text('Maaş Kartı', findRichText: true), findsOneWidget);
      expect(find.text('**** **** **** 4242'), findsOneWidget);
      expect(find.text('VISA'), findsOneWidget);

      // SnackBar'ın zamanlayıcısı bitsin
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('kaydedildikten sonra form temizlenir', (tester) async {
    await pumpUnlockedApp(tester);
    await openTab(tester, 'Kart Ekle');

    await fillField(tester, 'add_card_name', 'Market');
    await fillField(tester, 'add_card_number', '5555555555554444');
    await fillField(tester, 'add_card_expiry', '0631');
    await fillField(tester, 'add_card_cvv', '321');
    await tapSave(tester);

    await openTab(tester, 'Kart Ekle');
    final number = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('add_card_number')),
        matching: find.byType(EditableText),
      ),
    );
    expect(number.controller.text, isEmpty);
    expect(find.text('Kart İsmi'), findsWidgets);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('CVV/şifre yazılırken önizleme arka yüze döner', (tester) async {
    await pumpUnlockedApp(tester);
    await openTab(tester, 'Kart Ekle');

    // Ön yüzde CVV şeridi yok
    expect(find.text('KART ŞİFRESİ'), findsNothing);

    await fillField(tester, 'add_card_cvv', '123');
    // Önizleme formun en üstünde; odak CVV'deyken yukarı kaydırıp bak.
    await tester.scrollUntilVisible(
      find.text('KART ŞİFRESİ'),
      -150,
      scrollable: scrollableOf('add_card_list').first,
    );
    await tester.pumpAndSettle();
    expect(find.text('KART ŞİFRESİ'), findsOneWidget);
    // CVV varsayılan olarak gizli yazılır
    expect(find.text('***'), findsOneWidget);

    await fillField(tester, 'add_card_name', 'Market');
    await tester.pumpAndSettle();
    expect(find.text('KART ŞİFRESİ'), findsNothing);
  });

  testWidgets('hatalı form kaydedilmez ve hatalar gösterilir', (tester) async {
    final store = await pumpUnlockedApp(tester);
    await openTab(tester, 'Kart Ekle');

    await tapSave(tester);
    expect(find.text('Kart ismi gerekli'), findsOneWidget);
    expect(find.text('Kart numarası gerekli'), findsOneWidget);

    await fillField(tester, 'add_card_name', 'Test');
    await fillField(tester, 'add_card_number', '4242424242424241');
    await fillField(tester, 'add_card_expiry', '0120');
    await fillField(tester, 'add_card_cvv', '12');
    await fillField(tester, 'add_card_pin', '12');
    await tapSave(tester);

    expect(find.text('Kart numarası geçersiz, kontrol edin'), findsOneWidget);
    expect(find.text('Kartın süresi dolmuş'), findsOneWidget);
    expect(find.text('CVV 3 haneli olmalı'), findsOneWidget);
    expect(find.text('Şifre 4-6 haneli olmalı'), findsOneWidget);
    expect(savedCards(store), isNull);
    expect(find.text('KART EKLE'), findsOneWidget);
  });

  testWidgets('kartlar kilit açılınca yüklenir ve gizleme ayarına uyar', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    store.values['cards.v1'] = jsonEncode({
      'version': 1,
      'cards': [
        {
          'id': 'x1',
          'name': 'Seyahat',
          'number': '378282246310005',
          'expiryMonth': 1,
          'expiryYear': 2031,
          'cvv': '1234',
          'pin': null,
          'colorId': 'midnight',
          'createdAt': '2026-10-08T12:00:00.000',
        },
      ],
    });
    await pumpUnlockedApp(tester, store: store);

    expect(find.text('Seyahat', findRichText: true), findsOneWidget);
    expect(find.text('AMEX'), findsOneWidget);
    expect(find.text('**** **** ***0 005'), findsOneWidget);

    await openTab(tester, 'Ayarlar');
    await tester.tap(find.byKey(const ValueKey('settings_mask_cards')));
    await tester.pumpAndSettle();
    await openTab(tester, 'Kartlarım');
    expect(find.text('3782 8224 6310 005'), findsOneWidget);
  });

  testWidgets('tüm veriler silinince kartlar da silinir', (tester) async {
    final store = await pumpUnlockedApp(tester);
    await openTab(tester, 'Kart Ekle');
    await fillField(tester, 'add_card_name', 'Silinecek');
    await fillField(tester, 'add_card_number', '4242424242424242');
    await fillField(tester, 'add_card_expiry', '1230');
    await fillField(tester, 'add_card_cvv', '123');
    await tapSave(tester);
    expect(savedCards(store), isNotNull);

    // "Kaydedildi" bildirimi alttaki düğmeleri örtmesin diye kapanmasını bekle.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await openTab(tester, 'Ayarlar');
    final wipe = find.byKey(const ValueKey('settings_wipe_all'));
    await scrollSettingsTo(tester, wipe);
    await tester.tap(wipe);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm_wipe_all')));
    await tester.pumpAndSettle();
    expect(store.values, isEmpty);

    await enterPin(tester, testPin);
    await enterPin(tester, testPin);
    expect(find.text('Silinecek', findRichText: true), findsNothing);
    expect(find.text('Henüz kayıtlı kart yok'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
