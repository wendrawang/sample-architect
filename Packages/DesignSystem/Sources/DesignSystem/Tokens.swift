import SwiftUI
import UIKit

public enum AppColor {
    public static let brand = Color(red: 0.91, green: 0.03, blue: 0.08)
    public static let brandDark = Color(red: 0.65, green: 0.00, blue: 0.04)
    public static let accent = Color(red: 0.00, green: 0.42, blue: 0.78)
    public static let charcoal = Color(red: 0.23, green: 0.31, blue: 0.34)
    public static let success = Color(red: 0.10, green: 0.58, blue: 0.36)
    public static let warning = Color(red: 0.94, green: 0.56, blue: 0.11)
    public static let danger = Color(red: 0.82, green: 0.16, blue: 0.20)
    public static let background = Color(uiColor: .systemBackground)
    public static let surface = Color(red: 0.97, green: 0.97, blue: 0.98)
    public static let elevatedSurface = Color(uiColor: .systemBackground)
    public static let primaryText = Color(uiColor: .label)
    public static let secondaryText = Color(uiColor: .secondaryLabel)
    public static let divider = Color(uiColor: .separator).opacity(0.5)
}

public enum AppSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
}

public enum AppRadius {
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 14
    public static let large: CGFloat = 22
    public static let capsule: CGFloat = 999
}

public enum AppTypography {
    public static let hero = Font.system(size: 32, weight: .bold)
    public static let title = Font.system(size: 24, weight: .bold)
    public static let heading = Font.system(size: 18, weight: .semibold)
    public static let body = Font.system(size: 16, weight: .regular)
    public static let label = Font.system(size: 14, weight: .semibold)
    public static let caption = Font.system(size: 12, weight: .regular)
}
