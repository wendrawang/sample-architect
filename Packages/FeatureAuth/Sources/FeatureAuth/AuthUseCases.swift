import Foundation

public protocol ValidateUsernameUseCaseProtocol: Sendable {
    func execute(_ username: String) throws -> String
}

public struct ValidateUsernameUseCase: ValidateUsernameUseCaseProtocol {
    public init() {}

    public func execute(_ username: String) throws -> String {
        let normalized = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count >= 3 else {
            throw AuthValidationError.usernameTooShort
        }
        return normalized
    }
}

public protocol LoginUseCaseProtocol: Sendable {
    func execute(username: String, password: String) async throws -> AuthSession
}

public final class LoginUseCase: LoginUseCaseProtocol {
    private let repository: any AuthRepositoryProtocol

    public init(repository: any AuthRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(username: String, password: String) async throws -> AuthSession {
        guard password.count >= 6 else {
            throw AuthValidationError.passwordTooShort
        }
        return try await repository.login(username: username, password: password)
    }
}
