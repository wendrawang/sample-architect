import CoreGuards
import CoreKit
import CoreNavigation
import CoreNetwork
import FeatureAuth
import FeatureMain
import FeatureSplash
import UIKit

@MainActor
final class AppCoordinator: BaseCoordinator {
    private let window: UIWindow
    private let configuration: AppConfiguration
    private let navigationController: UINavigationController
    private let rootContainer: RootContainerViewController
    private let rootGuard: RootGuardMonitor
    private let apiClient: AlamofireAPIClient
    private let sessionStore: AppSessionStore
    private let fpsMonitor = FrameRateMonitor()

    private var authCoordinator: AuthCoordinator?
    private var mainCoordinator: MainCoordinator?
    private var rootState = AppRootState.initial
    private var hasStartedInitialFlow = false

    init(
        window: UIWindow,
        configuration: AppConfiguration,
        secrets: any AppSecretProviding = PlaceholderAppSecrets(),
        networkTracer: any NetworkTracing = NoOpNetworkTracer(),
        initialCredential: OAuthCredential? = nil
    ) {
        self.window = window
        self.configuration = configuration
        let navigationController = UINavigationController()
        self.navigationController = navigationController
        rootContainer = RootContainerViewController(
            navigationController: navigationController
        )
        rootGuard = RootGuardMonitor(
            integrityChecker: LaunchArgumentDeviceIntegrityChecker(),
            simulatesActiveCall: ProcessInfo.processInfo.arguments.contains(
                "-simulateActiveCall"
            )
        )
        let sessionStore = AppSessionStore(initialCredential: initialCredential)
        self.sessionStore = sessionStore
        apiClient = AppNetworkComposition.makeAPIClient(
            configuration: configuration,
            sessionStore: sessionStore,
            secrets: secrets,
            tracer: networkTracer
        )
        super.init()
        apiClient.updateCredential(initialCredential)
        apiClient.setUnauthorizedHandler { [weak self] in
            Task { [weak self] in
                await self?.handleUnauthorizedSession()
            }
        }
    }

    override func start() {
        window.rootViewController = rootContainer
        window.makeKeyAndVisible()

        rootGuard.onReasonChanged = { [weak self] reason in
            guard let self else { return }
            self.rootState.blocker = reason
            if let reason {
                AppLogger.security.warning(
                    "Root blocker active: \(reason.rawValue, privacy: .public)"
                )
            } else {
                AppLogger.security.debug("Root blocker cleared")
            }
            self.rootContainer.setBlocker(reason) { [weak self] in
                self?.rootGuard.refresh()
            }
            if reason == nil {
                self.startInitialFlowIfPossible()
            }
        }
        rootGuard.start()

        if configuration.showFPS {
            fpsMonitor.start()
            rootContainer.showFPS(fpsMonitor)
        }

        startInitialFlowIfPossible()
    }

    override func stop() {
        apiClient.setUnauthorizedHandler(nil)
        rootGuard.stop()
        fpsMonitor.stop()
        authCoordinator?.stop()
        mainCoordinator?.stop()
        authCoordinator = nil
        mainCoordinator = nil
        super.stop()
    }

    private func showSplash() {
        transitionContent(to: .splash)

        let repository: any SplashRepositoryProtocol
        if configuration.useMockServices {
            let arguments = ProcessInfo.processInfo.arguments
            let destination: LaunchDestination
            if arguments.contains("-simulateMaintenance") {
                destination = .maintenance
            } else if arguments.contains("-simulateForceUpdate") {
                destination = .forceUpdate
            } else {
                destination = .preLogin
            }
            repository = MockSplashRepository(
                decision: LaunchDecision(destination: destination),
                shouldFail: arguments.contains("-simulateSplashFailure")
            )
        } else {
            repository = RemoteSplashRepository(
                apiClient: apiClient,
                path: configuration.splashInquiryPath
            )
        }

        let viewModel = SplashViewModel(
            useCase: PrepareLaunchUseCase(repository: repository),
            onRoute: { [weak self] destination in
                self?.handleLaunchDestination(destination)
            },
            onUpdateRequested: { [weak self] in
                guard let url = self?.configuration.appStoreURL else { return }
                UIApplication.shared.open(url)
            }
        )
        let controller = ScreenHostingController(
            rootView: SplashView(viewModel: viewModel),
            hidesNavigationBar: true
        )
        navigationController.setViewControllers([controller], animated: false)
    }

    private func startInitialFlowIfPossible() {
        guard !hasStartedInitialFlow, rootState.blocker == nil else { return }
        hasStartedInitialFlow = true
        showSplash()
    }

    private func handleUnauthorizedSession() {
        guard rootState.content == .main else { return }
        AppLogger.security.warning("Authenticated session expired")
        showPreLogin()
    }

    private func showPreLogin() {
        transitionContent(to: .preLogin)
        sessionStore.clear()
        apiClient.updateCredential(nil)
        releaseMainFlow()
        releaseAuthFlow()

        let repository: any AuthRepositoryProtocol
        if configuration.useMockServices {
            repository = MockAuthRepository()
        } else {
            repository = RemoteAuthRepository(apiClient: apiClient)
        }

        let coordinator = AuthCoordinator(
            navigationController: navigationController,
            repository: repository,
            onAuthenticated: { [weak self] session in
                guard let self else { return }
                let credential = OAuthCredential(
                    accessToken: session.accessToken,
                    refreshToken: session.refreshToken,
                    expiration: session.expiration
                )
                self.sessionStore.save(credential: credential)
                self.apiClient.updateCredential(credential)
                self.showMain()
            }
        )
        authCoordinator = coordinator
        coordinator.start()
    }

    private func handleLaunchDestination(_ destination: LaunchDestination) {
        switch destination {
        case .main where sessionStore.currentCredential() != nil:
            showMain()
        case .preLogin, .main:
            showPreLogin()
        case .maintenance, .forceUpdate:
            break
        }
    }

    private func showMain() {
        transitionContent(to: .main)
        releaseAuthFlow()
        releaseMainFlow()

        let dependencies = MainDependencies.make(
            apiClient: apiClient,
            useMocks: configuration.useMockServices
        )
        let coordinator = MainCoordinator(
            navigationController: navigationController,
            dependencies: dependencies,
            onLogout: { [weak self] in
                self?.showPreLogin()
            }
        )
        mainCoordinator = coordinator
        coordinator.start()
    }

    private func releaseAuthFlow() {
        guard let coordinator = authCoordinator else { return }
        coordinator.stop()
        authCoordinator = nil
        LeakWatchdog.expectDeallocation(of: coordinator, named: "AuthCoordinator")
    }

    private func releaseMainFlow() {
        guard let coordinator = mainCoordinator else { return }
        coordinator.stop()
        mainCoordinator = nil
        LeakWatchdog.expectDeallocation(of: coordinator, named: "MainCoordinator")
    }

    private func transitionContent(to content: AppRootContentState) {
        guard rootState.content != content else { return }
        AppLogger.navigation.info(
            "Root transition: \(self.rootState.content.rawValue, privacy: .public) -> \(content.rawValue, privacy: .public)"
        )
        rootState.content = content
    }
}
