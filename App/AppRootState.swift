import CoreGuards

enum AppRootContentState: String, Equatable {
    case splash
    case preLogin
    case main
}

struct AppRootState: Equatable {
    var content: AppRootContentState
    var blocker: RootBlockerReason?

    static let initial = AppRootState(content: .splash, blocker: nil)
}
