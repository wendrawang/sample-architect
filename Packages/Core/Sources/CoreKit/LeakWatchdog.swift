import Foundation

private final class WeakReference {
    weak var value: AnyObject?

    init(_ value: AnyObject) {
        self.value = value
    }
}

public enum LeakWatchdog {
    /// Call after removing the last expected owner, for example after a flow finishes.
    /// Set launch argument `-assertLeaks` to turn the warning into a DEBUG assertion.
    public static func expectDeallocation(
        of object: AnyObject,
        named name: String,
        after delay: TimeInterval = 5
    ) {
        #if DEBUG
        let reference = WeakReference(object)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard reference.value != nil else { return }

            AppLogger.lifecycle.error("POSSIBLE LEAK: \(name, privacy: .public) still alive after \(delay, privacy: .public)s")

            if ProcessInfo.processInfo.arguments.contains("-assertLeaks") {
                assertionFailure("Possible leak: \(name)")
            }
        }
        #else
        _ = object
        _ = name
        _ = delay
        #endif
    }
}

