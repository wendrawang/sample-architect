import Combine
import CoreKit
import CorePresentation
import Foundation

@MainActor
public final class TransferViewModel: ObservableObject {
    @Published public var destinationAccount = ""
    @Published public var amount = ""
    @Published public private(set) var isLoading = false
    public let presentation = ScreenPresentationStore()

    private let submitTransfer: any SubmitTransferUseCaseProtocol
    private let onFinished: () -> Void
    private let lifecycleProbe = LifecycleProbe("TransferViewModel")
    private var submitTask: Task<Void, Never>?
    private var completionTask: Task<Void, Never>?

    public init(
        submitTransfer: any SubmitTransferUseCaseProtocol,
        onFinished: @escaping () -> Void
    ) {
        self.submitTransfer = submitTransfer
        self.onFinished = onFinished
    }

    public func didTapReview() {
        guard !isLoading else { return }
        presentation.present(
            bottomSheet: BottomSheetModel(
                iconSystemName: "arrow.left.arrow.right.circle.fill",
                title: "Konfirmasi transfer",
                message: "Kirim Rp\(amount.isEmpty ? "0" : amount) ke rekening \(destinationAccount.isEmpty ? "-" : destinationAccount)?",
                actions: [
                    PresentationAction(id: "confirm-transfer", title: "Ya, Transfer"),
                    PresentationAction(id: "cancel-transfer", title: "Periksa Lagi", role: .secondary)
                ]
            )
        )
    }

    public func selectDestinationAccount(_ account: String) {
        destinationAccount = account.replacingOccurrences(of: "•", with: "0")
        presentation.show(
            snackbar: SnackbarModel(
                message: "Penerima dipilih. Masukkan nominal transfer.",
                iconSystemName: "checkmark.circle.fill"
            )
        )
    }

    public func didTapNewRecipient() {
        destinationAccount = ""
        presentation.present(
            bottomSheet: BottomSheetModel(
                iconSystemName: "person.badge.plus",
                title: "Penerima baru",
                message: "Hubungkan action ini ke inquiry bank dan validasi rekening tujuan.",
                actions: [
                    PresentationAction(id: "dismiss", title: "Mengerti")
                ]
            )
        )
    }

    public func handlePresentationAction(_ id: String) {
        switch id {
        case "confirm-transfer":
            submit()
        case "retry-transfer":
            submit()
        default:
            break
        }
    }

    private func submit() {
        guard !isLoading else { return }
        isLoading = true
        let useCase = submitTransfer
        let account = destinationAccount
        let amountText = amount

        submitTask?.cancel()
        submitTask = Task { [weak self] in
            do {
                let receipt = try await useCase.execute(
                    destinationAccount: account,
                    amountText: amountText
                )
                guard !Task.isCancelled else { return }
                self?.showSuccess(receipt)
            } catch is CancellationError {
                self?.isLoading = false
            } catch let error as TransferValidationError {
                self?.showValidationError(error)
            } catch {
                self?.showServiceError(error)
            }
        }
    }

    private func showSuccess(_ receipt: TransferReceipt) {
        isLoading = false
        presentation.show(
            snackbar: SnackbarModel(
                message: "Transfer berhasil • \(receipt.referenceNumber)",
                iconSystemName: "checkmark.circle.fill",
                duration: 1
            )
        )

        completionTask?.cancel()
        completionTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            self?.onFinished()
        }
    }

    private func showValidationError(_ error: TransferValidationError) {
        isLoading = false
        presentation.show(
            snackbar: SnackbarModel(
                message: error.localizedDescription,
                iconSystemName: "exclamationmark.circle.fill"
            )
        )
    }

    private func showServiceError(_ error: Error) {
        isLoading = false
        presentation.present(
            blocker: ScreenBlockerModel(
                title: "Transfer belum berhasil",
                message: error.localizedDescription,
                actions: [
                    PresentationAction(id: "retry-transfer", title: "Coba Lagi"),
                    PresentationAction(id: "dismiss", title: "Tutup", role: .secondary)
                ]
            )
        )
    }

    deinit {
        submitTask?.cancel()
        completionTask?.cancel()
    }
}
