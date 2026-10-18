import 'dart:convert';

import 'package:add_card_app/models/card_model.dart';
import 'package:add_card_app/services/card_repository.dart';
import 'package:add_card_app/state/cards_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/in_memory_store.dart';

CardModel sampleCard(
  String id,
  String name, {
  String number = '4242424242424242',
}) => CardModel(
  id: id,
  name: name,
  number: number,
  expiryMonth: 12,
  expiryYear: 2030,
  cvv: '123',
  backgroundId: 'ac_white',
  accentId: 'ac_white',
  createdAt: DateTime(2026, 10, 8),
);

Map<String, dynamic> savedCards(InMemoryKeyValueStore store) =>
    jsonDecode(store.values['cards.v1']!) as Map<String, dynamic>;

Future<InMemoryKeyValueStore> storeWith(List<CardModel> cards) async {
  final store = InMemoryKeyValueStore();
  await CardRepository(store).saveAll(cards);
  return store;
}

void main() {
  group('CardsController', () {
    test(
      'update aynı kimlikli kartı yerinde değiştirir ve depoya yazar',
      () async {
        final store = await storeWith([
          sampleCard('a', 'Birinci'),
          sampleCard('b', 'İkinci'),
        ]);
        final controller = CardsController(CardRepository(store));
        await controller.load();

        await controller.update(sampleCard('b', 'Yeni İsim'));

        expect(controller.cards.map((c) => c.name), ['Birinci', 'Yeni İsim']);
        final raw = savedCards(store)['cards'] as List;
        expect(raw.map((c) => c['name']), ['Birinci', 'Yeni İsim']);
      },
    );

    test('update bilinmeyen kimlikte hiçbir şey yapmaz', () async {
      final store = await storeWith([sampleCard('a', 'Birinci')]);
      final controller = CardsController(CardRepository(store));
      await controller.load();

      await controller.update(sampleCard('yok', 'Hayalet'));

      expect(controller.cards.map((c) => c.name), ['Birinci']);
    });

    test('remove kartı bellekten ve depodan siler', () async {
      final store = await storeWith([
        sampleCard('a', 'Birinci'),
        sampleCard('b', 'İkinci'),
      ]);
      final controller = CardsController(CardRepository(store));
      await controller.load();

      await controller.remove('a');

      expect(controller.cards.map((c) => c.id), ['b']);
      expect((savedCards(store)['cards'] as List).single['id'], 'b');
    });
  });

  testWidgets('kart düzenlenir: form dolu açılır, kayıt güncellenir', (
    tester,
  ) async {
    final store = await storeWith([sampleCard('a', 'Maaş Kartı')]);
    await pumpUnlockedApp(tester, store: store);

    await tester.tap(find.byKey(const ValueKey('edit_card_button')));
    await tester.pumpAndSettle();

    expect(find.text('KARTI DÜZENLE'), findsOneWidget);
    final nameField = find.byKey(const ValueKey('add_card_name'));
    expect(
      tester.widget<TextFormField>(nameField).controller!.text,
      'Maaş Kartı',
    );

    await tester.enterText(nameField, 'Harçlık');
    await tester.pump();
    final save = find.byKey(const ValueKey('add_card_save'));
    await tester.scrollUntilVisible(
      save,
      120,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('add_card_list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(save);
    await tester.pumpAndSettle();

    // Düzenleme ekranı kapanır; kart yeni eklenmez, güncellenir.
    expect(find.text('KARTI DÜZENLE'), findsNothing);
    final cards = savedCards(store)['cards'] as List;
    expect(cards, hasLength(1));
    expect(cards.single['id'], 'a');
    expect(cards.single['name'], 'Harçlık');

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('kart silme onay ister; Vazgeç silmez, Sil kalıcı siler', (
    tester,
  ) async {
    final store = await storeWith([
      sampleCard('a', 'Silinecek', number: '5555555555554444'),
    ]);
    await pumpUnlockedApp(tester, store: store);

    await tester.tap(find.byKey(const ValueKey('delete_card_button')));
    await tester.pumpAndSettle();
    expect(find.text('"Silinecek" silinsin mi?'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('4444'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(savedCards(store)['cards'], hasLength(1));

    await tester.tap(find.byKey(const ValueKey('delete_card_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm_delete_card')));
    await tester.pumpAndSettle();

    expect(savedCards(store)['cards'], isEmpty);
    expect(find.text('Henüz kayıtlı kart yok'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('kart yokken düzenle ve sil butonları pasiftir', (tester) async {
    await pumpUnlockedApp(tester);

    final edit = tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(const ValueKey('edit_card_button')),
        matching: find.byType(IconButton),
      ),
    );
    final delete = tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(const ValueKey('delete_card_button')),
        matching: find.byType(IconButton),
      ),
    );
    expect(edit.onPressed, isNull);
    expect(delete.onPressed, isNull);
  });
}
