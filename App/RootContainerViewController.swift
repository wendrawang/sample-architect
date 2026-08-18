import CoreGuards
import CoreKit
import SwiftUI
import UIKit

@MainActor
final class RootContainerViewController: UIViewController {
    let navigationController: UINavigationController

    private var blockerController: UIHostingController<RootBlockerView>?
    private var fpsController: UIHostingController<FPSBadgeView>?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        embedNavigationController()
    }

    func setBlocker(
        _ reason: RootBlockerReason?,
        onRetry: @escaping () -> Void
    ) {
        guard let reason else {
            removeBlocker()
            return
        }

        if let blockerController {
            blockerController.rootView = RootBlockerView(reason: reason, onRetry: onRetry)
            return
        }

        let controller = UIHostingController(
            rootView: RootBlockerView(reason: reason, onRetry: onRetry)
        )
        controller.view.backgroundColor = .systemBackground
        addChild(controller)
        view.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        controller.didMove(toParent: self)
        blockerController = controller

        controller.view.alpha = 0
        UIView.animate(withDuration: 0.2) {
            controller.view.alpha = 1
        }
    }

    func showFPS(_ monitor: FrameRateMonitor) {
        guard fpsController == nil else { return }
        let controller = UIHostingController(rootView: FPSBadgeView(monitor: monitor))
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        addChild(controller)
        view.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controller.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            controller.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        ])
        controller.didMove(toParent: self)
        fpsController = controller
    }

    private func embedNavigationController() {
        addChild(navigationController)
        view.addSubview(navigationController.view)
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            navigationController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        navigationController.didMove(toParent: self)
    }

    private func removeBlocker() {
        guard let blockerController else { return }
        self.blockerController = nil

        UIView.animate(
            withDuration: 0.18,
            animations: { blockerController.view.alpha = 0 },
            completion: { _ in
                blockerController.willMove(toParent: nil)
                blockerController.view.removeFromSuperview()
                blockerController.removeFromParent()
            }
        )
    }
}

