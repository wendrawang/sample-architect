import Foundation

public protocol SubmitTransferUseCaseProtocol {
    func execute(destinationAccount: String, amountText: String) async throws -> TransferReceipt
}

public final class SubmitTransferUseCase: SubmitTransferUseCaseProtocol {
    private let repository: TransferRepositoryProtocol

    public init(repository: TransferRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(
        destinationAccount: String,
        amountText: String
    ) async throws -> TransferReceipt {
        let account = destinationAccount.filter(\.isNumber)
        guard account.count >= 8 else {
            throw TransferValidationError.invalidAccount
        }

        let normalizedAmount = amountText
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard let amount = Decimal(string: normalizedAmount), amount > 0 else {
            throw TransferValidationError.invalidAmount
        }

        return try await repository.submit(
            destinationAccount: account,
            amount: amount
        )
    }
}

