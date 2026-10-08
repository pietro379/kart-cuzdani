import 'package:add_card_app/models/card_model.dart';
import 'package:add_card_app/services/card_repository.dart';
import 'package:add_card_app/state/cards_controller.dart';
import 'package:add_card_app/theme/card_swatches.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/in_memory_store.dart';

CardModel sampleCard({String id = 'card-a', String? pin = '1234'}) => CardModel(
  id: id,
  name: 'Maaş Kartı',
  number: '4242424242424242',
  expiryMonth: 3,
  expiryYear: 2030,
  cvv: '123',
  pin: pin,
  backgroundId: 'emerald',
  accentId: 'ac_gold',
  createdAt: DateTime.utc(2026, 10, 8, 12),
);

void main() {
  group('detectCardBrand', () {
    test('yaygın markaları tanır', () {
      expect(detectCardBrand('4242 4242'), CardBrand.visa);
      expect(detectCardBrand('5555555555554444'), CardBrand.mastercard);
      expect(detectCardBrand('2223003122003222'), CardBrand.mastercard);
      expect(detectCardBrand('378282246310005'), CardBrand.amex);
      expect(detectCardBrand('9792000000000000'), CardBrand.troy);
      expect(detectCardBrand('6011111111111117'), CardBrand.unknown);
      expect(detectCardBrand(''), CardBrand.unknown);
    });

    test('Amex CVV 4, diğerleri 3 hane', () {
      expect(CardBrand.amex.cvvLength, 4);
      expect(CardBrand.visa.cvvLength, 3);
    });
  });

  group('CardModel', () {
    test('JSON\'a yazılıp aynen geri okunur', () {
      final card = sampleCard();
      expect(CardModel.fromJson(card.toJson()), card);
      expect(CardModel.fromJson(sampleCard(pin: null).toJson()).pin, isNull);
    });

    test('eski sürümün tek renkli (colorId) kaydı yeni modele taşınır', () {
      final json = sampleCard().toJson()
        ..remove('backgroundId')
        ..remove('accentId')
        ..['colorId'] = 'sunset';
      final card = CardModel.fromJson(json);
      expect(card.backgroundId, 'sunset');
      expect(card.accentId, 'ac_orange');
      expect(card.toJson().containsKey('colorId'), isFalse);
    });

    test('bilinmeyen renk kimlikleri varsayılan renge düşer', () {
      expect(
        CardSwatches.background('yok').id,
        CardSwatches.backgrounds.first.id,
      );
      expect(CardSwatches.accent('yok').id, CardSwatches.accents.first.id);
    });

    test('yazı rengi zeminin açıklığına göre seçilir', () {
      const dark = Color(0xFF15181D);
      expect(CardSwatches.background('bg_cream').foreground, dark);
      expect(CardSwatches.background('bg_white').foreground, dark);
      expect(CardSwatches.background('silver').foreground, dark);
      expect(CardSwatches.background('bg_black').foreground, isNot(dark));
      expect(CardSwatches.background('neon').foreground, isNot(dark));
    });

    test('türetilmiş alanlar', () {
      final card = sampleCard();
      expect(card.brand, CardBrand.visa);
      expect(card.lastFour, '4242');
      expect(card.expiryText, '03/30');
    });

    test('toString kart numarasını, CVV ve şifreyi sızdırmaz', () {
      final text = sampleCard().toString();
      expect(text, isNot(contains('4242424242424242')));
      expect(text, isNot(contains('123')));
      expect(text, isNot(contains('1234')));
    });

    test('üretilen kimlikler benzersiz ve 16 karakter', () {
      final ids = {for (var i = 0; i < 100; i++) CardModel.generateId()};
      expect(ids, hasLength(100));
      expect(ids.every((id) => RegExp(r'^[0-9a-f]{16}$').hasMatch(id)), isTrue);
    });
  });

  group('CardRepository / CardsController', () {
    test(
      'kartlar sürüm bilgisiyle tek kayıtta saklanır ve geri okunur',
      () async {
        final store = InMemoryKeyValueStore();
        final repository = CardRepository(store);
        await repository.saveAll([sampleCard(id: 'a'), sampleCard(id: 'b')]);

        expect(store.values['cards.v1'], startsWith('{"version":1'));
        final loaded = await repository.loadAll();
        expect(loaded.map((c) => c.id), ['a', 'b']);
      },
    );

    test('kayıt yokken boş liste döner', () async {
      expect(await CardRepository(InMemoryKeyValueStore()).loadAll(), isEmpty);
    });

    test('add kartı ekler, kaydeder ve dinleyicileri bilgilendirir', () async {
      final store = InMemoryKeyValueStore();
      final controller = CardsController(CardRepository(store));
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.add(sampleCard(id: 'a'));
      await controller.add(sampleCard(id: 'b'));

      expect(controller.cards.map((c) => c.id), ['a', 'b']);
      expect(notified, 2);

      final reloaded = CardsController(CardRepository(store));
      await reloaded.load();
      expect(reloaded.cards, controller.cards);
    });

    test('depoya yazılamazsa bellekteki liste değişmez', () async {
      final controller = CardsController(CardRepository(_FailingStore()));
      await expectLater(controller.add(sampleCard()), throwsException);
      expect(controller.cards, isEmpty);
    });
  });
}

class _FailingStore extends InMemoryKeyValueStore {
  @override
  Future<void> write(String key, String value) async =>
      throw Exception('disk dolu');
}
