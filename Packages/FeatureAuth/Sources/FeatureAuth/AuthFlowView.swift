import CoreNavigation
import SwiftUI

/// Every destination this flow can reach, as a value type. Routes carry the data a screen
/// needs to be rebuilt from scratch — never the screen or its ViewModel.
public enum AuthRoute: Hashable, Sendable {
    case password(username: String)
}

public struct AuthFlowView: View {
    @StateObject private var router = NavigationRouter<AuthRoute>(rootScreen: "auth.username")

    private let dependencies: any AuthDependencies
    private let onAuthenticated: (AuthSession) -> Void

    public init(
        dependencies: any AuthDependencies,
        onAuthenticated: @escaping (AuthSession) -> Void
    ) {
        self.dependencies = dependencies
        self.onAuthenticated = onAuthenticated
    }

    public var body: some View {
        NavigationStack(path: $router.path) {
            UsernameScreen(router: router)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AuthRoute.self) { route in
                    destination(for: route)
                }
        }
    }

    /// Attached once to the stack root, never inside a row or a lazy container — SwiftUI
    /// would otherwise register one destination table per row.
    @ViewBuilder
    private func destination(for route: AuthRoute) -> some View {
        switch route {
        case .password(let username):
            PasswordScreen(
                username: username,
                dependencies: dependencies,
                onAuthenticated: onAuthenticated
            )
            .navigationTitle(AuthStrings.passwordNavigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
