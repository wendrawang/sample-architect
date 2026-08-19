import DesignSystem
import SwiftUI

public struct QRISView: View {
    @ObservedObject private var viewModel: QRISViewModel

    public init(viewModel: QRISViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScreenScaffold(
            presentation: viewModel.presentation,
            style: .edgeToEdge,
            onAction: viewModel.handlePresentationAction
        ) {
            ZStack {
                QRISStyle.background.ignoresSafeArea()

                VStack(spacing: AppSpacing.lg) {
                    VStack(spacing: AppSpacing.xs) {
                        Text("Scan QRIS")
                            .font(AppTypography.title)
                        Text("Arahkan kamera ke kode QR")
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.72))
                    }
                    .foregroundColor(.white)

                    RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, dash: [22, 9]))
                        .frame(width: QRISStyle.scanArea, height: QRISStyle.scanArea)
                        .overlay(
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 76, weight: .thin))
                                .foregroundColor(.white.opacity(0.35))
                        )

                    PrimaryButton("Mulai Scan", action: viewModel.didTapScan)
                        .frame(maxWidth: 280)

                    Button(action: viewModel.didTapGallery) {
                        Label("Ambil dari Galeri", systemImage: "photo.fill")
                            .font(AppTypography.label)
                            .foregroundColor(.white)
                    }
                }
                .padding(AppSpacing.lg)
            }
        }
    }
}

