import CoreNetwork
import Foundation

private struct SubmitTransferRequestDTO: Encodable, Sendable {
    let destinationAccount: String
    let amount: Decimal
}

private struct TransferReceiptDTO: Decodable, Sendable {
    let referenceNumber: String
    let amount: Decimal
}

public final class RemoteTransferRepository: TransferRepositoryProtocol, @unchecked Sendable {
    private let apiClient: any APIClient

    public init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    public func submit(
        destinationAccount: String,
        amount: Decimal
    ) async throws -> TransferReceipt {
        let endpoint = Endpoint<TransferReceiptDTO>(
            path: "/v1/transfers",
            method: .post,
            body: AnyEncodable(
                SubmitTransferRequestDTO(
                    destinationAccount: destinationAccount,
                    amount: amount
                )
            ),
            authorization: .bearer,
            signature: .required
        )
        let dto = try await apiClient.request(endpoint)
        return TransferReceipt(referenceNumber: dto.referenceNumber, amount: dto.amount)
    }
}

public final class MockTransferRepository: TransferRepositoryProtocol, @unchecked Sendable {
    public init() {}

    public func submit(
        destinationAccount: String,
        amount: Decimal
    ) async throws -> TransferReceipt {
        try await Task.sleep(nanoseconds: 700_000_000)
        guard !Task.isCancelled else { throw CancellationError() }
        return TransferReceipt(
            referenceNumber: "TRF-\(Int(Date().timeIntervalSince1970))",
            amount: amount
        )
    }
}
