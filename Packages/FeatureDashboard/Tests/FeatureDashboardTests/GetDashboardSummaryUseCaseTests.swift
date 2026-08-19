import FeatureDashboard
import XCTest

private final class DashboardRepositorySpy: DashboardRepositoryProtocol, @unchecked Sendable {
    private(set) var callCount = 0

    func getSummary() async throws -> DashboardSummary {
        callCount += 1
        return DashboardSummary(
            customerName: "Test",
            accountNumber: "1",
            availableBalance: 100,
            transactions: []
        )
    }
}

final class GetDashboardSummaryUseCaseTests: XCTestCase {
    func testExecuteDelegatesToRepository() async throws {
        let repository = DashboardRepositorySpy()
        let sut = GetDashboardSummaryUseCase(repository: repository)

        let result = try await sut.execute()

        XCTAssertEqual(result.customerName, "Test")
        XCTAssertEqual(repository.callCount, 1)
    }
}
