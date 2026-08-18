import Combine
import Foundation
import QuartzCore
import os.signpost

public final class PerformanceInterval {
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

@MainActor
public final class FrameRateMonitor: ObservableObject {
    @Published public private(set) var framesPerSecond: Int = 0
    @Published public private(set) var hitchCount: Int = 0

    private let proxy = DisplayLinkProxy()
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var windowStart: CFTimeInterval = 0
    private var previousTimestamp: CFTimeInterval = 0

    public init() {
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
        }

        let elapsed = displayLink.timestamp - windowStart
        guard elapsed >= 1 else { return }

        let measuredFPS = Int((Double(frameCount) / elapsed).rounded())
        framesPerSecond = measuredFPS

        if measuredFPS < 55 {
            AppLogger.performance.warning("Low frame rate detected: \(measuredFPS, privacy: .public) FPS")
        }

        frameCount = 0
        windowStart = displayLink.timestamp
    }

    deinit {
        displayLink?.invalidate()
    }
}
