import UIKit
import AdyenActions

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        RedirectComponent.applicationDidOpen(from: urlContext.url)
    }
}
