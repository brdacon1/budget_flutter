import UIKit
import Flutter

/// Herda de `FlutterSceneDelegate` para que os eventos de cena (URL de
/// abertura no cold start e `openURLContexts` no warm start) sejam repassados
/// aos plugins — sem isso o `receive_sharing_intent` nunca recebe a URL
/// `ShareMedia-…` da Share Extension e a imagem compartilhada se perde.
@available(iOS 13.0, *)
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let flutterEngine = FlutterEngine(name: "scene_engine")
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)
    // Liga os plugins deste engine ao ciclo de vida da cena.
    registerSceneLifeCycle(with: flutterEngine)

    let flutterViewController = FlutterViewController(
      engine: flutterEngine,
      nibName: nil,
      bundle: nil
    )

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = flutterViewController
    self.window = window
    window.makeKeyAndVisible()

    // Repassa connectionOptions (URL do cold start) aos plugins.
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
