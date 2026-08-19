import CoreNavigation
import FeatureTransfer
import SwiftUI

public enum MainRoute: Hashable, Sendable {
    case transfer
}

public struct MainFlowView: View {
    @StateObject private var router = NavigationRouter<MainRoute>()

    private let dependencies: MainDependencies
    private let onLogout: () -> Void

    public init(
        dependencies: MainDependencies,
        onLogout: @escaping () -> Void
    ) {
        self.dependencies = dependencies
        self.onLogout = onLogout
    }

    /// The stack wraps the `TabView`, so a pushed screen covers the tab bar the same way
    /// `hidesBottomBarWhenPushed` used to.
    public var body: some View {
        NavigationStack(path: $router.path) {
            MainTabView(
                dependencies: dependencies,
                onTransfer: { [weak router] in
                    guard let router, router.current != .transfer else { return }
                    router.push(.transfer)
                },
                onLogout: onLogout
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: MainRoute.self) { route in
                destination(for: route)
            }
        }
    }

    @ViewBuilder
    private func destination(for route: MainRoute) -> some View {
        switch route {
        case .transfer:
            TransferScreen(
                repository: dependencies.transferRepository,
                onFinished: { [weak router] in router?.pop() }
            )
            .navigationTitle("Transfer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
