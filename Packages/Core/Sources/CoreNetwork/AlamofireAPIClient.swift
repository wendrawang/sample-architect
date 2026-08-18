import Alamofire
import CoreKit
import Foundation

public final class AlamofireAPIClient: APIClient {
    private let baseURL: URL
    private let session: Session
    private let defaultHeaders: () -> [String: String]

    public init(
        baseURL: URL,
        timeout: TimeInterval = 30,
        defaultHeaders: @escaping () -> [String: String] = { [:] }
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders

        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 2
        configuration.waitsForConnectivity = true
        session = Session(configuration: configuration)
    }

    public func request<Response: Decodable>(
        _ endpoint: Endpoint<Response>
    ) async throws -> Response {
        let interval = PerformanceTracer.begin("HTTP Request")
        defer { interval.end() }

        let request = try makeURLRequest(for: endpoint)
        AppLogger.network.debug("\(endpoint.method.rawValue, privacy: .public) \(endpoint.path, privacy: .public)")

        let response = await session
            .request(request)
            .serializingData()
            .response

        if let error = response.error {
            if case .explicitlyCancelled = error {
                throw APIError.cancelled
            }
            throw APIError.transport(error.localizedDescription)
        }

        guard let statusCode = response.response?.statusCode else {
            throw APIError.transport("Layanan tidak memberikan respons.")
        }

        let data = response.data ?? Data()
        guard (200..<300).contains(statusCode) else {
            if statusCode == 401 {
                throw APIError.unauthorized
            }

            let payload = try? makeDecoder().decode(ServerErrorPayload.self, from: data)
            throw APIError.server(
                statusCode: statusCode,
                message: payload?.message ?? "Terjadi kesalahan pada layanan."
            )
        }

        do {
            return try makeDecoder().decode(Response.self, from: data)
        } catch {
            AppLogger.network.error("Decode failed for \(endpoint.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw APIError.decoding(error.localizedDescription)
        }
    }

    private func makeURLRequest<Response: Decodable>(
        for endpoint: Endpoint<Response>
    ) throws -> URLRequest {
        let cleanPath = endpoint.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = baseURL.appendingPathComponent(cleanPath)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        if !endpoint.query.isEmpty {
            components?.queryItems = endpoint.query
                .sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let finalURL = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var headers = defaultHeaders()
        endpoint.headers.forEach { headers[$0.key] = $0.value }
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        if let body = endpoint.body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try makeEncoder().encode(body)
        }

        return request
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
        return encoder
    }
}
