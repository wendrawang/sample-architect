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

    private let loginUseCase: any LoginUseCaseProtocol
    private let onAuthenticated: (AuthSession) -> Void
    private let lifecycleProbe = LifecycleProbe("PasswordViewModel")
    /// Internal, bukan private, supaya test dapat menunggu pekerjaan yang sedang berjalan
    /// lewat `@testable import`. Tetap tidak terlihat dari luar modul.
    private(set) var loginTask: Task<Void, Never>?

    public init(
        username: String,
        loginUseCase: any LoginUseCaseProtocol,
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

    public func didTapForgotPassword() {
        presentation.present(
            bottomSheet: BottomSheetModel(
                iconSystemName: "key.fill",
                title: AuthStrings.passwordHelpTitle,
                message: AuthStrings.passwordHelpMessage,
                actions: [
                    PresentationAction(id: "reset-password", title: AuthStrings.passwordHelpReset),
                    PresentationAction(id: "dismiss", title: AuthStrings.passwordHelpLater, role: .secondary)
                ]
            )
        )
    }

    public func didTapBiometric() {
        presentation.show(
            snackbar: SnackbarModel(
                message: AuthStrings.passwordBiometricHint,
                iconSystemName: "faceid"
            )
        )
    }

    private func finishLogin(with session: AuthSession) {
        isLoading = false
        onAuthenticated(session)
    }

    private func showLoginError(_ error: Error) {
        isLoading = false
        presentation.present(
            blocker: ScreenBlockerModel(
                title: AuthStrings.passwordErrorTitle,
                message: error.localizedDescription,
                actions: [
                    PresentationAction(id: "retry", title: AuthStrings.passwordErrorRetry),
                    PresentationAction(id: "dismiss", title: AuthStrings.passwordErrorDismiss, role: .secondary)
                ]
            )
        )
    }

    deinit {
        loginTask?.cancel()
    }
}
