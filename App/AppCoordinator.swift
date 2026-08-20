import Combine
import CoreGuards
import CoreKit
import CoreNetwork
import FeatureAuth
import FeatureSplash
import Foundation
import UIKit

/// Owns app-level state: which root flow is on screen, the global blocker, and the
/// session/network objects that outlive any single flow.
///
/// It deliberately holds no flow object. Swapping `rootState.content` lets SwiftUI tear
/// down the whole flow — its router, screens, and ViewModels — so there is no child
/// coordinator to release by hand.
@MainActor
final class AppCoordinator: ObservableObject {
    @Published private(set) var rootState = AppRootState.initial

    let fpsMonitor: FrameRateMonitor?

    /// Satu object yang memenuhi protokol kebutuhan setiap feature. Diserahkan apa adanya
    /// ke flow; masing-masing flow hanya melihat bagian yang ia butuhkan.
    let dependencies: AppDependencies

    private let configuration: AppConfiguration
    private let rootGuard: RootGuardMonitor
    private let apiClient: AlamofireAPIClient
    private let sessionStore: AppSessionStore
    private var hasStartedInitialFlow = false

    init(
        configuration: AppConfiguration,
        secrets: any AppSecretProviding = PlaceholderAppSecrets(),
        networkTracer: any NetworkTracing = NoOpNetworkTracer(),
        initialCredential: OAuthCredential? = nil
    ) {
        self.configuration = configuration
        rootGuard = RootGuardMonitor(
            integrityChecker: LaunchArgumentDeviceIntegrityChecker(),
            simulatesActiveCall: ProcessInfo.processInfo.arguments.contains(
                "-simulateActiveCall"
            )
        )
        let sessionStore = AppSessionStore(initialCredential: initialCredential)
        self.sessionStore = sessionStore
        let apiClient = AppNetworkComposition.makeAPIClient(
            configuration: configuration,
            sessionStore: sessionStore,
            secrets: secrets,
            tracer: networkTracer
        )
        self.apiClient = apiClient
        fpsMonitor = configuration.showFPS ? FrameRateMonitor() : nil
        dependencies = AppDependencies(
            apiClient: apiClient,
            configuration: configuration
        )

        apiClient.updateCredential(initialCredential)
        // The handler is `@Sendable` and runs off the main actor, so the task does not
        // inherit isolation. Pin it to `@MainActor` rather than awaiting through an
        // optional chain — `await self?.method()` has to hop actors and unwrap in the same
        // expression, which is what the type checker cannot resolve.
        apiClient.setUnauthorizedHandler { [weak self] in
            Task { @MainActor in
                self?.handleUnauthorizedSession()
            }
        }
    }

    func start() {
        rootGuard.onReasonChanged = { [weak self] reason in
            guard let self else { return }
            self.rootState.blocker = reason
            if let reason {
                AppLogger.security.warning(
                    "Root blocker active: \(reason.rawValue, privacy: .public)"
                )
            } else {
                AppLogger.security.debug("Root blocker cleared")
                self.startInitialFlowIfPossible()
            }
        }
        rootGuard.start()
        fpsMonitor?.start()
        startInitialFlowIfPossible()
    }

    func stop() {
        apiClient.setUnauthorizedHandler(nil)
        rootGuard.stop()
        fpsMonitor?.stop()
    }

    func retryRootGuard() {
        rootGuard.refresh()
    }

    func openAppStore() {
        guard let url = configuration.appStoreURL else { return }
        UIApplication.shared.open(url)
    }

    func handleLaunchDestination(_ destination: LaunchDestination) {
        switch destination {
        case .main where sessionStore.currentCredential() != nil:
            showMain()
        case .preLogin, .main:
            showPreLogin()
        case .maintenance, .forceUpdate:
            break
        }
    }

    func handleAuthenticated(_ session: AuthSession) {
        let credential = OAuthCredential(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiration: session.expiration
        )
        sessionStore.save(credential: credential)
        apiClient.updateCredential(credential)
        showMain()
    }

    func handleLogout() {
        showPreLogin()
    }

    private func handleUnauthorizedSession() {
        guard rootState.content == .main else { return }
        AppLogger.security.warning("Authenticated session expired")
        showPreLogin()
    }

    private func startInitialFlowIfPossible() {
        guard !hasStartedInitialFlow, rootState.blocker == nil else { return }
        hasStartedInitialFlow = true
        transitionContent(to: .splash)
    }

    private func showPreLogin() {
        sessionStore.clear()
        apiClient.updateCredential(nil)
        transitionContent(to: .preLogin)
    }

    private func showMain() {
        transitionContent(to: .main)
    }

    private func transitionContent(to content: AppRootContentState) {
        guard rootState.content != content else { return }
        AppLogger.navigation.info(
            "Root transition: \(self.rootState.content.rawValue, privacy: .public) -> \(content.rawValue, privacy: .public)"
        )
        rootState.content = content
    }
}
