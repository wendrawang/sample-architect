import Foundation

public protocol SampleFeatureUseCaseProtocol: Sendable {
    func execute() async throws -> SampleFeatureContent
}

public struct SampleFeatureUseCase: SampleFeatureUseCaseProtocol {
    private let repository: any SampleFeatureRepositoryProtocol

    public init(repository: any SampleFeatureRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> SampleFeatureContent {
        let content = try await repository.loadContent()
        guard !content.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SampleFeatureError.emptyContent
        }
        return content
    }
}
