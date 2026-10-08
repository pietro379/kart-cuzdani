import 'package:add_card_app/models/card_model.dart';
import 'package:add_card_app/utils/card_input_formatters.dart';
import 'package:add_card_app/utils/card_validators.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue typed(String text, {int? cursor}) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

void main() {
  final now = DateTime(2026, 10, 8);

  group('passesLuhn', () {
    test('geçerli test numaraları', () {
      expect(passesLuhn('4242424242424242'), isTrue);
      expect(passesLuhn('5555 5555 5555 4444'), isTrue);
      expect(passesLuhn('378282246310005'), isTrue);
    });

    test('tek hane hatası yakalanır', () {
      expect(passesLuhn('4242424242424241'), isFalse);
      expect(passesLuhn(''), isFalse);
    });
  });

  group('CardValidators', () {
    test('kart ismi zorunlu', () {
      expect(CardValidators.name(''), isNotNull);
      expect(CardValidators.name('   '), isNotNull);
      expect(CardValidators.name('Maaş Kartı'), isNull);
    });

    test('kart numarası', () {
      expect(CardValidators.number(''), 'Kart numarası gerekli');
      expect(CardValidators.number('4242 4242'), contains('13-19'));
      expect(
        CardValidators.number('4242 4242 4242 4241'),
        contains('geçersiz'),
      );
      expect(CardValidators.number('3782 8224 6310 0050'), contains('15'));
      expect(CardValidators.number('4242 4242 4242 4242'), isNull);
    });

    test('son kullanma tarihi', () {
      expect(CardValidators.expiry('1230', now: now), contains('AA/YY'));
      expect(CardValidators.expiry('13/30', now: now), 'Geçersiz ay');
      expect(CardValidators.expiry('00/30', now: now), 'Geçersiz ay');
      expect(
        CardValidators.expiry('09/26', now: now),
        contains('süresi dolmuş'),
      );
      expect(CardValidators.expiry('12/60', now: now), 'Geçersiz yıl');
      // İçinde bulunulan ay hâlâ geçerlidir.
      expect(CardValidators.expiry('10/26', now: now), isNull);
      expect(CardValidators.expiry('12/30', now: now), isNull);
    });

    test('CVV uzunluğu markaya göre', () {
      expect(CardValidators.cvv('123', CardBrand.visa), isNull);
      expect(CardValidators.cvv('12', CardBrand.visa), isNotNull);
      expect(CardValidators.cvv('123', CardBrand.amex), isNotNull);
      expect(CardValidators.cvv('1234', CardBrand.amex), isNull);
    });

    test('kart şifresi isteğe bağlı, girilirse 4-6 hane', () {
      expect(CardValidators.pin(''), isNull);
      expect(CardValidators.pin(null), isNull);
      expect(CardValidators.pin('123'), isNotNull);
      expect(CardValidators.pin('1234'), isNull);
      expect(CardValidators.pin('123456'), isNull);
    });
  });

  group('CardNumberInputFormatter', () {
    final formatter = CardNumberInputFormatter();

    TextEditingValue format(TextEditingValue value) =>
        formatter.formatEditUpdate(TextEditingValue.empty, value);

    test('4\'lü gruplar ve imleç sonda', () {
      final result = format(typed('42424242'));
      expect(result.text, '4242 4242');
      expect(result.selection.baseOffset, 9);
    });

    test('rakam dışı karakterler atılır, 19 haneyle sınırlanır', () {
      expect(format(typed('4242-42ab42')).text, '4242 4242');
      expect(
        format(typed('1' * 25)).text.replaceAll(' ', ''),
        hasLength(CardNumberInputFormatter.maxDigits),
      );
    });

    test('ortadan düzenlemede imleç doğru hanede kalır', () {
      // "4242 4242" içinde 5. haneden sonra 9 yazıldı; imleç 9'un hemen ardında
      final result = format(typed('4242 49242', cursor: 7));
      expect(result.text, '4242 4924 2');
      expect(result.selection.baseOffset, 7);
    });
  });

  test('ExpiryDateInputFormatter AA/YY biçimine getirir', () {
    final formatter = ExpiryDateInputFormatter();
    String format(String text) =>
        formatter.formatEditUpdate(TextEditingValue.empty, typed(text)).text;
    expect(format('1'), '1');
    expect(format('12'), '12');
    expect(format('123'), '12/3');
    expect(format('12345'), '12/34');
  });
}
