import CoreNetwork
import Foundation

private struct LoginRequestDTO: Encodable {
    let username: String
    let password: String
}

private struct LoginResponseDTO: Decodable {
    let accessToken: String
    let displayName: String
}

public final class RemoteAuthRepository: AuthRepositoryProtocol {
    private let apiClient: any APIClient

    public init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    public func login(username: String, password: String) async throws -> AuthSession {
        let request = LoginRequestDTO(username: username, password: password)
        let endpoint = Endpoint<LoginResponseDTO>(
            path: "/v1/auth/login",
            method: .post,
            body: AnyEncodable(request)
        )
        let response = try await apiClient.request(endpoint)
        return AuthSession(
            accessToken: response.accessToken,
            userDisplayName: response.displayName
        )
    }
}

public final class MockAuthRepository: AuthRepositoryProtocol {
    public init() {}

    public func login(username: String, password: String) async throws -> AuthSession {
        try await Task.sleep(nanoseconds: 650_000_000)
        guard !Task.isCancelled else { throw CancellationError() }
        return AuthSession(
            accessToken: "mock-access-token",
            userDisplayName: username.capitalized
        )
    }
}

