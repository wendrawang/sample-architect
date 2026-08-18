import Foundation

/// In-memory session only. Replace or extend with the company's secure storage abstraction.
final class AppSessionStore {
    private let lock = NSLock()
    private var accessToken: String?

    func save(accessToken: String) {
        lock.lock()
        self.accessToken = accessToken
        lock.unlock()
    }

    func clear() {
        lock.lock()
        accessToken = nil
        lock.unlock()
    }

    func authorizationHeaders() -> [String: String] {
        lock.lock()
        defer { lock.unlock() }
        guard let accessToken else { return [:] }
        return ["Authorization": "Bearer \(accessToken)"]
    }
}

