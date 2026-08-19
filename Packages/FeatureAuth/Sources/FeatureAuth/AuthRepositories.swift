import CoreNetwork
import Foundation

private struct LoginRequestDTO: Encodable, Sendable {
    let username: String
    let password: String
}

private struct LoginResponseDTO: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: TimeInterval?
    let displayName: String
}

public final class RemoteAuthRepository: AuthRepositoryProtocol, @unchecked Sendable {
    private let apiClient: any APIClient

    public init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    public func login(username: String, password: String) async throws -> AuthSession {
        let request = LoginRequestDTO(username: username, password: password)
        let endpoint = Endpoint<LoginResponseDTO>(
            path: "/v1/auth/login",
            method: .post,
            body: AnyEncodable(request),
            authorization: .none,
            signature: .ifAvailable
        )
        let response = try await apiClient.request(endpoint)
        return AuthSession(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiration: response.expiresIn.map { Date().addingTimeInterval($0) },
            userDisplayName: response.displayName
        )
    }
}

public final class MockAuthRepository: AuthRepositoryProtocol, @unchecked Sendable {
    public init() {}

    public func login(username: String, password: String) async throws -> AuthSession {
        try await Task.sleep(nanoseconds: 650_000_000)
        guard !Task.isCancelled else { throw CancellationError() }
        return AuthSession(
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token",
            expiration: Date().addingTimeInterval(3_600),
            userDisplayName: username.capitalized
        )
    }
}
