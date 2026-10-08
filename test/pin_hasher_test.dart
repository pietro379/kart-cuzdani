import 'package:add_card_app/services/pin_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hasher = PinHasher(iterations: 1000);

  test('kayıt beklenen formatta ve PIN\'i içermiyor', () async {
    final record = await hasher.hash('482916');
    final parts = record.split(r'$');

    expect(parts, hasLength(4));
    expect(parts[0], 'pbkdf2-sha256');
    expect(parts[1], '1000');
    expect(record, isNot(contains('482916')));
  });

  test('doğru PIN doğrulanır, yanlış PIN reddedilir', () async {
    final record = await hasher.hash('482916');
    expect(await hasher.verify('482916', record), isTrue);
    expect(await hasher.verify('482917', record), isFalse);
  });

  test('aynı PIN her seferinde farklı tuzla farklı kayıt üretir', () async {
    final a = await hasher.hash('482916');
    final b = await hasher.hash('482916');
    expect(a, isNot(b));
    expect(await hasher.verify('482916', b), isTrue);
  });

  test('kayıttaki iterasyon sayısı kullanılır', () async {
    final record = await const PinHasher(iterations: 2000).hash('482916');
    expect(await hasher.verify('482916', record), isTrue);
  });

  test('bozuk veya tanınmayan kayıtlar false döner', () async {
    expect(await hasher.verify('482916', 'bozuk'), isFalse);
    expect(await hasher.verify('482916', r'md5$1000$AAAA$AAAA'), isFalse);
    expect(
      await hasher.verify('482916', r'pbkdf2-sha256$x$AAAA$AAAA'),
      isFalse,
    );
    expect(
      await hasher.verify('482916', r'pbkdf2-sha256$1000$!!!$AAAA'),
      isFalse,
    );
  });

  test('isolate kullanmayan mod aynı sonucu verir', () async {
    final record = await hasher.hash('482916');
    const inline = PinHasher(iterations: 1000, runInBackground: false);
    expect(await inline.verify('482916', record), isTrue);
  });
}
