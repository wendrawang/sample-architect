import CoreGuards
import DesignSystem
import FeatureAuth
import FeatureMain
import FeatureSplash
import SwiftUI

/// The single root view. It swaps whole flows, paints the global blocker above them, and
/// owns nothing else — every flow builds and releases its own router and ViewModels.
struct AppRootView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        ZStack {
            content

            if let reason = coordinator.rootState.blocker {
                RootBlockerView(reason: reason, onRetry: coordinator.retryRootGuard)
                    .transition(.opacity)
                    .zIndex(10)
            }

            if let monitor = coordinator.fpsMonitor {
                FPSBadgeView(monitor: monitor)
                    .padding(.trailing, AppSpacing.xs)
                    .padding(.top, AppSpacing.xs)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .allowsHitTesting(false)
                    .zIndex(20)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: coordinator.rootState.blocker)
    }

    /// Each `case` is its own branch identity, so switching content tears the previous flow
    /// down completely instead of reusing it.
    @ViewBuilder
    private var content: some View {
        switch coordinator.rootState.content {
        case .launching:
            AppColor.background.ignoresSafeArea()

        case .splash:
            SplashScreen(
                dependencies: coordinator.dependencies,
                onRoute: coordinator.handleLaunchDestination,
                onUpdateRequested: coordinator.openAppStore
            )

        case .preLogin:
            AuthFlowView(
                dependencies: coordinator.dependencies,
                onAuthenticated: coordinator.handleAuthenticated
            )

        case .main:
            MainFlowView(
                dependencies: coordinator.dependencies,
                onLogout: coordinator.handleLogout
            )
        }
    }
}
