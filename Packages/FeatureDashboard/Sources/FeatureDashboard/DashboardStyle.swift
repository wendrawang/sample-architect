import DesignSystem
import Foundation
import SwiftUI

enum DashboardStyle {
    static let heroHeight: CGFloat = 310
    static let heroGradient = LinearGradient(
        colors: [Color.white, Color(red: 0.92, green: 0.94, blue: 0.98)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let menuColumns = [
        GridItem(.flexible(), spacing: AppSpacing.sm),
        GridItem(.flexible(), spacing: AppSpacing.sm),
        GridItem(.flexible(), spacing: AppSpacing.sm)
    ]
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}
