import Foundation

public protocol SampleFeatureUseCaseProtocol {
    func execute() async throws -> String
}

public struct SampleFeatureUseCase: SampleFeatureUseCaseProtocol {
    public init() {}

    public func execute() async throws -> String {
        "Result from business logic"
    }
}

