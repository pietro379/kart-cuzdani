import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let privacyShield = PrivacyShield()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    privacyShield.start()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

/// Kart bilgilerinin ekran dışına sızmasını engeller (Android'deki FLAG_SECURE karşılığı):
///
/// 1. Ekran görüntüsü ve ekran kaydında uygulama içeriği boş görünür. iOS bunun için
///    resmi bir API sunmadığından, pencere katmanı şifre alanlarının (isSecureTextEntry)
///    kullandığı korumalı katmanın içine taşınır.
/// 2. Uygulama değiştiricide (app switcher) ve Kontrol Merkezi açıkken içerik yerine
///    düz bir perde gösterilir.
/// 3. Ekran kaydı veya AirPlay yansıtma sürerken içerik perdeyle kapalı kalır.
///
/// FlutterSceneDelegate'in yaşam döngüsü metotları ezilmez (Flutter'ın uygulama durumu
/// bildirimleri bozulmasın diye); olaylar NotificationCenter üzerinden dinlenir.
final class PrivacyShield {
  private var observers: [NSObjectProtocol] = []
  private weak var window: UIWindow?
  private var secureField: UITextField?
  private var cover: UIView?

  func start() {
    let center = NotificationCenter.default
    observers = [
      center.addObserver(
        forName: UIScene.didActivateNotification, object: nil, queue: .main
      ) { [weak self] note in
        guard let self, let window = Self.window(of: note.object) else { return }
        self.window = window
        self.protectFromScreenCapture(window)
        self.setCoverVisible(self.isScreenCaptured)
      },
      center.addObserver(
        forName: UIScene.willDeactivateNotification, object: nil, queue: .main
      ) { [weak self] note in
        guard let self, let window = Self.window(of: note.object) else { return }
        self.window = window
        self.setCoverVisible(true)
      },
      center.addObserver(
        forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main
      ) { [weak self] _ in
        guard let self else { return }
        self.setCoverVisible(self.isScreenCaptured)
      },
    ]
  }

  private var isScreenCaptured: Bool {
    window?.windowScene?.screen.isCaptured ?? false
  }

  private static func window(of object: Any?) -> UIWindow? {
    guard let scene = object as? UIWindowScene else { return nil }
    return scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first
  }

  private func protectFromScreenCapture(_ window: UIWindow) {
    guard secureField == nil, let superlayer = window.layer.superlayer else { return }

    let field = UITextField()
    field.isSecureTextEntry = true
    field.isUserInteractionEnabled = false
    window.addSubview(field)
    superlayer.addSublayer(field.layer)

    // Korumalı içerik katmanı iOS 17 ve sonrasında son, öncesinde ilk alt katmandır.
    let secureContainer: CALayer?
    if #available(iOS 17.0, *) {
      secureContainer = field.layer.sublayers?.last
    } else {
      secureContainer = field.layer.sublayers?.first
    }
    secureContainer?.addSublayer(window.layer)
    secureField = field
  }

  private func setCoverVisible(_ visible: Bool) {
    guard let window else { return }
    if !visible {
      cover?.removeFromSuperview()
      cover = nil
      return
    }
    guard cover == nil else { return }

    let view = UIView(frame: window.bounds)
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.backgroundColor = .systemBackground

    let icon = UIImageView(image: UIImage(systemName: "lock.shield"))
    icon.tintColor = .secondaryLabel
    icon.contentMode = .scaleAspectFit
    icon.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(icon)
    NSLayoutConstraint.activate([
      icon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      icon.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      icon.widthAnchor.constraint(equalToConstant: 64),
      icon.heightAnchor.constraint(equalToConstant: 64),
    ])

    window.addSubview(view)
    cover = view
  }
}
