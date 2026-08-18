import Foundation

public struct AuthSession: Equatable {
    public let accessToken: String
    public let userDisplayName: String

    public init(accessToken: String, userDisplayName: String) {
        self.accessToken = accessToken
        self.userDisplayName = userDisplayName
    }
}

public protocol AuthRepositoryProtocol {
    func login(username: String, password: String) async throws -> AuthSession
}

public enum AuthValidationError: Error, LocalizedError, Equatable {
    case usernameTooShort
    case passwordTooShort

    public var errorDescription: String? {
        switch self {
        case .usernameTooShort:
            return "Username minimal 3 karakter."
        case .passwordTooShort:
            return "Password minimal 6 karakter."
        }
    }
}

