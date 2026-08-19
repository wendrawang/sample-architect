import Foundation

public enum APIError: Error, LocalizedError, Equatable, Sendable {
    case invalidURL
    case transport(String)
    case unauthorized
    case authentication(String)
    case server(statusCode: Int, message: String)
    case decoding(String)
    case clientCertificateUnavailable
    case clientCertificateInvalid(String)
    case clientCertificateHostNotAllowed
    case insecureMTLSTransport
    case signatureUnavailable
    case emptyDownload
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Alamat layanan tidak valid."
        case let .transport(message):
            return message
        case .unauthorized:
            return "Sesi berakhir. Silakan masuk kembali."
        case let .authentication(message):
            return message
        case let .server(_, message):
            return message
        case .decoding:
            return "Respons layanan tidak dapat dibaca."
        case .clientCertificateUnavailable:
            return "Sertifikat perangkat tidak tersedia."
        case .clientCertificateInvalid:
            return "Sertifikat perangkat tidak dapat digunakan."
        case .clientCertificateHostNotAllowed:
            return "Host layanan tidak diizinkan untuk konfigurasi mTLS ini."
        case .insecureMTLSTransport:
            return "mTLS hanya dapat digunakan melalui koneksi HTTPS."
        case .signatureUnavailable:
            return "Request signature tidak tersedia."
        case .emptyDownload:
            return "File hasil unduhan tidak tersedia."
        case .cancelled:
            return "Permintaan dibatalkan."
        }
    }
}

struct ServerErrorPayload: Decodable, Sendable {
    let code: String?
    let message: String?
}
