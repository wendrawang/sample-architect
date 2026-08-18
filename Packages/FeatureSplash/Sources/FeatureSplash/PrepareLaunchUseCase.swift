import Foundation

public protocol PrepareLaunchUseCaseProtocol {
    func execute() async
}

public struct PrepareLaunchUseCase: PrepareLaunchUseCaseProtocol {
    private let minimumDisplayNanoseconds: UInt64

    public init(minimumDisplayNanoseconds: UInt64 = 700_000_000) {
        self.minimumDisplayNanoseconds = minimumDisplayNanoseconds
    }

    public func execute() async {
        try? await Task.sleep(nanoseconds: minimumDisplayNanoseconds)
    }
}

