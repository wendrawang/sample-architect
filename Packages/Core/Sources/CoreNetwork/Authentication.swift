import Alamofire
import Foundation

public struct OAuthCredential: AuthenticationCredential, Sendable, Equatable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiration: Date?
    public let refreshLeeway: TimeInterval

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        expiration: Date? = nil,
        refreshLeeway: TimeInterval = 60
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
        self.refreshLeeway = refreshLeeway
    }

    public var requiresRefresh: Bool {
        guard let expiration else { return false }
        return expiration.timeIntervalSinceNow <= refreshLeeway
    }
}

public protocol AuthenticationFailureIdentifying: Sendable {
    func isAuthenticationFailure(response: HTTPURLResponse) -> Bool
}

public struct StatusCodeAuthenticationFailureIdentifier: AuthenticationFailureIdentifying {
    public let statusCode: Int
    public let markerHeader: String?
    public let markerValue: String?

    public init(
        statusCode: Int = 401,
        markerHeader: String? = nil,
        markerValue: String? = nil
    ) {
        self.statusCode = statusCode
        self.markerHeader = markerHeader
        self.markerValue = markerValue
    }

    public func isAuthenticationFailure(response: HTTPURLResponse) -> Bool {
        guard response.statusCode == statusCode else { return false }
        guard let markerHeader else { return true }
        guard let actualValue = response.value(forHTTPHeaderField: markerHeader) else {
            return false
        }
        guard let markerValue else { return true }
        return actualValue.caseInsensitiveCompare(markerValue) == .orderedSame
    }
}

public protocol TokenRefreshing: Sendable {
    func refresh(
        _ credential: OAuthCredential,
        using session: Session,
        completion: @escaping @Sendable (Result<OAuthCredential, any Error>) -> Void
    )
}

public struct UnavailableTokenRefresher: TokenRefreshing {
    public init() {}

    public func refresh(
        _ credential: OAuthCredential,
        using session: Session,
        completion: @escaping @Sendable (Result<OAuthCredential, any Error>) -> Void
    ) {
        completion(.failure(APIError.authentication("Token refresh belum dikonfigurasi.")))
    }
}

public final class OAuthAuthenticator: Authenticator, @unchecked Sendable {
    private let tokenRefresher: any TokenRefreshing
    private let failureIdentifier: any AuthenticationFailureIdentifying

    public init(
        tokenRefresher: any TokenRefreshing,
        failureIdentifier: any AuthenticationFailureIdentifying
    ) {
        self.tokenRefresher = tokenRefresher
        self.failureIdentifier = failureIdentifier
    }

    public func apply(_ credential: OAuthCredential, to urlRequest: inout URLRequest) {
        urlRequest.setValue(
            "Bearer \(credential.accessToken)",
            forHTTPHeaderField: "Authorization"
        )
    }

    public func refresh(
        _ credential: OAuthCredential,
        for session: Session,
        completion: @escaping @Sendable (Result<OAuthCredential, any Error>) -> Void
    ) {
        tokenRefresher.refresh(credential, using: session, completion: completion)
    }

    public func didRequest(
        _ urlRequest: URLRequest,
        with response: HTTPURLResponse,
        failDueToAuthenticationError error: any Error
    ) -> Bool {
        failureIdentifier.isAuthenticationFailure(response: response)
    }

    public func isRequest(
        _ urlRequest: URLRequest,
        authenticatedWith credential: OAuthCredential
    ) -> Bool {
        urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer \(credential.accessToken)"
    }
}

public protocol OAuthClientSecretProviding: Sendable {
    func clientID() throws -> String
    func clientSecret() throws -> String
}

public struct ClientCredentialsRefreshConfiguration: Sendable {
    public let tokenURL: URL
    public let grantType: String
    public let additionalHeaders: [String: String]

    public init(
        tokenURL: URL,
        grantType: String = "client_credentials",
        additionalHeaders: [String: String] = [:]
    ) {
        self.tokenURL = tokenURL
        self.grantType = grantType
        self.additionalHeaders = additionalHeaders
    }
}

public final class ClientCredentialsTokenRefresher: TokenRefreshing, @unchecked Sendable {
    private struct TokenResponse: Decodable, Sendable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: TimeInterval?
    }

    private let configuration: ClientCredentialsRefreshConfiguration
    private let secrets: any OAuthClientSecretProviding
    private let mtls: MTLSConfiguration
    private let onCredentialRefreshed: @Sendable (OAuthCredential) -> Void

    public init(
        configuration: ClientCredentialsRefreshConfiguration,
        secrets: any OAuthClientSecretProviding,
        mtls: MTLSConfiguration = .disabled,
        onCredentialRefreshed: @escaping @Sendable (OAuthCredential) -> Void = { _ in }
    ) {
        self.configuration = configuration
        self.secrets = secrets
        self.mtls = mtls
        self.onCredentialRefreshed = onCredentialRefreshed
    }

    public func refresh(
        _ credential: OAuthCredential,
        using session: Session,
        completion: @escaping @Sendable (Result<OAuthCredential, any Error>) -> Void
    ) {
        do {
            let clientID = try secrets.clientID()
            let clientSecret = try secrets.clientSecret()
            let basicToken = Data("\(clientID):\(clientSecret)".utf8).base64EncodedString()

            var request = URLRequest(url: configuration.tokenURL)
            request.httpMethod = APIHTTPMethod.post.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("Basic \(basicToken)", forHTTPHeaderField: "Authorization")
            configuration.additionalHeaders.forEach {
                request.setValue($0.value, forHTTPHeaderField: $0.key)
            }

            var bodyComponents = URLComponents()
            bodyComponents.queryItems = [
                URLQueryItem(name: "grant_type", value: configuration.grantType)
            ]
            request.httpBody = bodyComponents.percentEncodedQuery?.data(using: .utf8)

            let dataRequest = session.request(request)
            do {
                if let clientCredential = try mtls.credential(for: configuration.tokenURL) {
                    dataRequest.authenticate(with: clientCredential)
                }
            } catch {
                dataRequest.cancel()
                throw error
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            dataRequest
                .validate(statusCode: 200..<300)
                .responseDecodable(of: TokenResponse.self, decoder: decoder) { response in
                    switch response.result {
                    case let .success(value):
                        let refreshedCredential = OAuthCredential(
                            accessToken: value.accessToken,
                            refreshToken: value.refreshToken ?? credential.refreshToken,
                            expiration: value.expiresIn.map { Date().addingTimeInterval($0) }
                        )
                        self.onCredentialRefreshed(refreshedCredential)
                        completion(.success(refreshedCredential))
                    case let .failure(error):
                        completion(.failure(APIError.authentication(error.localizedDescription)))
                    }
                }
        } catch {
            completion(.failure(error))
        }
    }
}
