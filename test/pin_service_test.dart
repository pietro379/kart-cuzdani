import 'package:add_card_app/services/pin_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/in_memory_store.dart';
import 'helpers/test_hasher.dart';

void main() {
  late InMemoryKeyValueStore store;
  late DateTime now;
  late PinService service;

  setUp(() {
    store = InMemoryKeyValueStore();
    now = DateTime(2026, 10, 8, 12);
    service = PinService(store, hasher: testHasher, clock: () => now);
  });

  test('PIN yokken hasPin false, kaydedince true döner', () async {
    expect(await service.hasPin(), isFalse);
    await service.setPin('482916');
    expect(await service.hasPin(), isTrue);
  });

  test('PIN depoya düz metin olarak yazılmaz', () async {
    await service.setPin('482916');
    expect(store.values['auth.pin_hash'], startsWith('pbkdf2-sha256\$'));
    expect(store.values.values.any((v) => v.contains('482916')), isFalse);
  });

  test('eski sürümden kalan düz PIN ilk doğru girişte özete taşınır', () async {
    store.values['auth.pin'] = '482916';
    expect(await service.hasPin(), isTrue);

    expect((await service.verify('000001')).result, PinCheckResult.wrong);
    expect(store.values, contains('auth.pin'));

    expect((await service.verify('482916')).result, PinCheckResult.success);
    expect(store.values, isNot(contains('auth.pin')));
    expect(store.values, contains('auth.pin_hash'));
    expect((await service.verify('482916')).result, PinCheckResult.success);
  });

  test('geçersiz formattaki PIN reddedilir', () {
    expect(() => service.setPin('12a456'), throwsArgumentError);
    expect(() => service.setPin('12345'), throwsArgumentError);
  });

  test('zayıf PIN\'ler tespit edilir', () {
    expect(PinService.isWeakPin('111111'), isTrue);
    expect(PinService.isWeakPin('123456'), isTrue);
    expect(PinService.isWeakPin('987654'), isTrue);
    expect(PinService.isWeakPin('482916'), isFalse);
  });

  test('doğru PIN başarılı, hatalı PIN kalan hakkı azaltır', () async {
    await service.setPin('482916');

    final wrong = await service.verify('000001');
    expect(wrong.result, PinCheckResult.wrong);
    expect(wrong.remainingAttempts, PinService.maxAttempts - 1);

    final ok = await service.verify('482916');
    expect(ok.result, PinCheckResult.success);

    // Başarılı girişten sonra sayaç sıfırlanır.
    final again = await service.verify('000001');
    expect(again.remainingAttempts, PinService.maxAttempts - 1);
  });

  test('art arda hatalı denemeler kilitler, süre dolunca açılır', () async {
    await service.setPin('482916');

    for (var i = 0; i < PinService.maxAttempts - 1; i++) {
      expect((await service.verify('000001')).result, PinCheckResult.wrong);
    }
    final locked = await service.verify('000001');
    expect(locked.result, PinCheckResult.lockedOut);

    // Kilitliyken doğru PIN bile kabul edilmez.
    expect((await service.verify('482916')).result, PinCheckResult.lockedOut);

    // Yeniden başlatma: kilit depoda kalıcıdır.
    final restarted = PinService(store, hasher: testHasher, clock: () => now);
    expect(await restarted.lockoutRemaining(), PinService.lockoutDuration);

    now = now.add(PinService.lockoutDuration);
    expect((await service.verify('482916')).result, PinCheckResult.success);
  });
}
