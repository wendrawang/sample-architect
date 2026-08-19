import Foundation

public struct SampleFeatureContent: Equatable, Sendable {
    public let title: String
    public let message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}

public protocol SampleFeatureRepositoryProtocol: Sendable {
    func loadContent() async throws -> SampleFeatureContent
}

public enum SampleFeatureError: Error, LocalizedError, Equatable, Sendable {
    case emptyContent

    public var errorDescription: String? {
        "Konten feature tidak tersedia."
    }
}
