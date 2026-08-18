import Foundation

public struct TransferReceipt: Equatable {
    public let referenceNumber: String
    public let amount: Decimal

    public init(referenceNumber: String, amount: Decimal) {
        self.referenceNumber = referenceNumber
        self.amount = amount
    }
}

public protocol TransferRepositoryProtocol {
    func submit(destinationAccount: String, amount: Decimal) async throws -> TransferReceipt
}

public enum TransferValidationError: Error, LocalizedError, Equatable {
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

