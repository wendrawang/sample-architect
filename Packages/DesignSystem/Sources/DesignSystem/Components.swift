import SwiftUI
import UIKit

public struct PrimaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let isEnabled: Bool
    private let action: () -> Void

    public init(
        _ title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(AppTypography.label)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if isEnabled {
                        LinearGradient(
                            colors: [AppColor.brandDark, AppColor.brand],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.gray.opacity(0.45), Color.gray.opacity(0.45)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled || isLoading)
    }
}

public enum BankBrandLogoSize {
    case compact
    case large

    var icon: CGFloat {
        switch self {
        case .compact: return 34
        case .large: return 52
        }
    }

    var text: CGFloat {
        switch self {
        case .compact: return 25
        case .large: return 38
        }
    }
}

/// Code-native placeholder brand mark. Replace this component with the approved
/// vector asset from the company design system in the production app.
public struct BankBrandLogo: View {
    private let size: BankBrandLogoSize

    public init(size: BankBrandLogoSize = .compact) {
        self.size = size
    }

    public var body: some View {
        HStack(spacing: size.icon * 0.14) {
            ZStack {
                Circle()
                    .fill(AppColor.brand)

                VStack(spacing: size.icon * 0.055) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(Color.white)
                            .frame(
                                width: size.icon * (0.62 - CGFloat(index) * 0.035),
                                height: max(1.5, size.icon * 0.045)
                            )
                    }
                }
                .rotationEffect(.degrees(18))
            }
            .frame(width: size.icon, height: size.icon)

            Text("OCBC")
                .font(.system(size: size.text, weight: .heavy))
                .foregroundColor(AppColor.brand)
                .tracking(-1.2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("OCBC")
    }
}

public struct BankInputCard: View {
    private let title: String
    private let placeholder: String
    @Binding private var text: String
    private let isSecure: Bool
    private let keyboardType: UIKeyboardType
    @State private var revealsSecureValue = false

    public init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) {
        self.title = title
        self.placeholder = placeholder
        _text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.label)
                .foregroundColor(AppColor.primaryText)

            HStack(spacing: AppSpacing.sm) {
                Group {
                    if isSecure && !revealsSecureValue {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(AppTypography.body)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

                if isSecure {
                    Button {
                        revealsSecureValue.toggle()
                    } label: {
                        Image(systemName: revealsSecureValue ? "eye.slash" : "eye")
                            .font(.system(size: 21, weight: .medium))
                            .foregroundColor(AppColor.primaryText)
                    }
                    .accessibilityLabel(
                        revealsSecureValue ? "Sembunyikan password" : "Tampilkan password"
                    )
                }
            }
            .padding(.bottom, AppSpacing.xs)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppColor.divider)
                    .frame(height: 1)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
    }
}

public struct SecondaryButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.label)
                .foregroundColor(AppColor.brand)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColor.brand.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

public struct AppTextField: View {
    private let title: String
    private let placeholder: String
    @Binding private var text: String
    private let isSecure: Bool
    private let keyboardType: UIKeyboardType

    public init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) {
        self.title = title
        self.placeholder = placeholder
        _text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.label)
                .foregroundColor(AppColor.primaryText)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(AppTypography.body)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 52)
            .background(AppColor.elevatedSurface)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .stroke(AppColor.divider, lineWidth: 1)
            )
        }
    }
}

public struct AppCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

public struct SectionHeader: View {
    private let title: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        _ title: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.heading)
                .foregroundColor(AppColor.primaryText)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(AppTypography.label)
                    .foregroundColor(AppColor.brand)
            }
        }
    }
}

public struct ScaleButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
