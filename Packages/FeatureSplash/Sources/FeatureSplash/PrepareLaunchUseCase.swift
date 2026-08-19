import Foundation

public protocol PrepareLaunchUseCaseProtocol: Sendable {
    func execute() async throws -> LaunchDecision
}

public struct PrepareLaunchUseCase: PrepareLaunchUseCaseProtocol {
    private let repository: any SplashRepositoryProtocol
    private let minimumDisplayNanoseconds: UInt64

    public init(
        repository: any SplashRepositoryProtocol,
        minimumDisplayNanoseconds: UInt64 = 700_000_000
    ) {
        self.repository = repository
        self.minimumDisplayNanoseconds = minimumDisplayNanoseconds
    }

    public func execute() async throws -> LaunchDecision {
        async let minimumDisplay: Void = Task.sleep(
            nanoseconds: minimumDisplayNanoseconds
        )
        async let inquiry = repository.inquireLaunchState()

        let decision = try await inquiry
        try await minimumDisplay
        try Task.checkCancellation()
        return decision
    }
}
