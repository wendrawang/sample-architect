import DesignSystem
import SwiftUI

public struct MoreView: View {
    @ObservedObject private var viewModel: MoreViewModel

    public init(viewModel: MoreViewModel) {
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
                    Text("More")
                        .font(AppTypography.title)
                    profileCard
                    menuList
                    logoutButton
                }
                .padding(.vertical, AppSpacing.md)
            }
        }
    }

    private var profileCard: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "person.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(AppColor.brand)
                .frame(width: 58, height: 58)
                .background(Color.white)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Wendra")
                    .font(AppTypography.heading)
                Text("Nasabah Premier")
                    .font(AppTypography.caption)
                    .opacity(0.8)
            }
            Spacer()
            Image(systemName: "chevron.right")
        }
        .foregroundColor(.white)
        .padding(AppSpacing.lg)
        .background(MoreStyle.profileGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }

    private var menuList: some View {
        AppCard {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.menus.enumerated()), id: \.element.id) { index, menu in
                    Button { viewModel.didTapMenu(menu) } label: {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: menu.icon)
                                .foregroundColor(AppColor.brand)
                                .frame(width: MoreStyle.menuIconSize, height: MoreStyle.menuIconSize)
                                .background(AppColor.brand.opacity(0.09))
                                .clipShape(Circle())
                            Text(menu.title)
                                .font(AppTypography.body)
                                .foregroundColor(AppColor.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColor.secondaryText)
                        }
                        .padding(.vertical, AppSpacing.sm)
                    }
                    .buttonStyle(.plain)

                    if index < viewModel.menus.count - 1 {
                        Divider().padding(.leading, 58)
                    }
                }
            }
        }
    }

    private var logoutButton: some View {
        Button(action: viewModel.didTapLogout) {
            Label("Keluar", systemImage: "rectangle.portrait.and.arrow.right")
                .font(AppTypography.label)
                .foregroundColor(AppColor.danger)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColor.danger.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

