import Alamofire
import Foundation

public struct RequestHeaderNames: Sendable {
    public let requestID: String
    public let platform: String
    public let appVersion: String
    public let language: String
    public let sessionID: String
    public let channel: String
    public let signature: String
    public let timestamp: String
    public let apiKey: String

    public init(
        requestID: String = "X-Request-ID",
        platform: String = "X-Platform",
        appVersion: String = "X-App-Version",
        language: String = "Accept-Language",
        sessionID: String = "X-Session-ID",
        channel: String = "X-Channel",
        signature: String = "X-Signature",
        timestamp: String = "X-Timestamp",
        apiKey: String = "X-API-Key"
    ) {
        self.requestID = requestID
        self.platform = platform
        self.appVersion = appVersion
        self.language = language
        self.sessionID = sessionID
        self.channel = channel
        self.signature = signature
        self.timestamp = timestamp
        self.apiKey = apiKey
    }
}

public struct RequestMetadata: Sendable {
    public let platform: String
    public let appVersion: String
    public let language: String
    public let sessionID: String?
    public let channel: String?
    public let apiKey: String?

    public init(
        platform: String = "iOS",
        appVersion: String,
        language: String,
        sessionID: String? = nil,
        channel: String? = nil,
        apiKey: String? = nil
    ) {
        self.platform = platform
        self.appVersion = appVersion
        self.language = language
        self.sessionID = sessionID
        self.channel = channel
        self.apiKey = apiKey
    }
}

public protocol RequestMetadataProviding: Sendable {
    func metadata() -> RequestMetadata
}

public final class ClosureRequestMetadataProvider: RequestMetadataProviding, @unchecked Sendable {
    private let provider: @Sendable () -> RequestMetadata

    public init(provider: @escaping @Sendable () -> RequestMetadata) {
        self.provider = provider
    }

    public func metadata() -> RequestMetadata {
        provider()
    }
}

public struct RequestSigningInput: Sendable {
    public let requestID: UUID
    public let method: String
    public let url: URL
    public let headers: [String: String]
    public let body: Data?
    public let timestamp: String

    public init(
        requestID: UUID,
        method: String,
        url: URL,
        headers: [String: String],
        body: Data?,
        timestamp: String
    ) {
        self.requestID = requestID
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.timestamp = timestamp
    }
}

public protocol RequestSigning: Sendable {
    func signature(for input: RequestSigningInput) throws -> String?
}

public struct DisabledRequestSigner: RequestSigning {
    public init() {}

    public func signature(for input: RequestSigningInput) throws -> String? {
        nil
    }
}

/// Adapter point for the company's proprietary signing algorithm. The closure
/// receives canonical request data, never values read from a committed secret.
public final class ClosureRequestSigner: RequestSigning, @unchecked Sendable {
    private let signer: @Sendable (RequestSigningInput) throws -> String?

    public init(
        signer: @escaping @Sendable (RequestSigningInput) throws -> String?
    ) {
        self.signer = signer
    }

    public func signature(for input: RequestSigningInput) throws -> String? {
        try signer(input)
    }
}

final class RequestHeaderAdapter: RequestAdapter, @unchecked Sendable {
    private let requestID: UUID
    private let signatureRequirement: APISignatureRequirement
    private let headerNames: RequestHeaderNames
    private let metadataProvider: any RequestMetadataProviding
    private let signer: any RequestSigning

    init(
        requestID: UUID,
        signatureRequirement: APISignatureRequirement,
        headerNames: RequestHeaderNames,
        metadataProvider: any RequestMetadataProviding,
        signer: any RequestSigning
    ) {
        self.requestID = requestID
        self.signatureRequirement = signatureRequirement
        self.headerNames = headerNames
        self.metadataProvider = metadataProvider
        self.signer = signer
    }

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void
    ) {
        do {
            var request = urlRequest
            let metadata = metadataProvider.metadata()
            let timestamp = ISO8601DateFormatter().string(from: Date())

            request.setValue(requestID.uuidString, forHTTPHeaderField: headerNames.requestID)
            request.setValue(metadata.platform, forHTTPHeaderField: headerNames.platform)
            request.setValue(metadata.appVersion, forHTTPHeaderField: headerNames.appVersion)
            request.setValue(metadata.language.uppercased(), forHTTPHeaderField: headerNames.language)
            set(metadata.sessionID, for: headerNames.sessionID, on: &request)
            set(metadata.channel, for: headerNames.channel, on: &request)
            set(metadata.apiKey, for: headerNames.apiKey, on: &request)

            guard signatureRequirement != .none else {
                completion(.success(request))
                return
            }
            guard let url = request.url else {
                completion(.failure(APIError.invalidURL))
                return
            }

            let input = RequestSigningInput(
                requestID: requestID,
                method: request.httpMethod ?? APIHTTPMethod.get.rawValue,
                url: url,
                headers: request.allHTTPHeaderFields ?? [:],
                body: request.httpBody,
                timestamp: timestamp
            )
            let signature = try signer.signature(for: input)

            if let signature, !signature.isEmpty {
                request.setValue(signature, forHTTPHeaderField: headerNames.signature)
                request.setValue(timestamp, forHTTPHeaderField: headerNames.timestamp)
            } else if signatureRequirement == .required {
                completion(.failure(APIError.signatureUnavailable))
                return
            }

            completion(.success(request))
        } catch let error as APIError {
            completion(.failure(error))
        } catch {
            completion(.failure(APIError.signatureUnavailable))
        }
    }

    private func set(_ value: String?, for field: String, on request: inout URLRequest) {
        guard let value, !value.isEmpty else { return }
        request.setValue(value, forHTTPHeaderField: field)
    }
}
