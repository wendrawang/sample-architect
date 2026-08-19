import CoreGuards
import Foundation

struct AppConfiguration: Sendable {
    let apiBaseURL: URL
    let useMockServices: Bool
    let showFPS: Bool
    let mtlsEnabled: Bool
    let mtlsCertificateName: String
    let oauthTokenPath: String
    let splashInquiryPath: String
    let apiChannel: String
    let authFailureHeader: String?
    let authFailureValue: String?
    let appStoreURL: URL?

    static func load(bundle: Bundle = .main) -> AppConfiguration {
        let rawURL = bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        let baseURL = rawURL.flatMap(URL.init(string:)) ?? URL(string: "https://api.example.com")!
        let infoUsesMocks = (bundle.object(forInfoDictionaryKey: "USE_MOCK_SERVICES") as? NSNumber)?.boolValue ?? true
        let arguments = ProcessInfo.processInfo.arguments
        let mtlsEnabled = (bundle.object(forInfoDictionaryKey: "MTLS_ENABLED") as? NSNumber)?.boolValue ?? false

        return AppConfiguration(
            apiBaseURL: baseURL,
            useMockServices: arguments.contains("-useLiveServices") ? false : infoUsesMocks,
            showFPS: arguments.contains("-showFPS"),
            mtlsEnabled: mtlsEnabled,
            mtlsCertificateName: bundle.string(forInfoKey: "MTLS_CERTIFICATE_NAME"),
            oauthTokenPath: bundle.string(forInfoKey: "OAUTH_TOKEN_PATH", fallback: "/oauth2/token"),
            splashInquiryPath: bundle.string(forInfoKey: "SPLASH_INQUIRY_PATH", fallback: "/v1/app/bootstrap"),
            apiChannel: bundle.string(forInfoKey: "API_CHANNEL", fallback: "mobile"),
            authFailureHeader: bundle.nonEmptyString(forInfoKey: "AUTH_FAILURE_HEADER"),
            authFailureValue: bundle.nonEmptyString(forInfoKey: "AUTH_FAILURE_VALUE"),
            appStoreURL: bundle.nonEmptyString(forInfoKey: "APP_STORE_URL").flatMap(URL.init(string:))
        )
    }
}

private extension Bundle {
    func string(forInfoKey key: String, fallback: String = "") -> String {
        (object(forInfoDictionaryKey: key) as? String) ?? fallback
    }

    func nonEmptyString(forInfoKey key: String) -> String? {
        let value = string(forInfoKey: key).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

struct LaunchArgumentDeviceIntegrityChecker: DeviceIntegrityChecking {
    func evaluate() -> DeviceIntegrityStatus {
        ProcessInfo.processInfo.arguments.contains("-simulateRootedDevice")
            ? .compromised
            : .trusted
    }
}
