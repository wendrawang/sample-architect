import Foundation
import os

public enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "ModularBank"

    public static let app = Logger(subsystem: subsystem, category: "app")
    public static let navigation = Logger(subsystem: subsystem, category: "navigation")
    public static let network = Logger(subsystem: subsystem, category: "network")
    public static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    public static let performance = Logger(subsystem: subsystem, category: "performance")
    public static let security = Logger(subsystem: subsystem, category: "security")
}

