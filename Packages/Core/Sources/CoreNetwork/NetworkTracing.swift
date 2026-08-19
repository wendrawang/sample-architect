import Foundation

public struct NetworkTraceContext: Sendable {
    public let requestID: UUID
    public let method: String
    public let url: URL

    public init(requestID: UUID, method: String, url: URL) {
        self.requestID = requestID
        self.method = method
        self.url = url
    }
}

public protocol NetworkTrace: AnyObject, Sendable {
    func finish(statusCode: Int?, error: Error?)
}

public protocol NetworkTracing: Sendable {
    func start(context: NetworkTraceContext) -> any NetworkTrace
}

private final class EmptyNetworkTrace: NetworkTrace, @unchecked Sendable {
    func finish(statusCode: Int?, error: Error?) {}
}

public struct NoOpNetworkTracer: NetworkTracing {
    public init() {}

    public func start(context: NetworkTraceContext) -> any NetworkTrace {
        EmptyNetworkTrace()
    }
}

public final class ClosureNetworkTracer: NetworkTracing, @unchecked Sendable {
    private let startHandler: @Sendable (NetworkTraceContext) -> any NetworkTrace

    public init(
        startHandler: @escaping @Sendable (NetworkTraceContext) -> any NetworkTrace
    ) {
        self.startHandler = startHandler
    }

    public func start(context: NetworkTraceContext) -> any NetworkTrace {
        startHandler(context)
    }
}
