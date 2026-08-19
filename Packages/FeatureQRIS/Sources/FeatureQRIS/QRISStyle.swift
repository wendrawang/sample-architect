import DesignSystem
import SwiftUI

enum QRISStyle {
    static let scanArea: CGFloat = 230
    static let cornerLength: CGFloat = 42
    static let background = LinearGradient(
        colors: [Color.black, AppColor.brandDark],
        startPoint: .top,
        endPoint: .bottom
    )
}

