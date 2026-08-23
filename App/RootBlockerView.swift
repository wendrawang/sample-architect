import CoreGuards
import CoreKit
import DesignSystem
import SwiftUI


struct RootBlockerView: View {
    let reason: RootBlockerReason
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            RootBlockerStyle.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                Image(systemName: content.icon)
                    .font(.system(size: RootBlockerStyle.iconSize, weight: .semibold))
                    .foregroundColor(content.color)

                VStack(spacing: AppSpacing.xs) {
                    Text(content.title)
                        .font(AppTypography.title)
                        .multilineTextAlignment(.center)
                    Text(content.message)
                        .font(AppTypography.body)
                        .foregroundColor(AppColor.secondaryText)
                        .multilineTextAlignment(.center)
                }

                if reason == .noInternet {
                    PrimaryButton("Coba Lagi", action: onRetry)
                        .frame(maxWidth: RootBlockerStyle.actionMaxWidth)
                }
            }
            .padding(AppSpacing.xl)
        }
        .accessibilityElement(children: .contain)
    }

    private var content: (icon: String, title: String, message: String, color: Color) {
        switch reason {
        case .noInternet:
            return (
                "wifi.slash",
                "Tidak ada koneksi internet",
                "Periksa Wi-Fi atau data seluler Anda. Halaman akan terbuka otomatis saat koneksi kembali.",
                AppColor.warning
            )
        case .compromisedDevice:
            return (
                "exclamationmark.shield.fill",
                "Perangkat tidak aman",
                "Akses dihentikan karena pemeriksaan integritas perangkat tidak terpenuhi.",
                AppColor.danger
            )
        case .activeCall:
            return (
                "phone.fill",
                "Panggilan sedang berlangsung",
                "Untuk melindungi transaksi, lanjutkan setelah panggilan berakhir.",
                AppColor.brand
            )
        }
    }
}

struct FPSBadgeView: View {
    @ObservedObject var monitor: FrameRateMonitor

    var body: some View {
        // Jumlah pelanggaran anggaran ikut ditampilkan supaya QA melihatnya tanpa membuka
        // Console: badge boleh hijau sekarang padahal sudah beberapa kali tersendat tadi.
        Text("\(monitor.framesPerSecond) FPS • \(monitor.hitchCount) hitch • \(monitor.budgetViolations) over")
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(monitor.budgetViolations == 0 ? Color.green.opacity(0.88) : Color.red.opacity(0.88))
            .clipShape(Capsule())
    }
}
