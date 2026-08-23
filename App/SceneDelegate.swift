import CoreKit
import CoreNavigation
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

        // URL yang membuka aplikasi dari keadaan mati.
        if let url = connectionOptions.urlContexts.first?.url {
            handle(url)
        }
    }

    /// URL yang datang ketika aplikasi sudah berjalan.
    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        guard let url = urlContexts.first?.url else { return }
        handle(url)
    }

    private func handle(_ url: URL) {
        guard let deepLink = DeepLink(url: url) else {
            AppLogger.navigation.error("Deep link tidak dapat diurai: \(url.absoluteString, privacy: .public)")
            return
        }
        appCoordinator?.handle(deepLink)
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
