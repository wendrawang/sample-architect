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
            style: .edgeToEdge
        ) {
            ZStack {
                SplashStyle.background.ignoresSafeArea()

                VStack(spacing: AppSpacing.lg) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                            .fill(Color.white)
                            .frame(width: SplashStyle.logoSize, height: SplashStyle.logoSize)

                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(AppColor.brand)
                    }

                    VStack(spacing: AppSpacing.xs) {
                        Text("Modular Bank")
                            .font(AppTypography.hero)
                            .foregroundColor(.white)
                        Text("Secure. Fast. Modular.")
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.78))
                    }

                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }
}

