/// Türkçe kurallarına göre büyük harfe çevirir (i → İ, ı → I).
/// Dart'ın `toUpperCase()` metodu "Ayşe Işık" gibi isimlerde i'yi I yapar.
String turkishUpperCase(String text) =>
    text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// Ad soyaddan en fazla iki harflik baş harf üretir: "ayşe yılmaz" → "AY".
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => String.fromCharCode(p.runes.first));
  return turkishUpperCase(letters.join());
}
