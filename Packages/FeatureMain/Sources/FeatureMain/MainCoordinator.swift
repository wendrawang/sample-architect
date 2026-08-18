import CoreNavigation
import FeatureTransfer
import UIKit

@MainActor
public final class MainCoordinator: NavigationCoordinator {
    private let dependencies: MainDependencies
    private let onLogout: () -> Void
    private var activeTransferCoordinator: TransferCoordinator?

    public init(
        navigationController: UINavigationController,
        dependencies: MainDependencies,
        onLogout: @escaping () -> Void
    ) {
        self.dependencies = dependencies
        self.onLogout = onLogout
        super.init(navigationController: navigationController)
    }

    public override func start() {
        let view = MainTabView(
            dependencies: dependencies,
            onTransfer: { [weak self] in
                self?.showTransfer()
            },
            onLogout: { [weak self] in
                self?.handleLogout()
            }
        )
        let controller = ScreenHostingController(
            rootView: view,
            hidesNavigationBar: true
        )
        navigationController?.setViewControllers([controller], animated: true)
    }

    public override func stop() {
        activeTransferCoordinator = nil
        super.stop()
    }

    private func showTransfer() {
        guard activeTransferCoordinator == nil,
              let navigationController else { return }

        let coordinator = TransferCoordinator(
            navigationController: navigationController,
            repository: dependencies.transferRepository,
            onFlowFinished: { [weak self] in
                self?.activeTransferCoordinator = nil
            }
        )
        activeTransferCoordinator = coordinator
        attach(coordinator)
        coordinator.start()
    }

    private func handleLogout() {
        stop()
        onLogout()
    }
}

