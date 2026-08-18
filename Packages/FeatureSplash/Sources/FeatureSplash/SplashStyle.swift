import DesignSystem
import SwiftUI

enum SplashStyle {
    static let logoSize: CGFloat = 88
    static let background = LinearGradient(
        colors: [AppColor.brandDark, AppColor.brand],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

