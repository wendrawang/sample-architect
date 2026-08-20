import Combine
import CoreKit
import Foundation

/// Owns the navigation path of exactly one flow.
///
/// The path stores value routes only — never a View, ViewModel, or controller — so
/// a pushed screen is released as soon as SwiftUI removes it from the stack. Nothing
/// here retains what it navigates to, which is what keeps the flow leak-free by
/// construction rather than by discipline.
@MainActor
public final class NavigationRouter<Route: Hashable>: ObservableObject {
    @Published public var path: [Route] = [] {
        didSet { logTransition(from: oldValue, to: path) }
    }

    private let label: String
    private let rootScreen: String
    private let lifecycleProbe: LifecycleProbe

    /// - Parameter rootScreen: nama layar dasar flow ini, dipakai saat path kembali kosong
    ///   sehingga screen view tetap tercatat ketika pengguna menekan Back.
    public init(rootScreen: String) {
        let name = String(describing: Route.self)
        label = name
        self.rootScreen = rootScreen
        lifecycleProbe = LifecycleProbe("NavigationRouter<\(name)>")
    }

    public var isAtRoot: Bool { path.isEmpty }

    public var current: Route? { path.last }

    public func push(_ route: Route) {
        path.append(route)
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func popToRoot() {
        guard !path.isEmpty else { return }
        path.removeAll()
    }

    /// Logs every path change, including the ones SwiftUI makes itself on a Back tap or
    /// interactive-pop swipe. Pair a `POP` line with the `DEINIT` line that `LifecycleProbe`
    /// prints: a pop without its matching deinit is the signature of a retained screen.
    private func logTransition(from oldPath: [Route], to newPath: [Route]) {
        guard oldPath.count != newPath.count else { return }
        let verb = newPath.count > oldPath.count ? "PUSH" : "POP"
        AppLogger.navigation.debug(
            "\(verb, privacy: .public) \(self.label, privacy: .public) depth \(oldPath.count, privacy: .public) -> \(newPath.count, privacy: .public)"
        )

        let visible = newPath.last.map { String(describing: $0) } ?? rootScreen
        ScreenTracker.track(visible)
    }
}
