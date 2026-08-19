import Combine
import CoreKit
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
    private let lifecycleProbe = LifecycleProbe("MainTabViewModel")

    public init() {}

    public func selectQRIS() {
        selection = .qris
    }
}
