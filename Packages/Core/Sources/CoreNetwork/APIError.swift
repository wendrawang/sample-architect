import Foundation

public enum APIError: Error, LocalizedError, Equatable {
    case invalidURL
    case transport(String)
    case unauthorized
    case server(statusCode: Int, message: String)
    case decoding(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Alamat layanan tidak valid."
        case let .transport(message):
            return message
        case .unauthorized:
            return "Sesi berakhir. Silakan masuk kembali."
        case let .server(_, message):
            return message
        case .decoding:
            return "Respons layanan tidak dapat dibaca."
        case .cancelled:
            return "Permintaan dibatalkan."
        }
    }
}

struct ServerErrorPayload: Decodable {
    let message: String?
}

