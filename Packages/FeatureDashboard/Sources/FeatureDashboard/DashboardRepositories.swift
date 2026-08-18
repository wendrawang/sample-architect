import CoreNetwork
import Foundation

private struct DashboardSummaryDTO: Decodable {
    let customerName: String
    let accountNumber: String
    let availableBalance: Decimal
    let transactions: [TransactionDTO]

    struct TransactionDTO: Decodable {
        let id: String
        let title: String
        let subtitle: String
        let amount: Decimal
    }
}

public final class RemoteDashboardRepository: DashboardRepositoryProtocol {
    private let apiClient: any APIClient

    public init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    public func getSummary() async throws -> DashboardSummary {
        let endpoint = Endpoint<DashboardSummaryDTO>(path: "/v1/dashboard/summary")
        let dto = try await apiClient.request(endpoint)
        return DashboardSummary(
            customerName: dto.customerName,
            accountNumber: dto.accountNumber,
            availableBalance: dto.availableBalance,
            transactions: dto.transactions.map {
                DashboardTransaction(
                    id: $0.id,
                    title: $0.title,
                    subtitle: $0.subtitle,
                    amount: $0.amount
                )
            }
        )
    }
}

public final class MockDashboardRepository: DashboardRepositoryProtocol {
    public init() {}

    public func getSummary() async throws -> DashboardSummary {
        try await Task.sleep(nanoseconds: 450_000_000)
        guard !Task.isCancelled else { throw CancellationError() }

        return DashboardSummary(
            customerName: "Wendra",
            accountNumber: "1234 5678 9012",
            availableBalance: 24_850_000,
            transactions: [
                DashboardTransaction(
                    id: "trx-1",
                    title: "Transfer masuk",
                    subtitle: "Hari ini, 09:42",
                    amount: 1_500_000
                ),
                DashboardTransaction(
                    id: "trx-2",
                    title: "Pembayaran QRIS",
                    subtitle: "Kemarin, 19:20",
                    amount: -87_500
                ),
                DashboardTransaction(
                    id: "trx-3",
                    title: "Tagihan Internet",
                    subtitle: "15 Agu 2026",
                    amount: -241_400
                )
            ]
        )
    }
}

