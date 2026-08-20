import CoreKit
import CoreNavigation
import Foundation

/// Contoh adapter analytics. Ganti isinya dengan SDK perusahaan.
///
/// Yang penting bukan implementasinya, melainkan bahwa hanya ada **satu** yang memanggil
/// ini — `NavigationRouter` saat path berubah. Selama tidak ada layar yang menembakkan
/// screen view sendiri dari `onAppear`, angka kunjungan tidak akan pernah dobel.
struct AppScreenTracker: ScreenTracking {
    func screenViewed(_ screen: String) {
        AppLogger.navigation.info("SCREEN VIEW \(screen, privacy: .public)")
    }
}
