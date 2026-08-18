import CoreNavigation
import UIKit

@MainActor
public final class SampleFeatureCoordinator: NavigationCoordinator {
    public override func start() {
        let viewModel = SampleFeatureViewModel(useCase: SampleFeatureUseCase())
        let controller = ScreenHostingController(
            rootView: SampleFeatureView(viewModel: viewModel),
            title: "Sample Feature"
        )
        controller.onPopped = { [weak self] in self?.finish() }
        navigationController?.pushViewController(controller, animated: true)
    }
}

