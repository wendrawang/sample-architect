import Foundation

public enum MainThreadGuard {
    public static func assertMainThread(
        _ message: @autoclosure () -> String = "UI state must be mutated on the main thread",
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        if !Thread.isMainThread {
            assertionFailure(message(), file: file, line: line)
        }
        #endif
    }
}

