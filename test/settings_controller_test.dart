import 'package:add_card_app/state/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/in_memory_store.dart';

void main() {
  late InMemoryKeyValueStore store;
  late SettingsController settings;

  setUp(() {
    store = InMemoryKeyValueStore();
    settings = SettingsController(store);
  });

  test('varsayılanlar: isim boş, kart gizleme açık', () async {
    await settings.load();
    expect(settings.userName, '');
    expect(settings.maskCardNumbers, isTrue);
  });

  test('değişiklikler kaydedilir ve yeniden yüklenir', () async {
    await settings.setUserName('  Ayşe Yılmaz ');
    await settings.setMaskCardNumbers(false);

    final reloaded = SettingsController(store);
    await reloaded.load();
    expect(reloaded.userName, 'Ayşe Yılmaz');
    expect(reloaded.maskCardNumbers, isFalse);
  });

  test('çok uzun isim kırpılır', () async {
    await settings.setUserName('a' * 100);
    expect(settings.userName.length, SettingsController.maxUserNameLength);
  });

  test('değişiklikte dinleyiciler bilgilendirilir', () async {
    var notified = 0;
    settings.addListener(() => notified++);
    await settings.setMaskCardNumbers(false);
    await settings.setUserName('Ali');
    expect(notified, 2);
  });

  test('reset bellekteki durumu varsayılana döndürür', () async {
    await settings.setUserName('Ali');
    await settings.setMaskCardNumbers(false);
    settings.reset();
    expect(settings.userName, '');
    expect(settings.maskCardNumbers, isTrue);
  });
}
