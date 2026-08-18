import Foundation

public enum APIHTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void

    public init<Value: Encodable>(_ value: Value) {
        encodeValue = value.encode
    }

    public func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}

public struct Endpoint<Response: Decodable> {
    public let path: String
    public let method: APIHTTPMethod
    public let query: [String: String]
    public let headers: [String: String]
    public let body: AnyEncodable?

    public init(
        path: String,
        method: APIHTTPMethod = .get,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        body: AnyEncodable? = nil
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.headers = headers
        self.body = body
    }
}

public protocol APIClient {
    func request<Response: Decodable>(_ endpoint: Endpoint<Response>) async throws -> Response
}

