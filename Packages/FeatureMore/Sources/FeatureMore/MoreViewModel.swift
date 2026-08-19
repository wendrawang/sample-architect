import Combine
import CoreKit
import CorePresentation
import Foundation

public struct MoreMenuItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let icon: String

    public init(id: String, title: String, icon: String) {
        self.id = id
        self.title = title
        self.icon = icon
    }
}

@MainActor
public final class MoreViewModel: ObservableObject {
    public let presentation = ScreenPresentationStore()
    public let menus: [MoreMenuItem] = [
        MoreMenuItem(id: "profile", title: "Profil", icon: "person.crop.circle.fill"),
        MoreMenuItem(id: "security", title: "Keamanan", icon: "lock.shield.fill"),
        MoreMenuItem(id: "settings", title: "Pengaturan", icon: "gearshape.fill"),
        MoreMenuItem(id: "support", title: "Pusat Bantuan", icon: "questionmark.circle.fill")
    ]

    private let onLogout: () -> Void
    private let lifecycleProbe = LifecycleProbe("MoreViewModel")

    public init(onLogout: @escaping () -> Void) {
        self.onLogout = onLogout
    }

    public func didTapMenu(_ menu: MoreMenuItem) {
        presentation.show(
            snackbar: SnackbarModel(
                message: "Buka flow \(menu.title)",
                iconSystemName: menu.icon
            )
        )
    }

    public func didTapLogout() {
        presentation.present(
            bottomSheet: BottomSheetModel(
                iconSystemName: "rectangle.portrait.and.arrow.right",
                title: "Keluar dari aplikasi?",
                message: "Anda perlu login kembali untuk mengakses akun.",
                actions: [
                    PresentationAction(id: "confirm-logout", title: "Keluar", role: .destructive),
                    PresentationAction(id: "cancel", title: "Batal", role: .secondary)
                ]
            )
        )
    }

    public func handlePresentationAction(_ id: String) {
        guard id == "confirm-logout" else { return }
        onLogout()
    }
}

