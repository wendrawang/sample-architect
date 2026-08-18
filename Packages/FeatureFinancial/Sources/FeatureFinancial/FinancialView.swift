import DesignSystem
import SwiftUI

public struct FinancialView: View {
    @ObservedObject private var viewModel: FinancialViewModel

    public init(viewModel: FinancialViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScreenScaffold(presentation: viewModel.presentation, style: .tab) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("Financial")
                        .font(AppTypography.title)

                    portfolioCard

                    SectionHeader("Produk Anda")
                    ForEach(viewModel.products) { product in
                        productCard(product)
                    }
                }
                .padding(.vertical, AppSpacing.md)
            }
        }
    }

    private var portfolioCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Total portofolio").font(AppTypography.label)
                Spacer()
                Button(action: viewModel.didTapRiskInfo) {
                    Image(systemName: "info.circle")
                }
            }
            Text("Rp28.240.000")
                .font(AppTypography.hero)
            Text("+Rp1.240.000 bulan ini")
                .font(AppTypography.label)
                .foregroundColor(Color.green.opacity(0.9))
        }
        .foregroundColor(.white)
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FinancialStyle.portfolioGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }

    private func productCard(_ product: FinancialProduct) -> some View {
        AppCard {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(AppColor.brand)
                    .frame(width: FinancialStyle.iconSize, height: FinancialStyle.iconSize)
                    .background(AppColor.brand.opacity(0.09))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(product.name).font(AppTypography.label)
                    Text(product.value).font(AppTypography.heading)
                }
                Spacer()
                Text(product.change)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColor.success)
            }
        }
    }
}

