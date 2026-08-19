import Combine
import CoreKit
import CorePresentation
import Foundation

@MainActor
public final class SplashViewModel: ObservableObject {
    @Published public private(set) var isLoading = false
    public let presentation = ScreenPresentationStore()

    private let useCase: any PrepareLaunchUseCaseProtocol
    private let onRoute: (LaunchDestination) -> Void
    private let onUpdateRequested: () -> Void
    private let lifecycleProbe = LifecycleProbe("SplashViewModel")
    private var prepareTask: Task<Void, Never>?
    private var hasCompleted = false

    public init(
        useCase: any PrepareLaunchUseCaseProtocol,
        onRoute: @escaping (LaunchDestination) -> Void,
        onUpdateRequested: @escaping () -> Void = {}
    ) {
        self.useCase = useCase
        self.onRoute = onRoute
        self.onUpdateRequested = onUpdateRequested
    }

    public func onAppear() {
        startIfNeeded()
    }

    public func handlePresentationAction(_ id: String) {
        switch id {
        case "retry-splash":
            presentation.dismissBlocker()
            startIfNeeded()
        case "update-app":
            onUpdateRequested()
        default:
            break
        }
    }

    private func startIfNeeded() {
        guard prepareTask == nil, !hasCompleted else { return }
        isLoading = true
        let useCase = useCase

        prepareTask = Task { [weak self] in
            do {
                let decision = try await useCase.execute()
                guard !Task.isCancelled else { return }
                self?.handle(decision)
            } catch is CancellationError {
                self?.finishCurrentAttempt()
            } catch {
                self?.show(error: error)
            }
        }
    }

    private func handle(_ decision: LaunchDecision) {
        finishCurrentAttempt()

        switch decision.destination {
        case .preLogin, .main:
            hasCompleted = true
            onRoute(decision.destination)
        case .maintenance:
            presentation.present(
                blocker: ScreenBlockerModel(
                    iconSystemName: "wrench.and.screwdriver.fill",
                    title: "Layanan sedang dipelihara",
                    message: decision.message ?? "Silakan coba kembali beberapa saat lagi.",
                    actions: [
                        PresentationAction(id: "retry-splash", title: "Coba Lagi")
                    ]
                )
            )
        case .forceUpdate:
            presentation.present(
                blocker: ScreenBlockerModel(
                    iconSystemName: "arrow.down.app.fill",
                    title: "Pembaruan diperlukan",
                    message: decision.message ?? "Perbarui aplikasi untuk melanjutkan.",
                    actions: [
                        PresentationAction(
                            id: "update-app",
                            title: "Perbarui Sekarang",
                            dismissesOnTap: false
                        )
                    ]
                )
            )
        }
    }

    private func show(error: Error) {
        finishCurrentAttempt()
        presentation.present(
            blocker: ScreenBlockerModel(
                title: "Aplikasi belum dapat disiapkan",
                message: error.localizedDescription,
                actions: [
                    PresentationAction(id: "retry-splash", title: "Coba Lagi")
                ]
            )
        )
    }

    private func finishCurrentAttempt() {
        isLoading = false
        prepareTask = nil
    }

    deinit {
        prepareTask?.cancel()
    }
}
