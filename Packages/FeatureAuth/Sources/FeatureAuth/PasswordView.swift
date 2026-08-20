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
            style: ScreenStyle(background: .white),
            onAction: viewModel.handlePresentationAction
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Masukkan Password kamu\nuntuk login ke OCBC mobile")
                    .font(AppTypography.title)
                    .fontWeight(.regular)
                    .padding(.top, AppSpacing.lg)

                BankInputCard(
                    title: "Password Login",
                    placeholder: "Masukkan password login kamu",
                    text: $viewModel.password,
                    isSecure: true
                )

                Button("Lupa atau Belum Punya Password?", action: viewModel.didTapForgotPassword)
                    .font(AppTypography.label)
                    .foregroundColor(AppColor.brand)
                    .underline()
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppSpacing.lg)

                Spacer(minLength: AppSpacing.xl)

                HStack(spacing: AppSpacing.md) {
                    Button(action: viewModel.didTapBiometric) {
                        Image(systemName: "faceid")
                            .font(.system(size: 27, weight: .medium))
                            .foregroundColor(AppColor.primaryText)
                            .frame(
                                width: PasswordStyle.biometricButtonWidth,
                                height: PasswordStyle.biometricButtonHeight
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.medium)
                                    .stroke(PasswordStyle.biometricBorder, lineWidth: 1.4)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())

                    PrimaryButton(
                        "Lanjut",
                        isLoading: viewModel.isLoading,
                        isEnabled: viewModel.password.count >= 6,
                        action: viewModel.didTapLogin
                    )
                }
                .padding(.bottom, AppSpacing.md)
            }
        }
    }
}

/// Ownership boundary for the password screen. It is built when the route is pushed and
/// released when it pops, which is what lets `PasswordViewModel.deinit` cancel its login task.
public struct PasswordScreen: View {
    @StateObject private var viewModel: PasswordViewModel

    public init(
        username: String,
        dependencies: any AuthDependencies,
        onAuthenticated: @escaping (AuthSession) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: PasswordViewModel(
                username: username,
                loginUseCase: LoginUseCase(
                    repository: dependencies.makeAuthRepository()
                ),
                onAuthenticated: onAuthenticated
            )
        )
    }

    public var body: some View {
        PasswordView(viewModel: viewModel)
    }
}
