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


/// Apa yang feature ini butuhkan dari luar. Composition root yang memenuhinya.
///
/// Bentuk factory, bukan property, supaya repository baru dibangun ketika layar dibuka —
/// bukan sekaligus di awal untuk layar yang mungkin tidak pernah dibuka.
public protocol SampleFeatureDependencies: Sendable {
    func makeSampleFeatureRepository() -> any SampleFeatureRepositoryProtocol
}
