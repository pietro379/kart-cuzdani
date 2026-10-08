import 'package:flutter/services.dart';

import 'card_number_format.dart';

/// Yazarken numarayı 4'lü gruplara ayırır (`4242 4242 ...`), en fazla 19 hane.
/// İmleç, araya giren boşluklara rağmen doğru hanenin yanında kalır.
class CardNumberInputFormatter extends TextInputFormatter {
  static const maxDigits = 19;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);

    var cursor = newValue.selection.end;
    if (cursor < 0 || cursor > newValue.text.length) {
      cursor = newValue.text.length;
    }
    var digitsBeforeCursor = newValue.text
        .substring(0, cursor)
        .replaceAll(RegExp(r'\D'), '')
        .length;
    if (digitsBeforeCursor > digits.length) digitsBeforeCursor = digits.length;

    // Her 4 haneden sonra bir boşluk eklenir.
    final int spacesBeforeCursor = digitsBeforeCursor == 0
        ? 0
        : (digitsBeforeCursor - 1) ~/ 4;
    final int offset = digitsBeforeCursor + spacesBeforeCursor;

    return TextEditingValue(
      text: formatCardNumber(digits, masked: false),
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// Yazarken `AA/YY` biçimine getirir: `1230` → `12/30`.
class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    final text = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
