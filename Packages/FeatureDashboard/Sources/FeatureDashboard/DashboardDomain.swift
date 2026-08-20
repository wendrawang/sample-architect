import Foundation

public struct DashboardTransaction: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let amount: Decimal

    public init(id: String, title: String, subtitle: String, amount: Decimal) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
    }
}

public struct DashboardSummary: Equatable, Sendable {
    public let customerName: String
    public let accountNumber: String
    public let availableBalance: Decimal
    public let transactions: [DashboardTransaction]

    public init(
        customerName: String,
        accountNumber: String,
        availableBalance: Decimal,
        transactions: [DashboardTransaction]
    ) {
        self.customerName = customerName
        self.accountNumber = accountNumber
        self.availableBalance = availableBalance
        self.transactions = transactions
    }
}

public protocol DashboardRepositoryProtocol: Sendable {
    func getSummary() async throws -> DashboardSummary
}


/// Apa yang feature ini butuhkan dari luar. Composition root yang memenuhinya.
///
/// Bentuk factory, bukan property, supaya repository baru dibangun ketika layar dibuka —
/// bukan sekaligus di awal untuk layar yang mungkin tidak pernah dibuka.
public protocol DashboardDependencies: Sendable {
    func makeDashboardRepository() -> any DashboardRepositoryProtocol
}
