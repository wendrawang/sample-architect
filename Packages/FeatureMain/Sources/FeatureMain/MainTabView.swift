import CoreNavigation
import CorePresentation
import DesignSystem
import FeatureDashboard
import FeatureFinancial
import FeatureMore
import FeatureQRIS
import FeatureRewards
import SwiftUI

/// Shell tab bar. Ia menyusun lima tab dan tidak tahu apa-apa soal layar yang bisa
/// di-push dari dalamnya — tiap tab memiliki stack dan route-nya sendiri.
public struct MainTabView<DashboardDestination: View>: View {
    @StateObject private var viewModel: MainTabViewModel
    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var financialViewModel: FinancialViewModel
    @StateObject private var qrisViewModel: QRISViewModel
    @StateObject private var rewardsViewModel: RewardsViewModel
    @StateObject private var moreViewModel: MoreViewModel

    private let dashboardDestination: (DashboardRoute) -> DashboardDestination

    public init(
        dependencies: any DashboardDependencies,
        onLogout: @escaping () -> Void,
        @ViewBuilder dashboardDestination: @escaping (DashboardRoute) -> DashboardDestination
    ) {
        self.dashboardDestination = dashboardDestination
        _viewModel = StateObject(wrappedValue: MainTabViewModel())
        _dashboardViewModel = StateObject(
            wrappedValue: DashboardViewModel(
                getSummary: GetDashboardSummaryUseCase(
                    repository: dependencies.makeDashboardRepository()
                )
            )
        )
        _financialViewModel = StateObject(wrappedValue: FinancialViewModel())
        _qrisViewModel = StateObject(wrappedValue: QRISViewModel())
        _rewardsViewModel = StateObject(wrappedValue: RewardsViewModel())
        _moreViewModel = StateObject(wrappedValue: MoreViewModel(onLogout: onLogout))
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $viewModel.selection) {
                DashboardFlowView(
                    viewModel: dashboardViewModel,
                    destination: dashboardDestination
                )
                    .tag(MainTab.dashboard)
                    .tabItem {
                        Label("Beranda", systemImage: "house.fill")
                    }

                FinancialView(viewModel: financialViewModel)
                    .tag(MainTab.financial)
                    .tabItem {
                        Label("Finansial", systemImage: "chart.pie.fill")
                    }

                QRISView(viewModel: qrisViewModel)
                    .tag(MainTab.qris)
                    .tabItem {
                        Label("", systemImage: "circle.fill")
                    }

                RewardsView(viewModel: rewardsViewModel)
                    .tag(MainTab.rewards)
                    .tabItem {
                        Label("Rewards", systemImage: "gift.fill")
                    }

                MoreView(viewModel: moreViewModel)
                    .tag(MainTab.more)
                    .tabItem {
                        Label("Lainnya", systemImage: "circle.grid.2x2.fill")
                    }
            }
            .tint(AppColor.brand)

            CenterQRISOverlay(
                selection: viewModel.selection,
                dashboard: dashboardViewModel.presentation,
                financial: financialViewModel.presentation,
                qris: qrisViewModel.presentation,
                rewards: rewardsViewModel.presentation,
                more: moreViewModel.presentation,
                action: viewModel.selectQRIS
            )
            .padding(.bottom, MainTabStyle.centerButtonBottomPadding)
        }
    }
}

private struct CenterQRISOverlay: View {
    let selection: MainTab
    @ObservedObject var dashboard: ScreenPresentationStore
    @ObservedObject var financial: ScreenPresentationStore
    @ObservedObject var qris: ScreenPresentationStore
    @ObservedObject var rewards: ScreenPresentationStore
    @ObservedObject var more: ScreenPresentationStore
    let action: () -> Void

    var body: some View {
        if !activeStoreHasModal {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(
                            width: MainTabStyle.centerButtonSize + 8,
                            height: MainTabStyle.centerButtonSize + 8
                        )

                    Circle()
                        .fill(MainTabStyle.centerButtonGradient)
                        .frame(
                            width: MainTabStyle.centerButtonSize,
                            height: MainTabStyle.centerButtonSize
                        )
                        .shadow(color: AppColor.brand.opacity(0.34), radius: 10, x: 0, y: 6)

                    VStack(spacing: 1) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 22, weight: .bold))
                        Text("QRIS")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Scan QRIS")
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var activeStoreHasModal: Bool {
        let store: ScreenPresentationStore
        switch selection {
        case .dashboard:
            store = dashboard
        case .financial:
            store = financial
        case .qris:
            store = qris
        case .rewards:
            store = rewards
        case .more:
            store = more
        }
        return store.bottomSheet != nil || store.blocker != nil
    }
}
