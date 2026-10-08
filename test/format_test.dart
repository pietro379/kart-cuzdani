import 'package:add_card_app/utils/card_number_format.dart';
import 'package:add_card_app/utils/text_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatCardNumber', () {
    test('gizliyken son 4 hane dışı maskelenir', () {
      expect(
        formatCardNumber('4242424242424242', masked: true),
        '**** **** **** 4242',
      );
    });

    test('açıkken 4\'lü gruplar halinde okunur', () {
      expect(
        formatCardNumber('4242424242424242', masked: false),
        '4242 4242 4242 4242',
      );
    });

    test('boşluk ve tireler yok sayılır', () {
      expect(
        formatCardNumber('4242-4242 4242 4242', masked: true),
        '**** **** **** 4242',
      );
    });

    test('15 haneli (Amex) numaralar da desteklenir', () {
      expect(
        formatCardNumber('378282246310005', masked: true),
        '**** **** ***0 005',
      );
    });
  });

  group('turkishUpperCase', () {
    test('i/ı harflerini Türkçe kurala göre büyütür', () {
      expect(turkishUpperCase('ayşe yılmaz'), 'AYŞE YILMAZ');
      expect(turkishUpperCase('özgür işık'), 'ÖZGÜR İŞIK');
    });
  });

  group('initialsOf', () {
    test('ilk iki kelimenin baş harfleri', () {
      expect(initialsOf('ayşe yılmaz'), 'AY');
      expect(initialsOf('  ismail  '), 'İ');
      expect(initialsOf('a b c'), 'AB');
    });
  });
}
