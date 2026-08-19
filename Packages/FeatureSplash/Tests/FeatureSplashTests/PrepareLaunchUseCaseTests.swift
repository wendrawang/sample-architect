@testable import FeatureSplash
import XCTest

private struct SplashRepositoryStub: SplashRepositoryProtocol {
    let decision: LaunchDecision

    func inquireLaunchState() async throws -> LaunchDecision {
        decision
    }
}

final class PrepareLaunchUseCaseTests: XCTestCase {
    func testReturnsRepositoryDecision() async throws {
        let expected = LaunchDecision(destination: .maintenance, message: "Maintenance")
        let useCase = PrepareLaunchUseCase(
            repository: SplashRepositoryStub(decision: expected),
            minimumDisplayNanoseconds: 0
        )

        let result = try await useCase.execute()

        XCTAssertEqual(result, expected)
    }
}
