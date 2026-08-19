import DesignSystem
import SwiftUI

enum FinancialStyle {
    static let portfolioGradient = LinearGradient(
        colors: [Color(red: 0.19, green: 0.12, blue: 0.48), AppColor.brand],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let iconSize: CGFloat = 44
}

