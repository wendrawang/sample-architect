import Combine
import CoreKit
import CorePresentation
import Foundation

@MainActor
public final class PasswordViewModel: ObservableObject {
    @Published public var password = ""
    @Published public private(set) var isLoading = false
    public let presentation = ScreenPresentationStore()
    public let username: String

    private let loginUseCase: LoginUseCaseProtocol
    private let onAuthenticated: (AuthSession) -> Void
    private let lifecycleProbe = LifecycleProbe("PasswordViewModel")
    private var loginTask: Task<Void, Never>?

    public init(
        username: String,
        loginUseCase: LoginUseCaseProtocol,
        onAuthenticated: @escaping (AuthSession) -> Void
    ) {
        self.username = username
        self.loginUseCase = loginUseCase
        self.onAuthenticated = onAuthenticated
    }

    public func didTapLogin() {
        guard !isLoading else { return }
        isLoading = true

        let useCase = loginUseCase
        let username = username
        let password = password

        loginTask?.cancel()
        loginTask = Task { [weak self] in
            do {
                let session = try await useCase.execute(username: username, password: password)
                guard !Task.isCancelled else { return }
                self?.finishLogin(with: session)
            } catch is CancellationError {
                self?.isLoading = false
            } catch {
                self?.showLoginError(error)
            }
        }
    }

    public func handlePresentationAction(_ id: String) {
        switch id {
        case "retry":
            didTapLogin()
        case "dismiss":
            presentation.dismissBlocker()
        default:
            break
        }
    }

    private func finishLogin(with session: AuthSession) {
        isLoading = false
        onAuthenticated(session)
    }

    private func showLoginError(_ error: Error) {
        isLoading = false
        presentation.present(
            blocker: ScreenBlockerModel(
                title: "Login belum berhasil",
                message: error.localizedDescription,
                actions: [
                    PresentationAction(id: "retry", title: "Coba Lagi"),
                    PresentationAction(id: "dismiss", title: "Tutup", role: .secondary)
                ]
            )
        )
    }

    deinit {
        loginTask?.cancel()
    }
}

