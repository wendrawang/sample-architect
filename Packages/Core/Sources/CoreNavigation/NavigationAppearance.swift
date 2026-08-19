import UIKit

/// `NavigationStack` renders through `UINavigationBar` on iOS, so the UIKit appearance
/// proxy is still the one place that styles every bar in the app.
public enum NavigationAppearance {
    @MainActor
    public static func applyGlobalStyle() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0.91, green: 0.03, blue: 0.08, alpha: 1)
    }
}
