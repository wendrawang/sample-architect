# ModularBank iOS Template

Template banking app untuk iOS 15+ dengan SwiftUI sebagai UI dan `UINavigationController` sebagai satu-satunya navigation engine. Project memakai MVVM + Coordinator + UseCase + Repository, Local Swift Package per flow, dan Alamofire 5.12.0 dengan Codable.

## Jalankan di Mac

Kebutuhan:

- macOS dengan Xcode 16 atau lebih baru
- Homebrew (hanya untuk memasang XcodeGen jika belum ada)

Cara termudah:

1. Extract ZIP.
2. Double-click `bootstrap.command`.
3. Buka target `ModularBank`, pilih Signing Team bila ingin menjalankan di device.
4. Run pada iOS Simulator atau device iOS 15+.

Alternatif lewat Terminal:

```bash
brew install xcodegen ripgrep
cd ModularBankTemplate
make project
open ModularBank.xcodeproj
```

Xcode akan mengambil Alamofire otomatis melalui Swift Package Manager. Project memakai exact version `5.12.0` agar build reproducible.

## Demo login

Mock service aktif secara default, jadi backend tidak dibutuhkan.

- Username: minimal 3 karakter, contoh `wendra`
- Password: minimal 6 karakter, contoh `secret123`

Flow yang tersedia:

```text
Splash
  -> Pre-login: Username -> Password
  -> Main TabView
       Dashboard -> Transfer (UIKit push)
       Financial
       QRIS (floating center button)
       Rewards
       More -> Logout
```

Root overlay memonitor:

- Tidak ada internet (`NWPathMonitor`)
- Panggilan aktif (`CXCallObserver`)
- Hasil adapter device integrity/root detection

## Struktur package

```text
Packages/
  Core/                 CoreKit, Navigation, Network, Presentation, Guards
  DesignSystem/         Token, komponen, ScreenScaffold
  FeatureSplash/
  FeatureAuth/          Username + Password + AuthCoordinator
  FeatureMain/          Composition lima tab + MainCoordinator
  FeatureDashboard/     Dashboard inquiry
  FeatureTransfer/      Transfer flow + TransferCoordinator
  FeatureFinancial/
  FeatureQRIS/
  FeatureRewards/
  FeatureMore/
  FeatureTemplate/      Bentuk baku feature baru
```

`FeatureMain` sengaja menjadi satu-satunya feature yang bergantung pada beberapa feature lain karena ia adalah composition boundary. Feature biasa tidak boleh saling mengimpor.

## Bottom sheet, blocker, dan snackbar

Setiap halaman memiliki satu `ScreenPresentationStore` dan dibungkus dengan `ScreenScaffold`.

```swift
let presentation = ScreenPresentationStore()

presentation.present(
    bottomSheet: BottomSheetModel(
        title: "Konfirmasi",
        message: "Lanjutkan transaksi?",
        actions: [
            PresentationAction(id: "confirm", title: "Lanjut"),
            PresentationAction(id: "cancel", title: "Batal", role: .secondary)
        ]
    )
)

presentation.present(
    blocker: ScreenBlockerModel(
        title: "Inquiry gagal",
        message: "Silakan coba kembali.",
        actions: [PresentationAction(id: "retry", title: "Coba Lagi")]
    )
)

presentation.show(
    snackbar: SnackbarModel(message: "Data berhasil disimpan")
)
```

Action disimpan sebagai ID, bukan closure. Ini mencegah cycle `ViewModel -> Store -> closure -> ViewModel`. View meneruskan ID kembali ke `handlePresentationAction(_:)`.

## Mengaktifkan live service

1. Ganti `API_BASE_URL` di `App/Resources/Info.plist`.
2. Ubah `USE_MOCK_SERVICES` menjadi `false`, atau tambahkan launch argument `-useLiveServices`.
3. Sesuaikan DTO dan endpoint berdasarkan `Docs/API_CONTRACT.md`.
4. Tambahkan auth interceptor, SSL pinning/mTLS, dan error mapping perusahaan pada `CoreNetwork`/composition layer.

`AppSessionStore` memasang Bearer token ke request setelah login dan hanya menyimpannya di memory. Hubungkan abstraction secure storage/Keychain milik perusahaan bila session harus dipulihkan setelah app relaunch.

Jangan menyimpan access token, client secret, certificate password, atau production URL sensitif di repository.

## Device integrity / rooted blocker

UI dan routing blocker sudah aktif, tetapi checker default hanya adapter simulasi. Jalankan dengan launch argument `-simulateRootedDevice` untuk melihat state-nya.

Untuk production, ganti `LaunchArgumentDeviceIntegrityChecker` dengan adapter dari RASP/device-integrity SDK resmi perusahaan. Template sengaja tidak mengklaim pemeriksaan file sederhana sebagai proteksi jailbreak yang memadai.

## Performance dan memory

- Tidak ada `NavigationLink`, destination pre-render, atau `AnyView`.
- Semua screen dibuat lazy saat coordinator melakukan push.
- ViewModel dan coordinator memiliki lifecycle log.
- Child coordinator dilepas pada tombol Back maupun interactive-pop.
- Async task dibatalkan saat ViewModel deinit dan tidak menahan ViewModel selama network wait.
- Tambahkan launch argument `-showFPS` untuk badge FPS/hitch.
- Tambahkan `-assertLeaks` untuk assertion DEBUG jika flow object masih hidup setelah batas waktu.
- Jalankan `make check` untuk aturan import/navigation dasar.

Lihat `Docs/PERFORMANCE_AND_LEAKS.md` untuk prosedur Instruments. Target 60 FPS adalah target yang harus diverifikasi pada device dan data nyata, bukan janji statis dari template.

## Dokumen lanjutan

- `Docs/ARCHITECTURE.md` — dependency direction dan ownership
- `Docs/NEW_FEATURE_GUIDE.md` — rule menambah halaman/flow
- `Docs/PERFORMANCE_AND_LEAKS.md` — pengukuran dan leak guard
- `Docs/API_CONTRACT.md` — contoh contract Codable

Sumber Alamofire: <https://github.com/Alamofire/Alamofire>
