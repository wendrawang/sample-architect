import DesignSystem
import SwiftUI

public struct TransferView: View {
    @ObservedObject private var viewModel: TransferViewModel

    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScreenScaffold(
            presentation: viewModel.presentation,
            onAction: viewModel.handlePresentationAction
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    AppCard {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(AppColor.brand)
                                .frame(width: TransferStyle.accountIconSize, height: TransferStyle.accountIconSize)
                                .background(AppColor.brand.opacity(0.09))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("Sumber dana")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColor.secondaryText)
                                Text("Tabungan • 9012")
                                    .font(AppTypography.heading)
                            }
                        }
                    }

                    AppTextField(
                        title: "Rekening tujuan",
                        placeholder: "Masukkan nomor rekening",
                        text: $viewModel.destinationAccount,
                        keyboardType: .numberPad
                    )

                    AppTextField(
                        title: "Nominal",
                        placeholder: "Contoh: 100000",
                        text: $viewModel.amount,
                        keyboardType: .numberPad
                    )

                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppColor.accent)
                        Text("Template ini memakai mock service. Aktifkan live service setelah endpoint dan contract backend tersedia.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColor.secondaryText)
                    }
                    .padding(AppSpacing.md)
                    .background(TransferStyle.infoBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))

                    PrimaryButton(
                        "Lanjut",
                        isLoading: viewModel.isLoading,
                        isEnabled: !viewModel.destinationAccount.isEmpty && !viewModel.amount.isEmpty,
                        action: viewModel.didTapReview
                    )
                }
                .padding(.vertical, AppSpacing.lg)
            }
        }
    }
}

