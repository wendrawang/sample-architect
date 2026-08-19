import DesignSystem
import SwiftUI

public struct SplashView: View {
    @ObservedObject private var viewModel: SplashViewModel

    public init(viewModel: SplashViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScreenScaffold(
            presentation: viewModel.presentation,
            style: .edgeToEdge,
            onAction: viewModel.handlePresentationAction
        ) {
            ZStack {
                SplashStyle.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: AppSpacing.md) {
                        BankBrandLogo(size: .large)

                        if viewModel.isLoading {
                            ProgressView()
                                .tint(AppColor.brand)
                                .scaleEffect(0.82)
                                .accessibilityLabel("Menyiapkan aplikasi")
                        }
                    }

                    Spacer()

                    Text("Hak Cipta 2026, PT Bank OCBC NISP Tbk berizin dan diawasi oleh Otoritas Jasa Keuangan & Bank Indonesia, serta merupakan peserta penjaminan LPS.")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColor.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.xl)
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }
}
