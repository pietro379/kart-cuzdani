import '../models/card_model.dart';

String digitsOnly(String text) => text.replaceAll(RegExp(r'\D'), '');

/// Kart numaralarındaki kontrol hanesini doğrulayan Luhn algoritması.
/// Yanlış yazılan numaraların (tek hane hatası, yer değiştirme) çoğunu yakalar.
bool passesLuhn(String number) {
  final digits = digitsOnly(number);
  if (digits.isEmpty) return false;
  var sum = 0;
  for (var i = 0; i < digits.length; i++) {
    var digit = digits.codeUnitAt(digits.length - 1 - i) - 48;
    if (i.isOdd) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    sum += digit;
  }
  return sum % 10 == 0;
}

/// `AA/YY` → (ay, dört haneli yıl); biçim hatalıysa null.
(int, int)? parseExpiry(String text) {
  final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(text.trim());
  if (match == null) return null;
  return (int.parse(match[1]!), 2000 + int.parse(match[2]!));
}

abstract final class CardValidators {
  static const maxNameLength = 24;

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Kart ismi gerekli';
    if (text.length > maxNameLength) {
      return 'En fazla $maxNameLength karakter olabilir';
    }
    return null;
  }

  static String? number(String? value) {
    final digits = digitsOnly(value ?? '');
    if (digits.isEmpty) return 'Kart numarası gerekli';
    final brand = detectCardBrand(digits);
    if (brand == CardBrand.amex && digits.length != 15) {
      return 'American Express kartları 15 hanelidir';
    }
    if (digits.length < 13 || digits.length > 19) {
      return 'Kart numarası 13-19 hane olmalı';
    }
    if (!passesLuhn(digits)) return 'Kart numarası geçersiz, kontrol edin';
    return null;
  }

  static String? expiry(String? value, {DateTime? now}) {
    final parsed = parseExpiry(value ?? '');
    if (parsed == null) return 'AA/YY biçiminde girin';
    final (month, year) = parsed;
    if (month < 1 || month > 12) return 'Geçersiz ay';

    final today = now ?? DateTime.now();
    // Kart, son kullanma ayının son gününe kadar geçerlidir.
    final firstDayAfterExpiry = DateTime(year, month + 1);
    if (!today.isBefore(firstDayAfterExpiry)) return 'Kartın süresi dolmuş';
    if (year > today.year + 20) return 'Geçersiz yıl';
    return null;
  }

  static String? cvv(String? value, CardBrand brand) {
    final length = brand.cvvLength;
    if (!RegExp('^\\d{$length}\$').hasMatch(value ?? '')) {
      return 'CVV $length haneli olmalı';
    }
    return null;
  }

  /// Kart şifresi isteğe bağlıdır; girilirse 4-6 hane olmalı.
  static String? pin(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^\d{4,6}$').hasMatch(value)) return 'Şifre 4-6 haneli olmalı';
    return null;
  }
}
