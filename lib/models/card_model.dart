import 'dart:math';

import 'package:flutter/foundation.dart';

import '../theme/card_swatches.dart';

enum CardBrand {
  visa('VISA'),
  mastercard('MASTERCARD'),
  amex('AMEX'),
  troy('TROY'),
  unknown('');

  const CardBrand(this.label);

  final String label;

  /// American Express kartlarında CVV 4 hanelidir.
  int get cvvLength => this == CardBrand.amex ? 4 : 3;
}

/// Kart numarasının ilk hanelerinden (IIN) markayı tahmin eder.
CardBrand detectCardBrand(String number) {
  final digits = number.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return CardBrand.unknown;
  if (digits.startsWith('4')) return CardBrand.visa;
  if (RegExp(r'^3[47]').hasMatch(digits)) return CardBrand.amex;
  if (digits.startsWith('9792')) return CardBrand.troy;
  if (RegExp(r'^5[1-5]').hasMatch(digits)) return CardBrand.mastercard;
  if (digits.length >= 4) {
    final prefix = int.parse(digits.substring(0, 4));
    if (prefix >= 2221 && prefix <= 2720) return CardBrand.mastercard;
  }
  return CardBrand.unknown;
}

/// Cihazda şifreli saklanan tek bir kart.
@immutable
class CardModel {
  const CardModel({
    required this.id,
    required this.name,
    required this.number,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    required this.backgroundId,
    required this.accentId,
    required this.createdAt,
    this.pin,
  });

  final String id;

  /// Kullanıcının verdiği isim, örn. "Maaş Kartı".
  final String name;

  /// Yalnızca rakamlar (boşluksuz).
  final String number;
  final int expiryMonth;

  /// Dört haneli yıl, örn. 2030.
  final int expiryYear;
  final String cvv;

  /// İsteğe bağlı kart şifresi (ATM PIN'i).
  final String? pin;

  /// Kart (zemin) renginin kimliği (bkz. `CardSwatches.backgrounds`).
  final String backgroundId;

  /// Desen renginin kimliği (bkz. `CardSwatches.accents`).
  final String accentId;
  final DateTime createdAt;

  CardBrand get brand => detectCardBrand(number);

  String get lastFour =>
      number.length <= 4 ? number : number.substring(number.length - 4);

  /// `AA/YY`
  String get expiryText =>
      '${expiryMonth.toString().padLeft(2, '0')}/'
      '${(expiryYear % 100).toString().padLeft(2, '0')}';

  /// Tahmin edilemeyen, 16 karakterlik onaltılık kimlik.
  static String generateId() {
    final random = Random.secure();
    return List.generate(
      8,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'number': number,
    'expiryMonth': expiryMonth,
    'expiryYear': expiryYear,
    'cvv': cvv,
    'pin': pin,
    'backgroundId': backgroundId,
    'accentId': accentId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CardModel.fromJson(Map<String, dynamic> json) {
    // Eski sürüm tek renk (colorId) saklıyordu: zemin aynı kimlikle,
    // desen rengi eşleme tablosundan alınır.
    final legacyColor = json['colorId'] as String?;
    return CardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      number: json['number'] as String,
      expiryMonth: json['expiryMonth'] as int,
      expiryYear: json['expiryYear'] as int,
      cvv: json['cvv'] as String,
      pin: json['pin'] as String?,
      backgroundId:
          json['backgroundId'] as String? ??
          legacyColor ??
          CardSwatches.defaultBackgroundId,
      accentId:
          json['accentId'] as String? ??
          CardSwatches.legacyAccentFor[legacyColor] ??
          CardSwatches.defaultAccentId,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CardModel &&
      other.id == id &&
      other.name == name &&
      other.number == number &&
      other.expiryMonth == expiryMonth &&
      other.expiryYear == expiryYear &&
      other.cvv == cvv &&
      other.pin == pin &&
      other.backgroundId == backgroundId &&
      other.accentId == accentId &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    number,
    expiryMonth,
    expiryYear,
    cvv,
    pin,
    backgroundId,
    accentId,
    createdAt,
  );

  /// Kart verisinin yanlışlıkla loglara düşmemesi için yalnızca son 4 hane.
  @override
  String toString() => 'CardModel($id, $name, **** $lastFour)';
}
