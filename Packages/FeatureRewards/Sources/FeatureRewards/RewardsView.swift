import DesignSystem
import Foundation
import SwiftUI

public struct RewardsView: View {
    @ObservedObject private var viewModel: RewardsViewModel

    public init(viewModel: RewardsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScreenScaffold(
            presentation: viewModel.presentation,
            style: .tab,
            onAction: viewModel.handlePresentationAction
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("Rewards")
                        .font(AppTypography.title)

                    pointsCard
                    SectionHeader("Pilihan reward")

                    ForEach(viewModel.rewards) { reward in
                        rewardCard(reward)
                    }
                }
                .padding(.vertical, AppSpacing.md)
            }
        }
    }

    private var pointsCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Poin Anda").font(AppTypography.label)
                Text(viewModel.totalPoints.formatted())
                    .font(AppTypography.hero)
                Text("Terus bertransaksi untuk tambah poin")
                    .font(AppTypography.caption)
                    .opacity(0.8)
            }
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(AppSpacing.lg)
        .background(RewardsStyle.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }

    private func rewardCard(_ reward: RewardItem) -> some View {
        AppCard {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(AppColor.brand)
                    .frame(width: RewardsStyle.rewardIconSize, height: RewardsStyle.rewardIconSize)
                    .background(AppColor.brand.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(reward.title).font(AppTypography.label)
                    Text("\(reward.points.formatted()) poin")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColor.secondaryText)
                }
                Spacer()
                Button("Tukar") { viewModel.didTapRedeem(reward) }
                    .font(AppTypography.label)
                    .foregroundColor(AppColor.brand)
            }
        }
    }
}
