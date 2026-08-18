import Combine
import CoreKit
import Foundation

@MainActor
public final class ScreenPresentationStore: ObservableObject {
    @Published public private(set) var bottomSheet: BottomSheetModel?
    @Published public private(set) var blocker: ScreenBlockerModel?
    @Published public private(set) var snackbar: SnackbarModel?

    private var snackbarTask: Task<Void, Never>?

    public init() {}

    public func present(bottomSheet: BottomSheetModel) {
        MainThreadGuard.assertMainThread()
        self.bottomSheet = bottomSheet
    }

    public func dismissBottomSheet() {
        MainThreadGuard.assertMainThread()
        bottomSheet = nil
    }

    public func present(blocker: ScreenBlockerModel) {
        MainThreadGuard.assertMainThread()
        self.blocker = blocker
    }

    public func dismissBlocker() {
        MainThreadGuard.assertMainThread()
        blocker = nil
    }

    public func show(snackbar: SnackbarModel) {
        MainThreadGuard.assertMainThread()
        snackbarTask?.cancel()
        self.snackbar = snackbar

        snackbarTask = Task { [weak self] in
            let duration = max(0, snackbar.duration)
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.snackbar = nil
        }
    }

    public func dismissSnackbar() {
        snackbarTask?.cancel()
        snackbarTask = nil
        snackbar = nil
    }

    deinit {
        snackbarTask?.cancel()
    }
}
