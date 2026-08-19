import CoreKit
import SwiftUI
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

        let coordinator = AppCoordinator(configuration: AppConfiguration.load())
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(
            rootView: AppRootView(coordinator: coordinator)
        )

        self.window = window
        appCoordinator = coordinator
        window.makeKeyAndVisible()
        coordinator.start()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        appCoordinator?.stop()
        appCoordinator = nil
        window = nil
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        AppLogger.app.debug("Scene entered background")
    }
}
