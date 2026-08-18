import Combine
import CoreKit
import CorePresentation
import Foundation

@MainActor
public final class SampleFeatureViewModel: ObservableObject {
    @Published public private(set) var value = ""
    public let presentation = ScreenPresentationStore()

    private let useCase: SampleFeatureUseCaseProtocol
    private let lifecycleProbe = LifecycleProbe("SampleFeatureViewModel")
    private var task: Task<Void, Never>?

    public init(useCase: SampleFeatureUseCaseProtocol) {
        self.useCase = useCase
    }

    public func onAppear() {
        guard task == nil else { return }
        let useCase = useCase

        task = Task { [weak self] in
            do {
                let result = try await useCase.execute()
                guard !Task.isCancelled else { return }
                self?.value = result
            } catch {
                self?.presentation.present(
                    blocker: ScreenBlockerModel(
                        title: "Data gagal dimuat",
                        message: error.localizedDescription,
                        actions: [PresentationAction(id: "retry", title: "Coba Lagi")]
                    )
                )
            }
        }
    }

    public func handlePresentationAction(_ id: String) {
        guard id == "retry" else { return }
        task = nil
        onAppear()
    }

    deinit {
        task?.cancel()
    }
}

