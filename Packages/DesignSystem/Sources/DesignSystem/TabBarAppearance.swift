import SwiftUI
import UIKit

public enum AppTabBarAppearance {
    @MainActor
    public static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.25)

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        UITabBar.appearance().tintColor = UIColor(red: 0.08, green: 0.31, blue: 0.78, alpha: 1)
        UITabBar.appearance().unselectedItemTintColor = .secondaryLabel
    }
}

