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
    private let navigationController = UINavigationController()
    private let rootContainer: RootContainerViewController
    private let rootGuard: RootGuardMonitor
    private let apiClient: AlamofireAPIClient
    private let sessionStore: AppSessionStore
    private let fpsMonitor = FrameRateMonitor()

    private var authCoordinator: AuthCoordinator?
    private var mainCoordinator: MainCoordinator?
    private var rootState = AppRootState.initial

    init(window: UIWindow, configuration: AppConfiguration) {
        self.window = window
        self.configuration = configuration
        rootContainer = RootContainerViewController(
            navigationController: navigationController
        )
        rootGuard = RootGuardMonitor(
            integrityChecker: LaunchArgumentDeviceIntegrityChecker()
        )
        let sessionStore = AppSessionStore()
        self.sessionStore = sessionStore
        apiClient = AlamofireAPIClient(
            baseURL: configuration.apiBaseURL,
            defaultHeaders: { [weak sessionStore] in
                sessionStore?.authorizationHeaders() ?? [:]
            }
        )
        super.init()
    }

    override func start() {
        window.rootViewController = rootContainer
        window.makeKeyAndVisible()

        rootGuard.onReasonChanged = { [weak self] reason in
            guard let self else { return }
            self.rootState.blocker = reason
            self.rootContainer.setBlocker(reason) { [weak self] in
                self?.rootGuard.refresh()
            }
        }
        rootGuard.start()

        if configuration.showFPS {
            fpsMonitor.start()
            rootContainer.showFPS(fpsMonitor)
        }

        showSplash()
    }

    override func stop() {
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
        let viewModel = SplashViewModel(
            useCase: PrepareLaunchUseCase(),
            onFinished: { [weak self] in
                self?.showPreLogin()
            }
        )
        let controller = ScreenHostingController(
            rootView: SplashView(viewModel: viewModel),
            hidesNavigationBar: true
        )
        navigationController.setViewControllers([controller], animated: false)
    }

    private func showPreLogin() {
        transitionContent(to: .preLogin)
        sessionStore.clear()
        releaseMainFlow()
        releaseAuthFlow()

        let repository: AuthRepositoryProtocol
        if configuration.useMockServices {
            repository = MockAuthRepository()
        } else {
            repository = RemoteAuthRepository(apiClient: apiClient)
        }

        let coordinator = AuthCoordinator(
            navigationController: navigationController,
            repository: repository,
            onAuthenticated: { [weak self] session in
                self?.sessionStore.save(accessToken: session.accessToken)
                self?.showMain()
            }
        )
        authCoordinator = coordinator
        coordinator.start()
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
