import Combine
import CoreKit
import CorePresentation
import Foundation

@MainActor
public final class QRISViewModel: ObservableObject {
    public let presentation = ScreenPresentationStore()
    private let lifecycleProbe = LifecycleProbe("QRISViewModel")

    public init() {}

    public func didTapScan() {
        presentation.show(
            snackbar: SnackbarModel(
                message: "Hubungkan CameraSession milik aplikasi di sini.",
                iconSystemName: "camera.fill"
            )
        )
    }

    public func didTapGallery() {
        presentation.present(
            bottomSheet: BottomSheetModel(
                iconSystemName: "photo.on.rectangle.angled",
                title: "Ambil QR dari galeri",
                message: "Implementasi production perlu meminta izin Photos secara kontekstual.",
                actions: [
                    PresentationAction(id: "open-gallery", title: "Pilih Foto"),
                    PresentationAction(id: "cancel", title: "Batal", role: .secondary)
                ]
            )
        )
    }

    public func handlePresentationAction(_ id: String) {
        guard id == "open-gallery" else { return }
        presentation.show(
            snackbar: SnackbarModel(message: "Gallery adapter dipanggil.")
        )
    }
}

