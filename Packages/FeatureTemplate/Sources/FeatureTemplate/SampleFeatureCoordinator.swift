import CoreNavigation
import UIKit

@MainActor
public final class SampleFeatureCoordinator: NavigationCoordinator {
    private let repository: any SampleFeatureRepositoryProtocol
    private let onFlowFinished: () -> Void
    private var hasFinished = false

    public init(
        navigationController: UINavigationController,
        repository: any SampleFeatureRepositoryProtocol,
        onFlowFinished: @escaping () -> Void = {}
    ) {
        self.repository = repository
        self.onFlowFinished = onFlowFinished
        super.init(navigationController: navigationController)
    }

    public override func start() {
        let viewModel = SampleFeatureViewModel(
            useCase: SampleFeatureUseCase(repository: repository)
        )
        let controller = ScreenHostingController(
            rootView: SampleFeatureView(viewModel: viewModel),
            title: "Sample Feature"
        )
        controller.onPopped = { [weak self] in self?.endFlow() }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func endFlow() {
        guard !hasFinished else { return }
        hasFinished = true
        onFlowFinished()
        finish()
    }
}
