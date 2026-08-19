import CallKit
import CoreKit
import Foundation
import Network

public enum DeviceIntegrityStatus: Equatable, Sendable {
    case trusted
    case compromised
}

/// Sendable because `RootGuardMonitor` is itself Sendable and stores one of these. Both
/// shipped implementations are stateless structs, and a real RASP adapter must be safe to
/// call from whatever thread the guard happens to run on anyway.
public protocol DeviceIntegrityChecking: Sendable {
    func evaluate() -> DeviceIntegrityStatus
}

public struct TrustedDeviceIntegrityChecker: DeviceIntegrityChecking {
    public init() {}

    public func evaluate() -> DeviceIntegrityStatus {
        .trusted
    }
}

public enum RootBlockerReason: String, Equatable, Sendable {
    case noInternet
    case compromisedDevice
    case activeCall
}

public protocol RootGuardMonitoring: AnyObject {
    var onReasonChanged: ((RootBlockerReason?) -> Void)? { get set }
    func start()
    func refresh()
    func stop()
}

/// Every entry point runs on the main thread and every framework callback hops to main
/// before touching state, so the class is main-isolated in practice. `@unchecked Sendable`
/// states that explicitly, which is what lets `self` be captured by the `@Sendable`
/// callbacks that `NWPathMonitor` and `CXCallObserver` hand back on their own queues.
public final class RootGuardMonitor: NSObject, RootGuardMonitoring, @unchecked Sendable {
    public var onReasonChanged: ((RootBlockerReason?) -> Void)?

    private let integrityChecker: DeviceIntegrityChecking
    private let simulatesActiveCall: Bool
    private let pathMonitor = NWPathMonitor()
    private let pathQueue = DispatchQueue(label: "com.modularbank.network-path")
    private let callObserver = CXCallObserver()

    private var isOnline = true
    private var isCompromised = false
    private var hasActiveCall = false
    private var lastPublishedReason: RootBlockerReason?
    private var isStarted = false

    public init(
        integrityChecker: DeviceIntegrityChecking,
        simulatesActiveCall: Bool = false
    ) {
        self.integrityChecker = integrityChecker
        self.simulatesActiveCall = simulatesActiveCall
        super.init()
    }

    public func start() {
        MainThreadGuard.assertMainThread()
        guard !isStarted else { return }
        isStarted = true

        isCompromised = integrityChecker.evaluate() == .compromised
        callObserver.setDelegate(self, queue: .main)
        hasActiveCall = simulatesActiveCall || callObserver.calls.contains { !$0.hasEnded }

        pathMonitor.pathUpdateHandler = { [weak self] path in
            let isSatisfied = path.status == .satisfied
            DispatchQueue.main.async { [weak self] in
                self?.isOnline = isSatisfied
                self?.publishIfNeeded()
            }
        }
        pathMonitor.start(queue: pathQueue)
        publishIfNeeded()
    }

    public func refresh() {
        MainThreadGuard.assertMainThread()
        publishIfNeeded(force: true)
    }

    public func stop() {
        MainThreadGuard.assertMainThread()
        guard isStarted else { return }
        isStarted = false
        pathMonitor.cancel()
        callObserver.setDelegate(nil, queue: nil)
        onReasonChanged = nil
    }

    private func publishIfNeeded(force: Bool = false) {
        MainThreadGuard.assertMainThread()
        let reason: RootBlockerReason?

        if isCompromised {
            reason = .compromisedDevice
        } else if hasActiveCall {
            reason = .activeCall
        } else if !isOnline {
            reason = .noInternet
        } else {
            reason = nil
        }

        guard force || reason != lastPublishedReason else { return }
        lastPublishedReason = reason
        onReasonChanged?(reason)
    }

    deinit {
        pathMonitor.cancel()
    }
}

extension RootGuardMonitor: CXCallObserverDelegate {
    public func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        let hasActive = callObserver.calls.contains { !$0.hasEnded }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hasActiveCall = self.simulatesActiveCall || hasActive
            self.publishIfNeeded()
        }
    }
}
