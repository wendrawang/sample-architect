import CallKit
import CoreKit
import Foundation
import Network

public enum DeviceIntegrityStatus: Equatable {
    case trusted
    case compromised
}

public protocol DeviceIntegrityChecking {
    func evaluate() -> DeviceIntegrityStatus
}

public struct TrustedDeviceIntegrityChecker: DeviceIntegrityChecking {
    public init() {}

    public func evaluate() -> DeviceIntegrityStatus {
        .trusted
    }
}

public enum RootBlockerReason: Equatable {
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

public final class RootGuardMonitor: NSObject, RootGuardMonitoring {
    public var onReasonChanged: ((RootBlockerReason?) -> Void)?

    private let integrityChecker: DeviceIntegrityChecking
    private let pathMonitor = NWPathMonitor()
    private let pathQueue = DispatchQueue(label: "com.modularbank.network-path")
    private let callObserver = CXCallObserver()

    private var isOnline = true
    private var isCompromised = false
    private var hasActiveCall = false
    private var lastPublishedReason: RootBlockerReason?
    private var isStarted = false

    public init(integrityChecker: DeviceIntegrityChecking) {
        self.integrityChecker = integrityChecker
        super.init()
    }

    public func start() {
        MainThreadGuard.assertMainThread()
        guard !isStarted else { return }
        isStarted = true

        isCompromised = integrityChecker.evaluate() == .compromised
        callObserver.setDelegate(self, queue: .main)
        hasActiveCall = callObserver.calls.contains { !$0.hasEnded }

        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { [weak self] in
                self?.isOnline = path.status == .satisfied
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
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hasActiveCall = callObserver.calls.contains { !$0.hasEnded }
            self.publishIfNeeded()
        }
    }
}
