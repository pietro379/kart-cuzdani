import 'dart:convert';

import 'package:add_card_app/theme/card_swatches.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/in_memory_store.dart';

const _names = ['Kripto', 'Banka', 'Bonus', 'Seyahat', 'Market'];

InMemoryKeyValueStore storeWithCards() {
  final store = InMemoryKeyValueStore();
  store.values['cards.v1'] = jsonEncode({
    'version': 1,
    'cards': [
      for (var i = 0; i < _names.length; i++)
        {
          'id': 'c$i',
          'name': _names[i],
          'number': '424242424242424$i',
          'expiryMonth': 1 + i,
          'expiryYear': 2030,
          'cvv': '12$i',
          'pin': i == 2 ? '9876' : null,
          'backgroundId': CardSwatches.backgrounds[i].id,
          'accentId': CardSwatches.accents[i].id,
          'createdAt': '2026-10-08T12:00:00.000',
        },
    ],
  });
  return store;
}

/// Ekranda en geniş çizilen kart öndeki karttır (diğerleri küçültülmüş).
String frontCardId(WidgetTester tester) {
  String? best;
  var bestWidth = 0.0;
  for (var i = 0; i < _names.length; i++) {
    final width = tester.getRect(find.byKey(ValueKey('stack_card_c$i'))).width;
    if (width > bestWidth) {
      bestWidth = width;
      best = 'c$i';
    }
  }
  return best!;
}

Finder get stack => find.byKey(const ValueKey('card_stack'));
Finder get revealButton => find.byKey(const ValueKey('reveal_button'));

Future<void> tapFrontCard(WidgetTester tester) async {
  await tester.tap(find.byKey(ValueKey('stack_card_${frontCardId(tester)}')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ilk açılışta ortadaki kart önde', (tester) async {
    await pumpUnlockedApp(tester, store: storeWithCards());
    expect(frontCardId(tester), 'c2');
  });

  testWidgets(
    'yukarı kaydırınca sonraki, aşağı kaydırınca önceki kart öne gelir',
    (tester) async {
      await pumpUnlockedApp(tester, store: storeWithCards());

      await tester.drag(stack, const Offset(0, -75));
      await tester.pumpAndSettle();
      expect(frontCardId(tester), 'c3');

      await tester.drag(stack, const Offset(0, 150));
      await tester.pumpAndSettle();
      expect(frontCardId(tester), 'c1');
    },
  );

  testWidgets('kaydırma uçlarda sınırlanır', (tester) async {
    await pumpUnlockedApp(tester, store: storeWithCards());

    await tester.drag(stack, const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(frontCardId(tester), 'c0');

    await tester.drag(stack, const Offset(0, -4000));
    await tester.pumpAndSettle();
    expect(frontCardId(tester), 'c4');
  });

  testWidgets('arkadaki karta dokunmak onu öne getirmez', (tester) async {
    await pumpUnlockedApp(tester, store: storeWithCards());

    await tester.tap(
      find.text('Kripto', findRichText: true),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(frontCardId(tester), 'c2');
  });

  testWidgets('öndeki karta dokununca arka yüz (CVV + şifre) görünür', (
    tester,
  ) async {
    await pumpUnlockedApp(tester, store: storeWithCards());

    // Ön yüzde CVV yok
    expect(find.text('CVV'), findsNothing);

    await tapFrontCard(tester);
    expect(find.text('CVV'), findsOneWidget);
    expect(find.text('KART ŞİFRESİ'), findsOneWidget);
    // Gizleme açık: CVV ve şifre yıldızlı
    expect(find.text('***'), findsOneWidget);
    expect(find.text('****'), findsOneWidget);

    // Tekrar dokununca ön yüze döner
    await tapFrontCard(tester);
    expect(find.text('CVV'), findsNothing);
  });

  testWidgets('başka kart öne gelince çevrilmiş kart düzelir', (tester) async {
    await pumpUnlockedApp(tester, store: storeWithCards());

    await tapFrontCard(tester);
    expect(find.text('CVV'), findsOneWidget);

    await tester.drag(stack, const Offset(0, -75));
    await tester.pumpAndSettle();
    expect(find.text('CVV'), findsNothing);
  });

  testWidgets('şifresi olmayan kartın arka yüzünde "Belirlenmedi" yazar', (
    tester,
  ) async {
    await pumpUnlockedApp(tester, store: storeWithCards());
    await tester.drag(stack, const Offset(0, -75));
    await tester.pumpAndSettle();

    await tapFrontCard(tester);
    expect(find.text('Belirlenmedi'), findsOneWidget);
  });

  testWidgets(
    'göze basılı tutunca yalnızca öndeki kart açılır, bırakınca gizlenir',
    (tester) async {
      await pumpUnlockedApp(tester, store: storeWithCards());

      expect(find.text('4242 4242 4242 4242'), findsNothing);

      final gesture = await tester.startGesture(tester.getCenter(revealButton));
      await tester.pump();
      // Öndeki kart (c2) açıldı; diğerleri hâlâ gizli.
      expect(find.text('4242 4242 4242 4242'), findsOneWidget);
      expect(find.text('4242 4242 4242 4241'), findsNothing);

      await gesture.up();
      await tester.pump();
      expect(find.text('4242 4242 4242 4242'), findsNothing);
      expect(find.text('**** **** **** 4242'), findsWidgets);
    },
  );

  testWidgets('göz arka yüzde CVV ve şifreyi de açar', (tester) async {
    await pumpUnlockedApp(tester, store: storeWithCards());
    await tapFrontCard(tester);

    final gesture = await tester.startGesture(tester.getCenter(revealButton));
    await tester.pump();
    expect(find.text('122'), findsOneWidget);
    expect(find.text('9876'), findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(find.text('122'), findsNothing);
    expect(find.text('***'), findsOneWidget);
  });

  testWidgets('gizleme kapalıyken bilgiler açık ve göz pasif', (tester) async {
    final store = storeWithCards();
    store.values['pref.mask_card_numbers'] = 'false';
    await pumpUnlockedApp(tester, store: store);

    expect(find.text('4242 4242 4242 4242'), findsOneWidget);
    expect(find.text('4242 4242 4242 4241'), findsOneWidget);

    await tapFrontCard(tester);
    expect(find.text('122'), findsOneWidget);
    expect(find.text('9876'), findsOneWidget);
  });
}
