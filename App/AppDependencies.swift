import CoreNetwork
import FeatureAuth
import FeatureDashboard
import FeatureSplash
import FeatureTransfer
import Foundation

/// Satu-satunya tempat yang tahu implementasi konkret setiap repository.
///
/// Feature hanya mendeklarasikan protokol kebutuhannya; object ini memenuhi semuanya.
/// Menambah feature berarti menambah satu `extension` di bawah, bukan mengubah struct
/// bersama yang dipakai semua orang.
///
/// Semua method berbentuk factory, jadi repository baru dibangun saat layarnya dibuka.
/// Layar yang tidak pernah dibuka tidak pernah membayar apa pun.
final class AppDependencies: Sendable {
    private let apiClient: any APIClient
    private let configuration: AppConfiguration

    init(apiClient: any APIClient, configuration: AppConfiguration) {
        self.apiClient = apiClient
        self.configuration = configuration
    }

    private var useMocks: Bool { configuration.useMockServices }
}

extension AppDependencies: SplashDependencies {
    func makeSplashRepository() -> any SplashRepositoryProtocol {
        guard useMocks else {
            return RemoteSplashRepository(
                apiClient: apiClient,
                path: configuration.splashInquiryPath
            )
        }

        let arguments = ProcessInfo.processInfo.arguments
        let destination: LaunchDestination
        if arguments.contains("-simulateMaintenance") {
            destination = .maintenance
        } else if arguments.contains("-simulateForceUpdate") {
            destination = .forceUpdate
        } else {
            destination = .preLogin
        }

        return MockSplashRepository(
            decision: LaunchDecision(destination: destination),
            shouldFail: arguments.contains("-simulateSplashFailure")
        )
    }
}

extension AppDependencies: AuthDependencies {
    func makeAuthRepository() -> any AuthRepositoryProtocol {
        if useMocks {
            return MockAuthRepository()
        }
        return RemoteAuthRepository(apiClient: apiClient)
    }
}

extension AppDependencies: DashboardDependencies {
    func makeDashboardRepository() -> any DashboardRepositoryProtocol {
        if useMocks {
            return MockDashboardRepository()
        }
        return RemoteDashboardRepository(apiClient: apiClient)
    }
}

extension AppDependencies: TransferDependencies {
    func makeTransferRepository() -> any TransferRepositoryProtocol {
        if useMocks {
            return MockTransferRepository()
        }
        return RemoteTransferRepository(apiClient: apiClient)
    }
}
