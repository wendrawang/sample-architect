import Foundation

/// Adapter analytics. `CoreNavigation` tidak pernah tahu SDK apa yang dipakai.
public protocol ScreenTracking: Sendable {
    func screenViewed(_ screen: String)
}

/// Titik tunggal pencatatan screen view.
///
/// Sengaja tidak dipasang di `onAppear`. `onAppear` dipanggil berkali-kali — saat
/// re-render, saat kembali dari background, saat pindah tab, dan saat layar di atasnya
/// dipop — sehingga angkanya pasti membengkak. Perubahan path terjadi **tepat sekali**
/// per perpindahan layar, jadi di sinilah tempat yang benar.
@MainActor
public enum ScreenTracker {
    private static var sink: (any ScreenTracking)?

    /// Panggil sekali saat aplikasi start, dari composition root.
    public static func use(_ sink: (any ScreenTracking)?) {
        Self.sink = sink
    }

    static func track(_ screen: String) {
        sink?.screenViewed(screen)
    }
}
