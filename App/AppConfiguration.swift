import CoreGuards
import Foundation

struct AppConfiguration {
    let apiBaseURL: URL
    let useMockServices: Bool
    let showFPS: Bool

    static func load(bundle: Bundle = .main) -> AppConfiguration {
        let rawURL = bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        let baseURL = rawURL.flatMap(URL.init(string:)) ?? URL(string: "https://api.example.com")!
        let infoUsesMocks = (bundle.object(forInfoDictionaryKey: "USE_MOCK_SERVICES") as? NSNumber)?.boolValue ?? true
        let arguments = ProcessInfo.processInfo.arguments

        return AppConfiguration(
            apiBaseURL: baseURL,
            useMockServices: arguments.contains("-useLiveServices") ? false : infoUsesMocks,
            showFPS: arguments.contains("-showFPS")
        )
    }
}

struct LaunchArgumentDeviceIntegrityChecker: DeviceIntegrityChecking {
    func evaluate() -> DeviceIntegrityStatus {
        ProcessInfo.processInfo.arguments.contains("-simulateRootedDevice")
            ? .compromised
            : .trusted
    }
}

