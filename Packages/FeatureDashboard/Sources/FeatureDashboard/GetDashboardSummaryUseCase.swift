import Foundation

public protocol GetDashboardSummaryUseCaseProtocol {
    func execute() async throws -> DashboardSummary
}

public final class GetDashboardSummaryUseCase: GetDashboardSummaryUseCaseProtocol {
    private let repository: DashboardRepositoryProtocol

    public init(repository: DashboardRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> DashboardSummary {
        try await repository.getSummary()
    }
}

