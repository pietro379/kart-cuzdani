import 'package:flutter/widgets.dart';

import 'services/pin_service.dart';
import 'state/cards_controller.dart';
import 'state/settings_controller.dart';
import 'theme/theme_controller.dart';

/// Uygulama genelindeki servis ve durumları alt ekranlara ulaştırır.
///
/// Değişiklikleri dinlemek isteyen ekranlar ilgili controller'ı
/// `ListenableBuilder` ile sarar.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.pinService,
    required this.themeController,
    required this.settings,
    required this.cards,
    required this.onLock,
    required this.onWipeAllData,
    required super.child,
  });

  final PinService pinService;
  final ThemeController themeController;
  final SettingsController settings;
  final CardsController cards;

  /// Cüzdanı hemen kilitler.
  final VoidCallback onLock;

  /// Depodaki her şeyi siler ve uygulamayı ilk kurulum ekranına döndürür.
  final Future<void> Function() onWipeAllData;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope bulunamadı');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      pinService != oldWidget.pinService ||
      themeController != oldWidget.themeController ||
      settings != oldWidget.settings ||
      cards != oldWidget.cards;
}
