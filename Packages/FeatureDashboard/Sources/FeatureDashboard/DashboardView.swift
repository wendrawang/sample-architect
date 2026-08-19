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
            style: ScreenStyle(
                background: .white,
                horizontalPadding: 0,
                snackbarBottomPadding: 90
            ),
            onAction: viewModel.handlePresentationAction
        ) {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                    promotionalHeader
                    quickMenuCard
                        .padding(.horizontal, AppSpacing.md)
                        .offset(y: -52)
                        .padding(.bottom, -52)

                    if let summary = viewModel.summary {
                        balanceCard(summary)
                            .padding(.horizontal, AppSpacing.md)
                        foreignExchangeCard
                            .padding(.horizontal, AppSpacing.md)
                        transactions(summary.transactions)
                            .padding(.horizontal, AppSpacing.md)
                    } else if viewModel.isLoading {
                        loadingState
                    }
                }
                .padding(.bottom, 110)
            }
            .refreshable { await viewModel.refresh() }
        }
        .onAppear(perform: viewModel.onAppear)
    }

    private var promotionalHeader: some View {
        ZStack(alignment: .topLeading) {
            DashboardStyle.heroGradient

            Circle()
                .fill(AppColor.brand)
                .frame(width: 270, height: 430)
                .offset(x: -220, y: 30)

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack {
                    HStack(spacing: AppSpacing.xs) {
                        Text("NYALA Fit")
                            .font(AppTypography.label)
                        Divider().frame(height: 18)
                        Image(systemName: "p.circle")
                        Text("1.478")
                            .font(AppTypography.label)
                    }
                    .padding(.horizontal, AppSpacing.sm)
                    .frame(height: 38)
                    .overlay(Capsule().stroke(AppColor.primaryText, lineWidth: 1))

                    Spacer()

                    Image(systemName: "bell")
                        .font(.system(size: 22, weight: .medium))
                        .overlay(alignment: .topTrailing) {
                            Circle()
                                .fill(AppColor.brand)
                                .frame(width: 7, height: 7)
                        }
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 24, weight: .medium))
                }

                HStack(alignment: .center, spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Cerdas lawan penipuan digital dan lindungi keamanan data diri Anda.")
                            .font(AppTypography.heading)
                            .foregroundColor(AppColor.secondaryText)
                        Text("Pelajari Sekarang")
                            .font(AppTypography.heading)
                            .foregroundColor(AppColor.accent)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(AppColor.brand.opacity(0.08))
                            .frame(width: 122, height: 128)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 62, weight: .light))
                            .foregroundColor(AppColor.brand)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
        }
        .frame(height: DashboardStyle.heroHeight)
        .clipped()
    }

    private var quickMenuCard: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: DashboardStyle.menuColumns, spacing: AppSpacing.xl) {
                menuButton(title: "Transfer", icon: "arrow.left.arrow.right", action: viewModel.didTapTransfer)
                menuButton(title: "Top Up\n& Bayar", icon: "creditcard.and.123") {}
                menuButton(title: "Investasi", icon: "chart.line.uptrend.xyaxis") {}
                menuButton(title: "Uang\nElektronik", icon: "wallet.pass") {}
                menuButton(title: "Kartu Kredit", icon: "creditcard") {}
                menuButton(title: "Semua Menu", icon: "circle.grid.2x2") {}
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.lg)

            Button(action: viewModel.didTapBalanceInfo) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.orange)
                        .frame(width: 34, height: 34)
                        .background(Color.white)
                        .clipShape(Circle())
                    Text("Bayar tagihan kamu di sini!")
                        .font(AppTypography.label)
                        .foregroundColor(AppColor.primaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppColor.primaryText)
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 64)
                .background(AppColor.brand.opacity(0.08))
            }
        }
        .background(AppColor.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 8)
    }

    private func menuButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 25, weight: .medium))
                    .foregroundColor(AppColor.primaryText)
                    .frame(height: 36)
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColor.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 42, alignment: .top)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func balanceCard(_ summary: DashboardSummary) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Saldo Aktif - IDR")
                    .font(AppTypography.body)
                    .foregroundColor(AppColor.secondaryText)
                Image(systemName: "chevron.down")
                    .foregroundColor(AppColor.brand)
                Spacer()
                Button(action: viewModel.didTapBalanceInfo) {
                    Label("Sembunyi", systemImage: "eye.slash")
                        .labelStyle(.titleAndIcon)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColor.secondaryText)
                }
            }

            Text(currency(summary.availableBalance))
                .font(AppTypography.title)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 6)
    }

    private var foreignExchangeCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Valuta Asing")
                .font(AppTypography.title)

            ZStack(alignment: .bottomTrailing) {
                LinearGradient(
                    colors: [AppColor.charcoal.opacity(0.78), AppColor.charcoal.opacity(0.48)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Kurs Bank Jual")
                        .font(AppTypography.heading)
                    Text("Harga indikatif dalam IDR")
                        .font(AppTypography.caption)
                        .opacity(0.85)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(AppSpacing.md)
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 25))
                    .foregroundColor(.white)
                    .padding(AppSpacing.md)
            }
            .frame(height: 126)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        }
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
                .foregroundColor(item.amount >= 0 ? AppColor.success : AppColor.brand)
                .frame(width: 36, height: 36)
                .background((item.amount >= 0 ? AppColor.success : AppColor.brand).opacity(0.1))
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
            ProgressView().tint(AppColor.brand)
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
