import Alamofire
import CoreKit
import Foundation

public final class AlamofireAPIClient: APIClient, FileDownloading, @unchecked Sendable {
    private let baseURL: URL
    private let session: Session
    private let timeout: TimeInterval
    private let headerNames: RequestHeaderNames
    private let metadataProvider: any RequestMetadataProviding
    private let signer: any RequestSigning
    private let mtls: MTLSConfiguration
    private let tracer: any NetworkTracing
    private let authenticationFailureIdentifier: any AuthenticationFailureIdentifying
    private let authenticationInterceptor: AuthenticationInterceptor<OAuthAuthenticator>
    private let unauthorizedHandlerLock = NSLock()
    private var unauthorizedHandler: (@Sendable () -> Void)?

    public init(
        baseURL: URL,
        timeout: TimeInterval = 30,
        headerNames: RequestHeaderNames = RequestHeaderNames(),
        metadataProvider: any RequestMetadataProviding,
        signer: any RequestSigning = DisabledRequestSigner(),
        mtls: MTLSConfiguration = .disabled,
        tokenRefresher: any TokenRefreshing = UnavailableTokenRefresher(),
        authenticationFailureIdentifier: any AuthenticationFailureIdentifying = StatusCodeAuthenticationFailureIdentifier(),
        tracer: any NetworkTracing = NoOpNetworkTracer(),
        serverTrustManager: ServerTrustManager? = nil
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.headerNames = headerNames
        self.metadataProvider = metadataProvider
        self.signer = signer
        self.mtls = mtls
        self.tracer = tracer
        self.authenticationFailureIdentifier = authenticationFailureIdentifier

        let authenticator = OAuthAuthenticator(
            tokenRefresher: tokenRefresher,
            failureIdentifier: authenticationFailureIdentifier
        )
        authenticationInterceptor = AuthenticationInterceptor(
            authenticator: authenticator,
            credential: nil,
            refreshWindow: .init(interval: 30, maximumAttempts: 2)
        )

        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 2
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

        let allowedScheme = baseURL.scheme?.lowercased()
        let allowedHost = baseURL.host?.lowercased()
        let allowedPort = baseURL.port ?? (allowedScheme == "https" ? 443 : 80)
        let redirectHandler = Redirector(
            behavior: .modify { _, redirectedRequest, _ in
                guard let redirectedURL = redirectedRequest.url else { return nil }
                let redirectedScheme = redirectedURL.scheme?.lowercased()
                let redirectedHost = redirectedURL.host?.lowercased()
                let redirectedPort = redirectedURL.port
                    ?? (redirectedScheme == "https" ? 443 : 80)

                guard redirectedScheme == allowedScheme,
                      redirectedHost == allowedHost,
                      redirectedPort == allowedPort else {
                    AppLogger.security.warning("Blocked cross-origin API redirect")
                    return nil
                }
                return redirectedRequest
            }
        )

        session = Session(
            configuration: configuration,
            requestSetup: .lazy,
            serverTrustManager: serverTrustManager,
            redirectHandler: redirectHandler
        )
    }

    public func updateCredential(_ credential: OAuthCredential?) {
        authenticationInterceptor.credential = credential
    }

    public func setUnauthorizedHandler(
        _ handler: (@Sendable () -> Void)?
    ) {
        unauthorizedHandlerLock.lock()
        unauthorizedHandler = handler
        unauthorizedHandlerLock.unlock()
    }

    public func request<Response: Decodable & Sendable>(
        _ endpoint: Endpoint<Response>
    ) async throws -> Response {
        let requestID = UUID()
        let urlRequest = try makeURLRequest(
            path: endpoint.path,
            method: endpoint.method,
            query: endpoint.query,
            headers: endpoint.headers,
            body: endpoint.body,
            timeoutOverride: endpoint.timeout
        )
        guard let url = urlRequest.url else { throw APIError.invalidURL }

        let trace = tracer.start(
            context: NetworkTraceContext(
                requestID: requestID,
                method: endpoint.method.rawValue,
                url: url
            )
        )
        // Signpost names must be compile-time strings. The concrete path is
        // emitted separately through the privacy-aware network logger below.
        let interval = PerformanceTracer.begin("HTTP Request")
        AppLogger.network.debug(
            "[\(requestID.uuidString, privacy: .public)] \(endpoint.method.rawValue, privacy: .public) \(endpoint.path, privacy: .public)"
        )

        let interceptor = makeInterceptor(
            requestID: requestID,
            authorization: endpoint.authorization,
            signature: endpoint.signature
        )
        let dataRequest = session.request(urlRequest, interceptor: interceptor)

        do {
            if let credential = try mtls.credential(for: url) {
                dataRequest.authenticate(with: credential)
            }
        } catch {
            dataRequest.cancel()
            interval.end()
            trace.finish(statusCode: nil, error: error)
            throw error
        }

        let response = await dataRequest
            .validate(statusCode: 200..<300)
            .serializingData(automaticallyCancelling: true)
            .response

        interval.end()
        let statusCode = response.response?.statusCode
        trace.finish(statusCode: statusCode, error: response.error)
        AppLogger.network.debug(
            "[\(requestID.uuidString, privacy: .public)] status=\(statusCode ?? -1, privacy: .public)"
        )

        return try decode(response: response, path: endpoint.path)
    }

    public func download(_ endpoint: DownloadEndpoint) async throws -> URL {
        let requestID = UUID()
        let urlRequest = try makeURLRequest(
            path: endpoint.path,
            method: .get,
            query: endpoint.query,
            headers: endpoint.headers,
            body: nil,
            timeoutOverride: endpoint.timeout
        )
        guard let url = urlRequest.url else { throw APIError.invalidURL }

        let trace = tracer.start(
            context: NetworkTraceContext(
                requestID: requestID,
                method: APIHTTPMethod.get.rawValue,
                url: url
            )
        )
        let interval = PerformanceTracer.begin("HTTP Download")
        AppLogger.network.debug(
            "[\(requestID.uuidString, privacy: .public)] DOWNLOAD \(endpoint.path, privacy: .public)"
        )
        let destination = DownloadRequest.suggestedDownloadDestination(
            for: .cachesDirectory,
            options: [.removePreviousFile, .createIntermediateDirectories]
        )
        let interceptor = makeInterceptor(
            requestID: requestID,
            authorization: endpoint.authorization,
            signature: endpoint.signature
        )
        let request = session.download(
            urlRequest,
            interceptor: interceptor,
            to: destination
        )

        do {
            if let credential = try mtls.credential(for: url) {
                request.authenticate(with: credential)
            }
        } catch {
            request.cancel()
            interval.end()
            trace.finish(statusCode: nil, error: error)
            throw error
        }

        let response = await request
            .validate(statusCode: 200..<300)
            .serializingDownloadedFileURL(automaticallyCancelling: true)
            .response

        let statusCode = response.response?.statusCode
        interval.end()
        trace.finish(statusCode: statusCode, error: response.error)
        AppLogger.network.debug(
            "[\(requestID.uuidString, privacy: .public)] download status=\(statusCode ?? -1, privacy: .public)"
        )

        if let statusCode, !(200..<300).contains(statusCode) {
            if let httpResponse = response.response,
               authenticationFailureIdentifier.isAuthenticationFailure(
                   response: httpResponse
               ) {
                notifyUnauthorized()
                throw APIError.unauthorized
            }
            throw APIError.server(
                statusCode: statusCode,
                message: "Unduhan gagal dengan status \(statusCode)."
            )
        }
        if let error = response.error {
            throw mapTransport(error)
        }
        guard let fileURL = response.value else {
            throw APIError.emptyDownload
        }
        return fileURL
    }

    private func makeURLRequest(
        path: String,
        method: APIHTTPMethod,
        query: [String: String],
        headers: [String: String],
        body: AnyEncodable?,
        timeoutOverride: TimeInterval?
    ) throws -> URLRequest {
        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = baseURL.appendingPathComponent(cleanPath)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        if !query.isEmpty {
            components?.queryItems = query
                .sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let finalURL = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutOverride ?? timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try makeEncoder().encode(body)
        }

        return request
    }

    private func makeInterceptor(
        requestID: UUID,
        authorization: APIAuthorization,
        signature: APISignatureRequirement
    ) -> Interceptor {
        let headerAdapter = RequestHeaderAdapter(
            requestID: requestID,
            signatureRequirement: signature,
            headerNames: headerNames,
            metadataProvider: metadataProvider,
            signer: signer
        )

        switch authorization {
        case .none:
            return Interceptor(adapters: [headerAdapter])
        case .bearerIfAvailable where authenticationInterceptor.credential == nil:
            return Interceptor(adapters: [headerAdapter])
        case .bearerIfAvailable, .bearer:
            // Optional bearer reaches this branch only when a credential is
            // available; required bearer fails fast through the interceptor.
            // Auth runs before signing. A retry reruns both adapters so a new
            // token always receives a fresh timestamp and signature.
            return Interceptor(
                adapters: [authenticationInterceptor, headerAdapter],
                retriers: [authenticationInterceptor]
            )
        }
    }

    private func decode<Response: Decodable & Sendable>(
        response: DataResponse<Data, AFError>,
        path: String
    ) throws -> Response {
        let statusCode = response.response?.statusCode
        let data = response.data ?? Data()

        if let statusCode, !(200..<300).contains(statusCode) {
            if let httpResponse = response.response,
               authenticationFailureIdentifier.isAuthenticationFailure(
                   response: httpResponse
               ) {
                notifyUnauthorized()
                throw APIError.unauthorized
            }
            let payload = try? makeDecoder().decode(ServerErrorPayload.self, from: data)
            throw APIError.server(
                statusCode: statusCode,
                message: payload?.message ?? "Terjadi kesalahan pada layanan."
            )
        }

        if let error = response.error {
            throw mapTransport(error)
        }
        guard statusCode != nil else {
            throw APIError.transport("Layanan tidak memberikan respons.")
        }

        do {
            return try makeDecoder().decode(Response.self, from: data)
        } catch {
            AppLogger.network.error(
                "Decode failed for \(path, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            throw APIError.decoding(error.localizedDescription)
        }
    }

    private func mapTransport(_ error: AFError) -> APIError {
        if error.isExplicitlyCancelledError {
            return .cancelled
        }
        if case let .requestRetryFailed(retryError, _) = error {
            if retryError is AuthenticationError {
                notifyUnauthorized()
                return .unauthorized
            }
            if let apiError = retryError as? APIError {
                return apiError
            }
            return .authentication(retryError.localizedDescription)
        }
        if case let .requestAdaptationFailed(innerError) = error {
            if innerError is AuthenticationError {
                notifyUnauthorized()
                return .unauthorized
            }
            if let apiError = innerError as? APIError {
                return apiError
            }
            return .authentication(innerError.localizedDescription)
        }
        return .transport(error.localizedDescription)
    }

    private func notifyUnauthorized() {
        unauthorizedHandlerLock.lock()
        let handler = unauthorizedHandler
        unauthorizedHandlerLock.unlock()
        handler?()
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        // Stable key ordering matters when the raw body participates in a
        // company request-signing algorithm.
        encoder.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        return encoder
    }
}
