import CoreNetwork
import FeatureDashboard
import FeatureTransfer

public struct MainDependencies {
    let dashboardRepository: DashboardRepositoryProtocol
    let transferRepository: TransferRepositoryProtocol

    public init(
        dashboardRepository: DashboardRepositoryProtocol,
        transferRepository: TransferRepositoryProtocol
    ) {
        self.dashboardRepository = dashboardRepository
        self.transferRepository = transferRepository
    }

    public static func make(
        apiClient: any APIClient,
        useMocks: Bool
    ) -> MainDependencies {
        if useMocks {
            return MainDependencies(
                dashboardRepository: MockDashboardRepository(),
                transferRepository: MockTransferRepository()
            )
        }

        return MainDependencies(
            dashboardRepository: RemoteDashboardRepository(apiClient: apiClient),
            transferRepository: RemoteTransferRepository(apiClient: apiClient)
        )
    }
}

