import Foundation

public struct AuthSession: Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiration: Date?
    public let userDisplayName: String

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        expiration: Date? = nil,
        userDisplayName: String
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
        self.userDisplayName = userDisplayName
    }
}

public protocol AuthRepositoryProtocol: Sendable {
    func login(username: String, password: String) async throws -> AuthSession
}

public enum AuthValidationError: Error, LocalizedError, Equatable, Sendable {
    case usernameTooShort
    case passwordTooShort

    public var errorDescription: String? {
        switch self {
        case .usernameTooShort:
            return AuthStrings.errorUsernameTooShort
        case .passwordTooShort:
            return AuthStrings.errorPasswordTooShort
        }
    }
}


/// Apa yang feature ini butuhkan dari luar. Composition root yang memenuhinya.
///
/// Bentuk factory, bukan property, supaya repository baru dibangun ketika layar dibuka —
/// bukan sekaligus di awal untuk layar yang mungkin tidak pernah dibuka.
public protocol AuthDependencies: Sendable {
    func makeAuthRepository() -> any AuthRepositoryProtocol
}
