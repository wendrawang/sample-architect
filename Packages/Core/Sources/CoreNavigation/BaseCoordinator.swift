import CoreKit
import Foundation
import UIKit

@MainActor
open class BaseCoordinator: NSObject {
    public private(set) weak var parentCoordinator: BaseCoordinator?
    private var childCoordinators: [ObjectIdentifier: BaseCoordinator] = [:]
    private var isFinished = false
    private let lifecycleProbe: LifecycleProbe

    public override init() {
        lifecycleProbe = LifecycleProbe(String(describing: Self.self))
        super.init()
    }

    open func start() {}

    open func stop() {
        let children = Array(childCoordinators.values)
        childCoordinators.removeAll()

        children.forEach { child in
            child.parentCoordinator = nil
            child.stop()
        }
    }

    public final func attach(_ child: BaseCoordinator) {
        child.parentCoordinator = self
        childCoordinators[ObjectIdentifier(child)] = child
    }

    public final func release(_ child: BaseCoordinator) {
        child.parentCoordinator = nil
        childCoordinators.removeValue(forKey: ObjectIdentifier(child))
    }

    public final func finish() {
        guard !isFinished else { return }
        isFinished = true

        let parent = parentCoordinator
        stop()
        parent?.release(self)
        LeakWatchdog.expectDeallocation(of: self, named: String(describing: Self.self))
    }
}

@MainActor
open class NavigationCoordinator: BaseCoordinator {
    public weak var navigationController: UINavigationController?

    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }
}

