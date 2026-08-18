import Combine
import CoreKit
import CorePresentation
import Foundation

public struct RewardItem: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let points: Int

    public init(id: String, title: String, points: Int) {
        self.id = id
        self.title = title
        self.points = points
    }
}

@MainActor
public final class RewardsViewModel: ObservableObject {
    public let presentation = ScreenPresentationStore()
    public let totalPoints = 12_450
    public let rewards: [RewardItem] = [
        RewardItem(id: "coffee", title: "Voucher Kopi", points: 2_500),
        RewardItem(id: "shopping", title: "Voucher Belanja", points: 5_000),
        RewardItem(id: "miles", title: "1.000 Airline Miles", points: 10_000)
    ]

    private let lifecycleProbe = LifecycleProbe("RewardsViewModel")

    public init() {}

    public func didTapRedeem(_ reward: RewardItem) {
        presentation.present(
            bottomSheet: BottomSheetModel(
                iconSystemName: "gift.fill",
                title: "Tukar reward?",
                message: "Tukar \(reward.points.formatted()) poin untuk \(reward.title).",
                actions: [
                    PresentationAction(id: "redeem-\(reward.id)", title: "Tukar Sekarang"),
                    PresentationAction(id: "cancel", title: "Nanti", role: .secondary)
                ]
            )
        )
    }

    public func handlePresentationAction(_ id: String) {
        guard id.hasPrefix("redeem-") else { return }
        presentation.show(
            snackbar: SnackbarModel(
                message: "Reward berhasil ditukar.",
                iconSystemName: "checkmark.circle.fill"
            )
        )
    }
}

