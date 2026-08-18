import Combine
import Foundation

public enum MainTab: Int, CaseIterable {
    case dashboard
    case financial
    case qris
    case rewards
    case more
}

@MainActor
public final class MainTabViewModel: ObservableObject {
    @Published public var selection: MainTab = .dashboard

    public init() {}

    public func selectQRIS() {
        selection = .qris
    }
}

