import CoreKit
import UIKit

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let coordinator = AppCoordinator(
            window: window,
            configuration: AppConfiguration.load()
        )
        self.window = window
        appCoordinator = coordinator
        coordinator.start()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        AppLogger.app.debug("Scene entered background")
    }
}
