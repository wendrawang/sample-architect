import DesignSystem
import SwiftUI

public struct PasswordView: View {
    @ObservedObject private var viewModel: PasswordViewModel

    public init(viewModel: PasswordViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScreenScaffold(
            presentation: viewModel.presentation,
            onAction: viewModel.handlePresentationAction
        ) {
            VStack(spacing: AppSpacing.lg) {
                Spacer(minLength: AppSpacing.xl)

                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppColor.brand)
                    .frame(width: PasswordStyle.avatarSize, height: PasswordStyle.avatarSize)
                    .background(PasswordStyle.iconBackground)
                    .clipShape(Circle())

                VStack(spacing: AppSpacing.xs) {
                    Text("Halo, \(viewModel.username)")
                        .font(AppTypography.title)
                    Text("Masukkan password untuk melanjutkan")
                        .font(AppTypography.body)
                        .foregroundColor(AppColor.secondaryText)
                }

                AppTextField(
                    title: "Password",
                    placeholder: "Minimal 6 karakter",
                    text: $viewModel.password,
                    isSecure: true
                )

                PrimaryButton(
                    "Masuk",
                    isLoading: viewModel.isLoading,
                    isEnabled: viewModel.password.count >= 6,
                    action: viewModel.didTapLogin
                )

                Spacer()
            }
            .padding(.vertical, AppSpacing.lg)
        }
    }
}

