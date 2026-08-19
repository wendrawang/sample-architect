import DesignSystem
import SwiftUI

enum UsernameStyle {
    static let heroHeight: CGFloat = 330
    static let heroGradient = LinearGradient(
        colors: [Color.white, AppColor.surface],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let menuColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
}
