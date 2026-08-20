import Combine
import CoreKit
import CorePresentation
import Foundation

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public private(set) var summary: DashboardSummary?
    @Published public private(set) var isLoading = false
    public let presentation = ScreenPresentationStore()

    /// ViewModel menyatakan "pengguna ingin transfer" tanpa tahu itu route apa, di stack
    /// mana, atau layar apa yang akan dibangun. Flow view yang menerjemahkannya.
    public let transferRequested = PassthroughSubject<Void, Never>()

    private let getSummary: any GetDashboardSummaryUseCaseProtocol
    private let lifecycleProbe = LifecycleProbe("DashboardViewModel")
    private var loadTask: Task<Void, Never>?
    private var hasLoaded = false

    public init(getSummary: any GetDashboardSummaryUseCaseProtocol) {
        self.getSummary = getSummary
    }

    public func onAppear() {
        guard !hasLoaded else { return }
        hasLoaded = true
        load()
    }

    public func refresh() async {
        let useCase = getSummary
        do {
            let value = try await useCase.execute()
            guard !Task.isCancelled else { return }
            summary = value
        } catch is CancellationError {
            return
        } catch {
            showLoadError(error)
        }
    }

    public func didTapTransfer() {
        transferRequested.send()
    }

    public func didTapBalanceInfo() {
        presentation.present(
            bottomSheet: BottomSheetModel(
                iconSystemName: "info.circle.fill",
                title: "Saldo tersedia",
                message: "Saldo yang dapat digunakan saat ini, di luar dana yang sedang ditahan.",
                actions: [
                    PresentationAction(id: "understood", title: "Mengerti")
                ]
            )
        )
    }

    public func handlePresentationAction(_ id: String) {
        guard id == "retry-dashboard" else { return }
        load()
    }

    private func load() {
        guard !isLoading else { return }
        isLoading = true
        let useCase = getSummary

        loadTask?.cancel()
        loadTask = Task { [weak self] in
            do {
                let value = try await useCase.execute()
                guard !Task.isCancelled else { return }
                self?.apply(summary: value)
            } catch is CancellationError {
                self?.isLoading = false
            } catch {
                self?.showLoadError(error)
            }
        }
    }

    private func apply(summary: DashboardSummary) {
        isLoading = false
        self.summary = summary
    }

    private func showLoadError(_ error: Error) {
        isLoading = false
        presentation.present(
            blocker: ScreenBlockerModel(
                title: "Dashboard tidak dapat dimuat",
                message: error.localizedDescription,
                actions: [
                    PresentationAction(id: "retry-dashboard", title: "Coba Lagi")
                ]
            )
        )
    }

    deinit {
        loadTask?.cancel()
    }
}
