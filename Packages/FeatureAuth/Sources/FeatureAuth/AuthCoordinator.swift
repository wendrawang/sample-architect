import CoreKit
import CoreNavigation
import UIKit

@MainActor
public final class AuthCoordinator: NavigationCoordinator {
    private let repository: AuthRepositoryProtocol
    private let onAuthenticated: (AuthSession) -> Void

    public init(
        navigationController: UINavigationController,
        repository: AuthRepositoryProtocol,
        onAuthenticated: @escaping (AuthSession) -> Void
    ) {
        self.repository = repository
        self.onAuthenticated = onAuthenticated
        super.init(navigationController: navigationController)
    }

    public override func start() {
        showUsername()
    }

    private func showUsername() {
        let viewModel = UsernameViewModel(
            validateUsername: ValidateUsernameUseCase(),
            onContinue: { [weak self] username in
                self?.showPassword(username: username)
            }
        )
        let controller = ScreenHostingController(
            rootView: UsernameView(viewModel: viewModel),
            hidesNavigationBar: true
        )
        navigationController?.setViewControllers([controller], animated: true)
    }

    private func showPassword(username: String) {
        let viewModel = PasswordViewModel(
            username: username,
            loginUseCase: LoginUseCase(repository: repository),
            onAuthenticated: { [weak self] session in
                self?.onAuthenticated(session)
            }
        )
        let controller = ScreenHostingController(
            rootView: PasswordView(viewModel: viewModel),
            title: "Login"
        )
        controller.onPopped = {
            AppLogger.navigation.debug("Password screen popped")
        }
        navigationController?.pushViewController(controller, animated: true)
    }
}

