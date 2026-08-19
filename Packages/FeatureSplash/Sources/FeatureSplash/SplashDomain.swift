import Foundation

public enum LaunchDestination: String, Equatable, Sendable {
    case preLogin
    case main
    case maintenance
    case forceUpdate
}

public struct LaunchDecision: Equatable, Sendable {
    public let destination: LaunchDestination
    public let message: String?

    public init(destination: LaunchDestination, message: String? = nil) {
        self.destination = destination
        self.message = message
    }
}

public protocol SplashRepositoryProtocol: Sendable {
    func inquireLaunchState() async throws -> LaunchDecision
}

public enum MockSplashError: Error, LocalizedError, Sendable {
    case simulated

    public var errorDescription: String? {
        "Inquiry splash gagal untuk simulasi."
    }
}
