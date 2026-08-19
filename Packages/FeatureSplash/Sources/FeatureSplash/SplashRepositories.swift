import CoreNetwork
import Foundation

private struct SplashInquiryDTO: Decodable, Sendable {
    let nextRoute: String?
    let isMaintenance: Bool?
    let forceUpdate: Bool?
    let isAuthenticated: Bool?
    let message: String?
}

public final class RemoteSplashRepository: SplashRepositoryProtocol, @unchecked Sendable {
    private let apiClient: any APIClient
    private let path: String

    public init(
        apiClient: any APIClient,
        path: String = "/v1/app/bootstrap"
    ) {
        self.apiClient = apiClient
        self.path = path
    }

    public func inquireLaunchState() async throws -> LaunchDecision {
        let endpoint = Endpoint<SplashInquiryDTO>(
            path: path,
            method: .get,
            authorization: .bearerIfAvailable,
            signature: .ifAvailable
        )
        let response = try await apiClient.request(endpoint)

        if response.forceUpdate == true {
            return LaunchDecision(destination: .forceUpdate, message: response.message)
        }
        if response.isMaintenance == true {
            return LaunchDecision(destination: .maintenance, message: response.message)
        }
        if response.isAuthenticated == true || response.nextRoute == "main" {
            return LaunchDecision(destination: .main)
        }
        return LaunchDecision(destination: .preLogin)
    }
}

public final class MockSplashRepository: SplashRepositoryProtocol, @unchecked Sendable {
    private let decision: LaunchDecision
    private let shouldFail: Bool
    private let delayNanoseconds: UInt64

    public init(
        decision: LaunchDecision = LaunchDecision(destination: .preLogin),
        shouldFail: Bool = false,
        delayNanoseconds: UInt64 = 250_000_000
    ) {
        self.decision = decision
        self.shouldFail = shouldFail
        self.delayNanoseconds = delayNanoseconds
    }

    public func inquireLaunchState() async throws -> LaunchDecision {
        try await Task.sleep(nanoseconds: delayNanoseconds)
        try Task.checkCancellation()
        if shouldFail {
            throw MockSplashError.simulated
        }
        return decision
    }
}
