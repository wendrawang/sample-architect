import SwiftUI
import UIKit

/// Pintu masuk untuk layar yang datang sebagai `UIViewController` — kamera, biometrik,
/// e-KYC, payment gateway, dan SDK pihak ketiga lain.
///
/// Membungkusnya lewat tipe ini, bukan lewat `UIViewControllerRepresentable` dadakan di
/// tiap tempat, menghindari dua bug yang paling sering muncul: controller dibangun ulang
/// setiap `body` dievaluasi, dan controller yang tidak pernah dilepas.
///
/// ```swift
/// case .ekyc:
///     UIKitScreen { EKYCViewController(onFinish: ...) }
///         .toolbar(.hidden, for: .tabBar)
/// ```
public struct UIKitScreen<Controller: UIViewController>: UIViewControllerRepresentable {
    private let make: () -> Controller

    public init(_ make: @escaping () -> Controller) {
        self.make = make
    }

    /// Dipanggil sekali per identitas layar. Di sinilah controller dibangun.
    public func makeUIViewController(context: Context) -> Controller {
        make()
    }

    /// Sengaja kosong. Membangun ulang controller di sini adalah penyebab paling umum
    /// layar SDK berkedip atau kehilangan state saat parent-nya re-render.
    public func updateUIViewController(_ controller: Controller, context: Context) {}
}
