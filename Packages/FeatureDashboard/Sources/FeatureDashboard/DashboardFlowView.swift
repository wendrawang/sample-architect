import CoreNavigation
import SwiftUI

/// Tujuan yang bisa dicapai dari tab Beranda. Dimiliki oleh package ini, bukan oleh
/// FeatureMain — menambah tujuan baru di sini tidak menyentuh package mana pun.
public enum DashboardRoute: Hashable, Sendable {
    case transfer
}

extension DashboardRoute {
    /// Memetakan sisa segmen URL menjadi path. Dimiliki package ini, bukan registry pusat,
    /// jadi menambah deep link baru di Beranda tidak menyentuh package lain.
    ///
    /// Segmen yang tidak dikenali menghasilkan path kosong — layar tetap terbuka di root,
    /// bukan crash atau layar kosong.
    public static func path(for link: DeepLink) -> [DashboardRoute] {
        switch link.root {
        case "transfer": return [.transfer]
        default:         return []
        }
    }
}

/// Satu `NavigationStack` milik tab Beranda sendiri.
///
/// Layar tujuan dibangun oleh composition root lewat `destination`, sehingga package ini
/// tidak perlu mengimpor package tujuan. `@ViewBuilder` membuat `switch` di sisi pemanggil
/// menghasilkan satu tipe konkret, jadi `AnyView` tetap tidak diperlukan dan `switch`-nya
/// tetap exhaustive.
public struct DashboardFlowView<Destination: View>: View {
    @StateObject private var router: NavigationRouter<DashboardRoute>
    @ObservedObject private var viewModel: DashboardViewModel

    private let destination: (DashboardRoute) -> Destination

    public init(
        viewModel: DashboardViewModel,
        initialPath: [DashboardRoute] = [],
        @ViewBuilder destination: @escaping (DashboardRoute) -> Destination
    ) {
        _router = StateObject(
            wrappedValue: NavigationRouter(rootScreen: "dashboard", initialPath: initialPath)
        )
        self.viewModel = viewModel
        self.destination = destination
    }

    public var body: some View {
        NavigationStack(path: $router.path) {
            DashboardView(viewModel: viewModel)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: DashboardRoute.self, destination: destination)
        }
        .onReceive(viewModel.transferRequested) { _ in
            guard router.current != .transfer else { return }
            router.push(.transfer)
        }
    }
}
