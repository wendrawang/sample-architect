import DesignSystem
import Foundation
import SwiftUI

public struct DashboardView: View {
    @ObservedObject private var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
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
                    header

                    if let summary = viewModel.summary {
                        balanceCard(summary)
                        quickMenu
                        transactions(summary.transactions)
                    } else if viewModel.isLoading {
                        loadingState
                    }
                }
                .padding(.vertical, AppSpacing.md)
            }
            .refreshable { await viewModel.refresh() }
        }
        .onAppear(perform: viewModel.onAppear)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Selamat datang,")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColor.secondaryText)
                Text(viewModel.summary?.customerName ?? "Nasabah")
                    .font(AppTypography.title)
            }
            Spacer()
            Image(systemName: "bell.fill")
                .foregroundColor(AppColor.brand)
                .frame(width: 42, height: 42)
                .background(AppColor.elevatedSurface)
                .clipShape(Circle())
        }
    }

    private func balanceCard(_ summary: DashboardSummary) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Saldo tersedia")
                    .font(AppTypography.label)
                Spacer()
                Button(action: viewModel.didTapBalanceInfo) {
                    Image(systemName: "info.circle")
                }
            }

            Text(currency(summary.availableBalance))
                .font(AppTypography.hero)
                .minimumScaleFactor(0.72)
                .lineLimit(1)

            Text(summary.accountNumber)
                .font(.system(.body, design: .monospaced))
                .opacity(0.8)
        }
        .foregroundColor(.white)
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DashboardStyle.balanceGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }

    private var quickMenu: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader("Menu cepat")
            LazyVGrid(columns: DashboardStyle.menuColumns, spacing: AppSpacing.md) {
                menuButton(title: "Transfer", icon: "arrow.left.arrow.right", action: viewModel.didTapTransfer)
                menuButton(title: "Bayar", icon: "doc.text.fill") {}
                menuButton(title: "Top Up", icon: "plus.circle.fill") {}
                menuButton(title: "Lainnya", icon: "square.grid.2x2.fill") {}
            }
        }
    }

    private func menuButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColor.brand)
                    .frame(width: 46, height: 46)
                    .background(AppColor.brand.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColor.primaryText)
                    .lineLimit(1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func transactions(_ items: [DashboardTransaction]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader("Transaksi terbaru", actionTitle: "Lihat Semua") {}
            AppCard {
                LazyVStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        transactionRow(item)
                        if index < items.count - 1 {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
            }
        }
    }

    private func transactionRow(_ item: DashboardTransaction) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: item.amount >= 0 ? "arrow.down.left" : "arrow.up.right")
                .foregroundColor(item.amount >= 0 ? AppColor.success : AppColor.danger)
                .frame(width: 36, height: 36)
                .background((item.amount >= 0 ? AppColor.success : AppColor.danger).opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(item.title).font(AppTypography.label)
                Text(item.subtitle)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColor.secondaryText)
            }
            Spacer()
            Text(currency(item.amount))
                .font(AppTypography.label)
                .foregroundColor(item.amount >= 0 ? AppColor.success : AppColor.primaryText)
        }
        .padding(.vertical, AppSpacing.sm)
    }

    private var loadingState: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
            Text("Memuat dashboard...")
                .font(AppTypography.body)
                .foregroundColor(AppColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
    }

    private func currency(_ amount: Decimal) -> String {
        DashboardStyle.currencyFormatter.string(from: amount as NSDecimalNumber) ?? "Rp0"
    }
}
