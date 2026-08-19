import Foundation

public enum APIHTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public enum APIAuthorization: Sendable {
    case none
    case bearerIfAvailable
    case bearer
}

public enum APISignatureRequirement: Sendable {
    case none
    case ifAvailable
    case required
}

public struct AnyEncodable: Encodable, Sendable {
    private let encodeValue: @Sendable (Encoder) throws -> Void

    public init<Value: Encodable & Sendable>(_ value: Value) {
        encodeValue = { encoder in
            try value.encode(to: encoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}

public struct Endpoint<Response: Decodable & Sendable>: Sendable {
    public let path: String
    public let method: APIHTTPMethod
    public let query: [String: String]
    public let headers: [String: String]
    public let body: AnyEncodable?
    public let authorization: APIAuthorization
    public let signature: APISignatureRequirement
    public let timeout: TimeInterval?

    public init(
        path: String,
        method: APIHTTPMethod = .get,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        body: AnyEncodable? = nil,
        authorization: APIAuthorization = .none,
        signature: APISignatureRequirement = .ifAvailable,
        timeout: TimeInterval? = nil
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.headers = headers
        self.body = body
        self.authorization = authorization
        self.signature = signature
        self.timeout = timeout
    }
}

public struct DownloadEndpoint: Sendable {
    public let path: String
    public let query: [String: String]
    public let headers: [String: String]
    public let authorization: APIAuthorization
    public let signature: APISignatureRequirement
    public let timeout: TimeInterval?

    public init(
        path: String,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        authorization: APIAuthorization = .bearer,
        signature: APISignatureRequirement = .ifAvailable,
        timeout: TimeInterval? = nil
    ) {
        self.path = path
        self.query = query
        self.headers = headers
        self.authorization = authorization
        self.signature = signature
        self.timeout = timeout
    }
}

public protocol APIClient: Sendable {
    func request<Response: Decodable & Sendable>(
        _ endpoint: Endpoint<Response>
    ) async throws -> Response
}

public protocol FileDownloading: Sendable {
    func download(_ endpoint: DownloadEndpoint) async throws -> URL
}
