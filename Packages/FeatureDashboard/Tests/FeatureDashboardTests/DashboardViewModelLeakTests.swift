import Combine
import CoreTestSupport
import FeatureDashboard
import XCTest

private struct StubGetSummaryUseCase: GetDashboardSummaryUseCaseProtocol {
    func execute() async throws -> DashboardSummary {
        DashboardSummary(
            customerName: "Test",
            accountNumber: "1",
            availableBalance: 100,
            transactions: []
        )
    }
}

/// Menggantikan prosedur manual "buka Memory Graph setelah mengulang flow sepuluh kali"
/// dengan test yang gagal di CI.
@MainActor
final class DashboardViewModelLeakTests: XCTestCase {
    func testViewModelIsReleasedWhenOwnerGoesAway() {
        assertDeallocatedAfterUse {
            DashboardViewModel(getSummary: StubGetSummaryUseCase())
        }
    }

    /// Sinyal `transferRequested` sengaja tidak memegang siapa pun. Kalau suatu hari ada
    /// yang menggantinya dengan closure yang menangkap ViewModel, test ini yang jatuh.
    func testObservingTheTransferSignalDoesNotRetainTheViewModel() {
        assertNoAccumulation(iterations: 10) {
            DashboardViewModel(getSummary: StubGetSummaryUseCase())
        } use: { viewModel in
            var received = 0
            let subscription = viewModel.transferRequested.sink { received += 1 }
            viewModel.didTapTransfer()
            subscription.cancel()
            XCTAssertEqual(received, 1)
        }
    }
}
