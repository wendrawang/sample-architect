import Foundation

/// Attach one probe to every long-lived reference type (ViewModel, UseCase, Coordinator).
/// It deliberately owns nothing outside its immutable label.
public final class LifecycleProbe {
    private let label: String
    private let identifier = String(UUID().uuidString.prefix(6))

    public init(_ label: String) {
        self.label = label
        AppLogger.lifecycle.debug("INIT \(label, privacy: .public) [\(self.identifier, privacy: .public)]")
    }

    deinit {
        AppLogger.lifecycle.debug("DEINIT \(label, privacy: .public) [\(self.identifier, privacy: .public)]")
    }
}
