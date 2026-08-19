import CoreNavigation
import UIKit

@MainActor
public final class TransferCoordinator: NavigationCoordinator {
    private let repository: any TransferRepositoryProtocol
    private let onFlowFinished: () -> Void
    private var didFinishFlow = false

    public init(
        navigationController: UINavigationController,
        repository: any TransferRepositoryProtocol,
        onFlowFinished: @escaping () -> Void = {}
    ) {
        self.repository = repository
        self.onFlowFinished = onFlowFinished
        super.init(navigationController: navigationController)
    }

    public override func start() {
        let viewModel = TransferViewModel(
            submitTransfer: SubmitTransferUseCase(repository: repository),
            onFinished: { [weak self] in
                self?.completeFlow()
            }
        )
        let controller = ScreenHostingController(
            rootView: TransferView(viewModel: viewModel),
            title: "Transfer"
        )
        controller.hidesBottomBarWhenPushed = true
        controller.onPopped = { [weak self] in
            self?.endFlow()
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func completeFlow() {
        navigationController?.popViewController(animated: true)
        endFlow()
    }

    private func endFlow() {
        guard !didFinishFlow else { return }
        didFinishFlow = true
        onFlowFinished()
        finish()
    }
}
