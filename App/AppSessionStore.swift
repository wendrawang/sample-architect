import CoreNetwork
import Foundation

/// In-memory session only. Replace or extend with the company's secure storage abstraction.
final class AppSessionStore: @unchecked Sendable {
    private let lock = NSLock()
    private var credential: OAuthCredential?
    private var sessionID: String?

    init(initialCredential: OAuthCredential? = nil) {
        credential = initialCredential
        sessionID = initialCredential == nil ? nil : UUID().uuidString
    }

    func save(credential: OAuthCredential) {
        lock.lock()
        self.credential = credential
        sessionID = UUID().uuidString
        lock.unlock()
    }

    /// Refresh must replace only the token material and preserve the logical
    /// app session ID used by downstream headers and tracing.
    func updateCredential(_ credential: OAuthCredential) {
        lock.lock()
        self.credential = credential
        lock.unlock()
    }

    func clear() {
        lock.lock()
        credential = nil
        sessionID = nil
        lock.unlock()
    }

    func currentCredential() -> OAuthCredential? {
        lock.lock()
        defer { lock.unlock() }
        return credential
    }

    func currentSessionID() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return sessionID
    }
}
