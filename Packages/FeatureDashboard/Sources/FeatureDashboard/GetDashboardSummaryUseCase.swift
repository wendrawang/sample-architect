import Foundation

public protocol GetDashboardSummaryUseCaseProtocol: Sendable {
    func execute() async throws -> DashboardSummary
}

public final class GetDashboardSummaryUseCase: GetDashboardSummaryUseCaseProtocol {
    private let repository: any DashboardRepositoryProtocol

    public init(repository: any DashboardRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> DashboardSummary {
        try await repository.getSummary()
    }
}
