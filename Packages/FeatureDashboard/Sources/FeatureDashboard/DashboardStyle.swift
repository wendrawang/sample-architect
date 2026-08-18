import DesignSystem
import Foundation
import SwiftUI

enum DashboardStyle {
    static let balanceGradient = LinearGradient(
        colors: [AppColor.brandDark, AppColor.brand, AppColor.accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let menuColumns = [
        GridItem(.flexible(), spacing: AppSpacing.sm),
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
