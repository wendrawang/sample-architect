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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    hero
                    quickActions
                        .padding(.horizontal, AppSpacing.md)
                        .offset(y: -28)
                        .padding(.bottom, -12)
                    loginForm
                }
            }
            .background(AppColor.background)
        }
    }

    private var hero: some View {
        ZStack(alignment: .topLeading) {
            UsernameStyle.heroGradient

            Circle()
                .fill(AppColor.brand)
                .frame(width: 260, height: 360)
                .offset(x: -205, y: 38)

            VStack(spacing: AppSpacing.lg) {
                HStack {
                    BankBrandLogo(size: .compact)
                    Spacer()
                    Image(systemName: "bell")
                        .font(.system(size: 21, weight: .medium))
                    Text("ID")
                        .font(AppTypography.label)
                        .foregroundColor(AppColor.accent)
                }

                HStack(alignment: .center, spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Cerdas melawan\npenipuan digital")
                            .font(AppTypography.title)
                            .foregroundColor(AppColor.charcoal)
                        Text("Lindungi keamanan data diri Anda.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColor.secondaryText)
                        Button("Pelajari Sekarang", action: viewModel.didTapHelp)
                            .font(AppTypography.label)
                            .foregroundColor(AppColor.accent)
                    }

                    ZStack {
                        Circle()
                            .fill(AppColor.brand.opacity(0.08))
                            .frame(width: 112, height: 112)
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 64, weight: .light))
                            .foregroundColor(AppColor.brand)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.xxl)
        }
        .frame(height: UsernameStyle.heroHeight)
        .clipped()
    }

    private var quickActions: some View {
        LazyVGrid(columns: UsernameStyle.menuColumns, spacing: AppSpacing.lg) {
            quickAction("Transfer", icon: "arrow.left.arrow.right")
            quickAction("Tarik Tunai", icon: "banknote")
            quickAction("PIN Token", icon: "rectangle.and.hand.point.up.left")
            quickAction("e-Money", icon: "wallet.pass")
            quickAction("Scan", icon: "qrcode.viewfinder")
            quickAction("Promo", icon: "tag")
        }
        .padding(.vertical, AppSpacing.lg)
        .padding(.horizontal, AppSpacing.sm)
        .background(AppColor.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
    }

    private func quickAction(_ title: String, icon: String) -> some View {
        Button(action: viewModel.didTapHelp) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .medium))
                    .foregroundColor(AppColor.charcoal)
                    .frame(height: 34)
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColor.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var loginForm: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Masuk ke OCBC Indonesia")
                    .font(AppTypography.title)
                Text("Masukkan username Internet Banking kamu.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColor.secondaryText)
            }

            BankInputCard(
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
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.xxl)
    }
}
