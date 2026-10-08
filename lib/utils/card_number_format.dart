/// Kart numarasını 4'lü gruplar halinde biçimlendirir.
///
/// [masked] açıkken son 4 hane dışındaki tüm haneler `*` ile gizlenir:
/// `4242424242424242` → `**** **** **** 4242`
String formatCardNumber(String number, {required bool masked}) {
  final digits = number.replaceAll(RegExp(r'\D'), '');
  final visibleFrom = masked ? digits.length - 4 : 0;

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(i < visibleFrom ? '*' : digits[i]);
  }
  return buffer.toString();
}
