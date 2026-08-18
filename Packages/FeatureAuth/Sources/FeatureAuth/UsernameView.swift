import DesignSystem
import SwiftUI

public struct UsernameView: View {
    @ObservedObject private var viewModel: UsernameViewModel

    public init(viewModel: UsernameViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScreenScaffold(
            presentation: viewModel.presentation,
            style: .edgeToEdge,
            onAction: viewModel.handlePresentationAction
        ) {
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    form
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(AppColor.background)
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            UsernameStyle.heroGradient
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 34, weight: .semibold))
                Text("Selamat datang")
                    .font(AppTypography.hero)
                Text("Masuk dengan aman ke akun Anda")
                    .font(AppTypography.body)
                    .opacity(0.8)
            }
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
        .frame(height: UsernameStyle.heroHeight)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            AppTextField(
                title: "Username",
                placeholder: "Masukkan username",
                text: $viewModel.username
            )

            PrimaryButton(
                "Lanjut",
                isEnabled: viewModel.canContinue,
                action: viewModel.didTapContinue
            )

            Button("Butuh bantuan?", action: viewModel.didTapHelp)
                .font(AppTypography.label)
                .foregroundColor(AppColor.brand)
                .frame(maxWidth: .infinity)
        }
        .padding(AppSpacing.lg)
    }
}

