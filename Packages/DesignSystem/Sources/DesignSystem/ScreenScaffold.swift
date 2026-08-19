import CorePresentation
import SwiftUI

/// `Sendable` is spelled out because Swift only infers it for non-public types: for a
/// public one the conformance is part of the API contract, so the compiler refuses to
/// commit you to it silently. Without it the `static let` presets below count as shared
/// mutable state.
public struct ScreenStyle: Sendable {
    public let background: Color
    public let horizontalPadding: CGFloat
    public let snackbarBottomPadding: CGFloat

    public init(
        background: Color = AppColor.background,
        horizontalPadding: CGFloat = AppSpacing.md,
        snackbarBottomPadding: CGFloat = AppSpacing.lg
    ) {
        self.background = background
        self.horizontalPadding = horizontalPadding
        self.snackbarBottomPadding = snackbarBottomPadding
    }

    public static let standard = ScreenStyle()
    public static let tab = ScreenStyle(snackbarBottomPadding: 82)
    public static let edgeToEdge = ScreenStyle(horizontalPadding: 0)
}

public struct ScreenScaffold<Content: View>: View {
    @ObservedObject private var presentation: ScreenPresentationStore
    private let style: ScreenStyle
    private let onAction: (String) -> Void
    private let content: Content

    public init(
        presentation: ScreenPresentationStore,
        style: ScreenStyle = .standard,
        onAction: @escaping (String) -> Void = { _ in },
        @ViewBuilder content: () -> Content
    ) {
        self.presentation = presentation
        self.style = style
        self.onAction = onAction
        self.content = content()
    }

    public var body: some View {
        ZStack {
            style.background.ignoresSafeArea()

            content
                .padding(.horizontal, style.horizontalPadding)

            if let blocker = presentation.blocker {
                blockerView(blocker)
                    .transition(.opacity)
                    .zIndex(20)
            }

            if let bottomSheet = presentation.bottomSheet {
                bottomSheetView(bottomSheet)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .zIndex(30)
            }

            if let snackbar = presentation.snackbar {
                snackbarView(snackbar)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(40)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: presentation.blocker?.id)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: presentation.bottomSheet?.id)
        .animation(.easeOut(duration: 0.2), value: presentation.snackbar?.id)
    }

    private func bottomSheetView(_ model: BottomSheetModel) -> some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    guard model.isDismissible else { return }
                    presentation.dismissBottomSheet()
                }

            VStack(spacing: AppSpacing.md) {
                Capsule()
                    .fill(AppColor.divider)
                    .frame(width: 42, height: 5)

                if let icon = model.iconSystemName {
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(AppColor.brand)
                }

                VStack(spacing: AppSpacing.xs) {
                    Text(model.title)
                        .font(AppTypography.heading)
                        .multilineTextAlignment(.center)
                    Text(model.message)
                        .font(AppTypography.body)
                        .foregroundColor(AppColor.secondaryText)
                        .multilineTextAlignment(.center)
                }

                actionList(model.actions) { action in
                    if action.dismissesOnTap {
                        presentation.dismissBottomSheet()
                    }
                    onAction(action.id)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.xl)
            .frame(maxWidth: .infinity)
            .background(AppColor.elevatedSurface)
            .clipShape(
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func blockerView(_ model: ScreenBlockerModel) -> some View {
        ZStack {
            AppColor.elevatedSurface.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                Image(systemName: model.iconSystemName)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundColor(AppColor.warning)

                VStack(spacing: AppSpacing.xs) {
                    Text(model.title)
                        .font(AppTypography.title)
                        .multilineTextAlignment(.center)
                    Text(model.message)
                        .font(AppTypography.body)
                        .foregroundColor(AppColor.secondaryText)
                        .multilineTextAlignment(.center)
                }

                actionList(model.actions) { action in
                    if action.dismissesOnTap {
                        presentation.dismissBlocker()
                    }
                    onAction(action.id)
                }
            }
            .padding(AppSpacing.xl)
        }
    }

    private func snackbarView(_ model: SnackbarModel) -> some View {
        VStack {
            Spacer()
            HStack(spacing: AppSpacing.sm) {
                if let icon = model.iconSystemName {
                    Image(systemName: icon)
                }
                Text(model.message)
                    .font(AppTypography.label)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .foregroundColor(.white)
            .padding(AppSpacing.md)
            .background(Color.black.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, style.snackbarBottomPadding)
            .onTapGesture { presentation.dismissSnackbar() }
        }
        .allowsHitTesting(true)
    }

    private func actionList(
        _ actions: [PresentationAction],
        onTap: @escaping (PresentationAction) -> Void
    ) -> some View {
        VStack(spacing: AppSpacing.xs) {
            ForEach(actions) { action in
                Button {
                    onTap(action)
                } label: {
                    Text(action.title)
                        .font(AppTypography.label)
                        .foregroundColor(actionForeground(action.role))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(actionBackground(action.role))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private func actionForeground(_ role: PresentationActionRole) -> Color {
        switch role {
        case .primary, .destructive:
            return .white
        case .secondary:
            return AppColor.brand
        }
    }

    private func actionBackground(_ role: PresentationActionRole) -> Color {
        switch role {
        case .primary:
            return AppColor.brand
        case .secondary:
            return AppColor.brand.opacity(0.08)
        case .destructive:
            return AppColor.danger
        }
    }
}

