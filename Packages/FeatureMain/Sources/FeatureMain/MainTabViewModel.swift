import Combine
import CoreKit
import CoreNavigation
import Foundation

public enum MainTab: Int, CaseIterable, Sendable {
    case dashboard
    case financial
    case qris
    case rewards
    case more

    /// Segmen pertama URL menentukan tab. Tidak dikenali berarti tetap di Beranda.
    public static func tab(for link: DeepLink) -> MainTab {
        switch link.root {
        case "financial": return .financial
        case "qris":      return .qris
        case "rewards":   return .rewards
        case "more":      return .more
        default:          return .dashboard
        }
    }
}

@MainActor
public final class MainTabViewModel: ObservableObject {
    @Published public var selection: MainTab = .dashboard
    private let lifecycleProbe = LifecycleProbe("MainTabViewModel")

    public init(initialTab: MainTab = .dashboard) {
        selection = initialTab
    }

    public func selectQRIS() {
        selection = .qris
    }
}
