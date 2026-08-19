import Combine
import CoreKit
import CorePresentation
import Foundation

@MainActor
public final class SampleFeatureViewModel: ObservableObject {
    @Published public private(set) var content: SampleFeatureContent?
    @Published public private(set) var isLoading = false
    public let presentation = ScreenPresentationStore()

    private let useCase: any SampleFeatureUseCaseProtocol
    private let lifecycleProbe = LifecycleProbe("SampleFeatureViewModel")
    private var task: Task<Void, Never>?

    public init(useCase: any SampleFeatureUseCaseProtocol) {
        self.useCase = useCase
    }

    public func onAppear() {
        guard content == nil, task == nil else { return }
        load()
    }

    public func didTapInfo() {
        presentation.present(
            bottomSheet: BottomSheetModel(
                iconSystemName: "info.circle.fill",
                title: "Custom action",
                message: "Gunakan action ID untuk meneruskan intent ke ViewModel.",
                actions: [PresentationAction(id: "acknowledge", title: "Mengerti")]
            )
        )
    }

    public func handlePresentationAction(_ id: String) {
        switch id {
        case "retry":
            presentation.dismissBlocker()
            load()
        case "acknowledge":
            presentation.show(
                snackbar: SnackbarModel(
                    message: "Custom action diterima.",
                    iconSystemName: "checkmark.circle.fill"
                )
            )
        default:
            break
        }
    }

    private func load() {
        guard task == nil else { return }
        isLoading = true
        let useCase = useCase

        task = Task { [weak self] in
            do {
                let result = try await useCase.execute()
                guard !Task.isCancelled else { return }
                self?.apply(result)
            } catch is CancellationError {
                self?.finishLoading()
            } catch {
                self?.show(error)
            }
        }
    }

    private func apply(_ content: SampleFeatureContent) {
        finishLoading()
        self.content = content
    }

    private func show(_ error: Error) {
        finishLoading()
        presentation.present(
            blocker: ScreenBlockerModel(
                title: "Data gagal dimuat",
                message: error.localizedDescription,
                actions: [PresentationAction(id: "retry", title: "Coba Lagi")]
            )
        )
    }

    private func finishLoading() {
        isLoading = false
        task = nil
    }

    deinit {
        task?.cancel()
    }
}
