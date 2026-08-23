import Combine
import Foundation
import QuartzCore
import os.signpost

public final class PerformanceInterval: @unchecked Sendable {
    private let log: OSLog
    private let identifier: OSSignpostID
    private let name: StaticString
    private let lock = NSLock()
    private var isEnded = false

    fileprivate init(log: OSLog, identifier: OSSignpostID, name: StaticString) {
        self.log = log
        self.identifier = identifier
        self.name = name
        os_signpost(.begin, log: log, name: name, signpostID: identifier)
    }

    public func end() {
        lock.lock()
        defer { lock.unlock() }
        guard !isEnded else { return }
        isEnded = true
        os_signpost(.end, log: log, name: name, signpostID: identifier)
    }

    deinit {
        end()
    }
}

public enum PerformanceTracer {
    private static let log = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "ModularBank",
        category: .pointsOfInterest
    )

    public static func begin(_ name: StaticString) -> PerformanceInterval {
        PerformanceInterval(
            log: log,
            identifier: OSSignpostID(log: log),
            name: name
        )
    }
}

@MainActor
private final class DisplayLinkProxy: NSObject {
    weak var owner: FrameRateMonitor?

    @objc func tick(_ displayLink: CADisplayLink) {
        owner?.tick(displayLink)
    }
}

/// Ambang yang dianggap "masih 60 fps".
///
/// 60 Hz memberi anggaran 16,67 ms per frame. Rata-rata FPS saja menyesatkan — satu frame
/// yang molor 300 ms terasa jelas oleh pengguna tetapi hampir tidak menggeser rata-rata.
/// Karena itu hitch dihitung terpisah.
public struct PerformanceBudget: Sendable {
    public let minimumFPS: Int
    public let maximumHitchesPerWindow: Int

    public init(minimumFPS: Int, maximumHitchesPerWindow: Int) {
        self.minimumFPS = minimumFPS
        self.maximumHitchesPerWindow = maximumHitchesPerWindow
    }

    /// Default: turun di bawah 55 fps, atau lebih dari dua frame molor dalam satu detik,
    /// dihitung sebagai pelanggaran.
    public static let sixtyFPS = PerformanceBudget(minimumFPS: 55, maximumHitchesPerWindow: 2)
}

@MainActor
public final class FrameRateMonitor: ObservableObject {
    @Published public private(set) var framesPerSecond: Int = 0
    @Published public private(set) var hitchCount: Int = 0
    /// Berapa kali anggaran dilanggar sejak monitor dijalankan. Ditampilkan pada badge
    /// supaya QA bisa melihatnya tanpa membuka Console.
    @Published public private(set) var budgetViolations: Int = 0

    private let budget: PerformanceBudget
    private let assertsOnViolation: Bool
    private var hitchesInWindow = 0

    private let proxy = DisplayLinkProxy()
    /// `deinit` is nonisolated, so it cannot read a main-actor-isolated property of a
    /// non-Sendable type. Deinit only runs once the last reference is gone and nothing else
    /// can touch the link, so opting this one property out of isolation is safe.
    private nonisolated(unsafe) var displayLink: CADisplayLink?
    private var frameCount = 0
    private var windowStart: CFTimeInterval = 0
    private var previousTimestamp: CFTimeInterval = 0

    /// - Parameter budget: ambang yang dianggap masih memenuhi target frame rate.
    ///
    /// Launch argument `-assertPerformance` mengubah peringatan menjadi assertion DEBUG,
    /// sehingga pelanggaran anggaran menghentikan aplikasi tepat saat terjadi — pola yang
    /// sama dengan `-assertLeaks`.
    public init(budget: PerformanceBudget = .sixtyFPS) {
        self.budget = budget
        assertsOnViolation = ProcessInfo.processInfo.arguments.contains("-assertPerformance")
        proxy.owner = self
    }

    public func start() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    public func stop() {
        displayLink?.invalidate()
        displayLink = nil
        frameCount = 0
        windowStart = 0
        previousTimestamp = 0
    }

    fileprivate func tick(_ displayLink: CADisplayLink) {
        if windowStart == 0 {
            windowStart = displayLink.timestamp
            previousTimestamp = displayLink.timestamp
            return
        }

        frameCount += 1
        let frameDuration = displayLink.timestamp - previousTimestamp
        previousTimestamp = displayLink.timestamp

        if frameDuration > (1.0 / 30.0) {
            hitchCount += 1
            hitchesInWindow += 1
        }

        let elapsed = displayLink.timestamp - windowStart
        guard elapsed >= 1 else { return }

        let measuredFPS = Int((Double(frameCount) / elapsed).rounded())
        framesPerSecond = measuredFPS

        evaluateBudget(fps: measuredFPS, hitches: hitchesInWindow)

        frameCount = 0
        hitchesInWindow = 0
        windowStart = displayLink.timestamp
    }

    private func evaluateBudget(fps: Int, hitches: Int) {
        let belowFPS = fps < budget.minimumFPS
        let tooManyHitches = hitches > budget.maximumHitchesPerWindow
        guard belowFPS || tooManyHitches else { return }

        budgetViolations += 1
        AppLogger.performance.warning(
            "Performance budget terlampaui: \(fps, privacy: .public) FPS (minimum \(self.budget.minimumFPS, privacy: .public)), \(hitches, privacy: .public) hitch (maksimum \(self.budget.maximumHitchesPerWindow, privacy: .public))"
        )

        #if DEBUG
        if assertsOnViolation {
            assertionFailure(
                "Performance budget terlampaui: \(fps) FPS, \(hitches) hitch dalam satu detik."
            )
        }
        #endif
    }

    deinit {
        displayLink?.invalidate()
    }
}
