import CoreGuards
import CoreNavigation

enum AppRootContentState: String, Equatable {
    /// Before the root guard has cleared. Nothing is built yet, so a compromised device
    /// or an active call is decided before any flow or inquiry starts.
    case launching
    case splash
    case preLogin
    case main
}

struct AppRootState: Equatable {
    var content: AppRootContentState
    var blocker: RootBlockerReason?
    /// Deep link yang menunggu dipakai saat flow tujuan dibangun.
    var deepLink: DeepLink?

    static let initial = AppRootState(content: .launching, blocker: nil, deepLink: nil)
}
