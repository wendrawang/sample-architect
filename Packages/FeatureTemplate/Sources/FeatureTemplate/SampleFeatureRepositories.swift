import CoreNetwork
import Foundation

private struct SampleFeatureDTO: Decodable, Sendable {
    let title: String
    let message: String
}

public final class RemoteSampleFeatureRepository: SampleFeatureRepositoryProtocol, @unchecked Sendable {
    private let apiClient: any APIClient

    public init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    public func loadContent() async throws -> SampleFeatureContent {
        let dto = try await apiClient.request(
            Endpoint<SampleFeatureDTO>(
                path: "/v1/sample-feature",
                authorization: .bearer,
                signature: .required
            )
        )
        return SampleFeatureContent(title: dto.title, message: dto.message)
    }
}

public struct MockSampleFeatureRepository: SampleFeatureRepositoryProtocol {
    public init() {}

    public func loadContent() async throws -> SampleFeatureContent {
        try await Task.sleep(nanoseconds: 250_000_000)
        try Task.checkCancellation()
        return SampleFeatureContent(
            title: "Feature siap dikembangkan",
            message: "Ganti repository, domain, UseCase, dan UI sesuai flow baru."
        )
    }
}
