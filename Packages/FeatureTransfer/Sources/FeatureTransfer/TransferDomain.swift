import Foundation

public struct TransferReceipt: Equatable, Sendable {
    public let referenceNumber: String
    public let amount: Decimal

    public init(referenceNumber: String, amount: Decimal) {
        self.referenceNumber = referenceNumber
        self.amount = amount
    }
}

public protocol TransferRepositoryProtocol: Sendable {
    func submit(destinationAccount: String, amount: Decimal) async throws -> TransferReceipt
}

public enum TransferValidationError: Error, LocalizedError, Equatable, Sendable {
    case invalidAccount
    case invalidAmount

    public var errorDescription: String? {
        switch self {
        case .invalidAccount:
            return "Nomor rekening minimal 8 digit."
        case .invalidAmount:
            return "Nominal transfer harus lebih dari Rp0."
        }
    }
}
