import DesignSystem
import SwiftUI

enum MainTabStyle {
    static let centerButtonSize: CGFloat = 68
    static let centerButtonBottomPadding: CGFloat = 22
    static let centerButtonGradient = LinearGradient(
        colors: [AppColor.brandDark, AppColor.brand],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
