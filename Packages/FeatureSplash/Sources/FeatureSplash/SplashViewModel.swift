import Combine
import CoreKit
import CorePresentation
import Foundation

@MainActor
public final class SplashViewModel: ObservableObject {
    public let presentation = ScreenPresentationStore()

    private let useCase: PrepareLaunchUseCaseProtocol
    private let onFinished: () -> Void
    private let lifecycleProbe = LifecycleProbe("SplashViewModel")
    private var prepareTask: Task<Void, Never>?
    private var hasStarted = false

    public init(
        useCase: PrepareLaunchUseCaseProtocol,
        onFinished: @escaping () -> Void
    ) {
        self.useCase = useCase
        self.onFinished = onFinished
    }

    public func onAppear() {
        guard !hasStarted else { return }
        hasStarted = true
        let useCase = useCase

        prepareTask = Task { [weak self] in
            await useCase.execute()
            guard !Task.isCancelled else { return }
            self?.onFinished()
        }
    }

    deinit {
        prepareTask?.cancel()
    }
}

