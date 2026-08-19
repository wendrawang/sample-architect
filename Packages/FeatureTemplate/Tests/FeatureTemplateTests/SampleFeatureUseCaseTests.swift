@testable import FeatureTemplate
import XCTest

private struct RepositoryStub: SampleFeatureRepositoryProtocol {
    let content: SampleFeatureContent

    func loadContent() async throws -> SampleFeatureContent {
        content
    }
}

final class SampleFeatureUseCaseTests: XCTestCase {
    func testReturnsValidatedContent() async throws {
        let expected = SampleFeatureContent(title: "Title", message: "Message")
        let useCase = SampleFeatureUseCase(
            repository: RepositoryStub(content: expected)
        )

        let result = try await useCase.execute()

        XCTAssertEqual(result, expected)
    }
}
