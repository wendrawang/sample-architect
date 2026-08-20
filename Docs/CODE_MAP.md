# Peta Kode: Apa Guna Setiap File

Dokumen ini menjawab satu pertanyaan untuk setiap file: **kenapa file ini ada, dan apa
yang rusak kalau dihapus.**

Kolom "kalau dihapus" bukan sekadar hiasan. Kalau Anda tidak bisa menjawabnya, berarti
file itu memang tidak perlu ada.

---

## 1. App — composition root

Satu-satunya tempat yang tahu *keseluruhan* aplikasi. Semua keputusan konkret
(mock atau live, siapa implementasi secrets, flow mana yang jadi root) dibuat di sini,
supaya feature package tetap tidak tahu-menahu soal aplikasi yang memakainya.

| File | Kegunaan | Kalau dihapus |
|---|---|---|
| `AppDelegate.swift` | Titik masuk proses. Memasang appearance global nav bar dan tab bar sekali di awal. | App tidak punya entry point. |
| `SceneDelegate.swift` | Membuat `UIWindow`, membuat `AppCoordinator`, memasang `AppRootView` sebagai root. | Layar tidak pernah muncul. |
| `AppConfiguration.swift` | Membaca `Info.plist` dan launch argument jadi satu struct: base URL, mock/live, path OAuth, marker 401, URL App Store. | Setiap file harus baca `Info.plist` sendiri, dan QA kehilangan semua toggle `-simulate*`. |
| `AppCoordinator.swift` | Memegang state root (`launching` → `splash` → `preLogin` → `main`), sesi, API client, dan root guard. Menerima callback unauthorized lalu memaksa kembali ke pre-login. | Tidak ada yang memutuskan layar mana yang tampil, dan sesi kedaluwarsa tidak menendang pengguna keluar. |
| `AppRootView.swift` | Menerjemahkan state root jadi tampilan, plus overlay blocker dan badge FPS. | State berubah tapi layar tidak ikut berubah. |
| `AppRootState.swift` | Struct kecil berisi `content` dan `blocker`. Nilai, bukan object. | State root tersebar jadi beberapa boolean yang bisa saling bertentangan. |
| `AppSessionStore.swift` | Menyimpan `OAuthCredential` dan session ID di memory, dilindungi `NSLock`. Refresh hanya mengganti token, session ID tetap. | Token hilang antar request, dan header tracing kehilangan identitas sesi. |
| `AppNetworkComposition.swift` | Merakit `AlamofireAPIClient`: menyuntik secrets, signer, tracer, konfigurasi mTLS. | Tidak ada yang menyambungkan `CoreNetwork` ke konfigurasi perusahaan. |
| `RootBlockerView.swift` | Tampilan layar penuh untuk tidak ada internet / perangkat tidak aman / sedang menelepon. | Kondisi berbahaya terdeteksi tapi pengguna tidak diberi tahu. |
| `RootBlockerStyle.swift` | Konstanta visual khusus blocker. | Angka ajaib tersebar di dalam View. |

**Yang penting dipahami:** `AppCoordinator` **tidak memiliki satu pun flow**. Ia hanya
mengubah `rootState`. SwiftUI yang membongkar flow lama dan membangun yang baru. Itulah
sebabnya tidak ada `childCoordinators` yang perlu dilepas manual — sumber memory leak
klasik pada pola coordinator lama.

---

## 2. CoreKit — perkakas observasi

Tidak ada UI, tidak ada network. Isinya alat untuk *melihat* apa yang terjadi.

| File | Kegunaan | Kalau dihapus |
|---|---|---|
| `AppLogger.swift` | Enam kategori `os.Logger`: app, navigation, network, lifecycle, performance, security. Memakai `privacy:` supaya data sensitif tidak bocor ke Console. | Debugging kembali ke `print()`, dan log production berisiko membocorkan token. |
| `LifecycleProbe.swift` | Ditempel di setiap ViewModel dan router. Mencetak `INIT` saat lahir, `DEINIT` saat mati. | Anda kehilangan cara termurah membuktikan sebuah layar benar-benar terlepas. |
| `LeakWatchdog.swift` | Dipanggil manual di titik yang Anda tahu sebuah object seharusnya sudah mati; memperingatkan kalau setelah 5 detik masih hidup. Launch argument `-assertLeaks` mengubahnya jadi assertion. | Kehilangan alat cek leak yang bisa dipanggil ad hoc. |
| `MainThreadGuard.swift` | `assertMainThread()` — DEBUG-only, meledak kalau state UI disentuh dari thread lain. | Bug thread muncul sebagai kerusakan acak jauh dari penyebabnya. |
| `PerformanceMonitor.swift` | `PerformanceTracer` (signpost untuk Instruments) dan `FrameRateMonitor` (badge FPS + penghitung hitch lewat `CADisplayLink`). | Tidak ada cara mengukur; optimasi jadi tebak-tebakan. |

---

## 3. CoreNavigation — mesin navigasi

| File | Kegunaan | Kalau dihapus |
|---|---|---|
| `NavigationRouter.swift` | Satu router per flow. Menyimpan `[Route]` — **nilai**, bukan View atau ViewModel. Punya `push`, `pop`, `popToRoot`, dan mencatat `PUSH`/`POP` termasuk yang dipicu swipe. | Setiap flow bikin cara push/pop sendiri, dan tidak ada yang bisa di-unit test. |
| `NavigationAppearance.swift` | Styling `UINavigationBar` lewat appearance proxy. `NavigationStack` tetap memakai `UINavigationBar` di baliknya. | Nav bar kembali ke tampilan default sistem. |

**Kenapa router hanya menyimpan nilai:** kalau router menyimpan ViewModel, ia menjadi
pemilik layar. Layar yang sudah di-pop tetap dipegang router, dan itu leak. Dengan
menyimpan route (`enum`), yang dipop otomatis dilepas SwiftUI. Aman *karena bentuk
datanya*, bukan karena kedisiplinan programmer.

---

## 4. CoreNetwork — infrastruktur jaringan

Satu-satunya modul yang boleh `import Alamofire`.

| File | Kegunaan | Kalau dihapus |
|---|---|---|
| `APIClient.swift` | Protokol `APIClient` dan tipe `Endpoint<Response>`. Response-nya ditentukan di compile time, bukan `Any`. | Repository kembali menebak tipe response dan crash saat runtime. |
| `APIError.swift` | Error jaringan yang bertipe: transport, decoding, authentication, status code. | Semua kegagalan jadi satu `Error` buram yang tidak bisa dibedakan. |
| `AlamofireAPIClient.swift` | Implementasi konkret: satu `Session` terkonfigurasi, timeout, penolakan redirect lintas origin, decoding, signpost, dan logging privacy-aware. | Tidak ada yang benar-benar mengirim request. |
| `Authentication.swift` | `OAuthCredential`, `OAuthAuthenticator`, dan token refresh terkendali — request 401 diantre, refresh dibatasi 2 kali per 30 detik. | Sepuluh request yang 401 bersamaan memicu sepuluh refresh (refresh storm). |
| `RequestMetadata.swift` | Header terpusat (request ID, platform, versi, session ID, channel, API key, timestamp) dan request signing dengan mode `.none` / `.ifAvailable` / `.required`. | Setiap service merakit header sendiri, dan signature tidak ikut diulang setelah retry. |
| `MTLS.swift` | Client certificate dari PKCS#12, hanya untuk host yang di-allowlist, gagal tertutup kalau wajib tapi tidak tersedia. | mTLS tidak bisa diaktifkan; atau lebih buruk, gagal diam-diam. |
| `NetworkTracing.swift` | Adapter APM. `CoreNetwork` tidak pernah tahu Dynatrace itu apa. | `CoreNetwork` jadi bergantung pada SDK APM tertentu selamanya. |

**Urutan yang disengaja:** auth adapter berjalan **sebelum** signature adapter. Setelah
token di-refresh, Alamofire mengulang seluruh adaptation, sehingga `Authorization`,
timestamp, dan signature selalu konsisten satu sama lain.

---

## 5. CorePresentation — state transient per layar

| File | Kegunaan | Kalau dihapus |
|---|---|---|
| `PresentationModels.swift` | `BottomSheetModel`, `ScreenBlockerModel`, `SnackbarModel`, `PresentationAction`. Action disimpan sebagai **string ID**, bukan closure. | Model presentation dibuat ulang beda-beda di tiap feature. |
| `ScreenPresentationStore.swift` | Satu store per ViewModel. Memegang bottom sheet, blocker, dan snackbar yang sedang tampil, plus auto-dismiss snackbar yang bisa dibatalkan. | Setiap layar bikin sendiri `@Published var showSheet` yang saling bertabrakan. |

**Kenapa action pakai string ID, bukan closure:** kalau model menyimpan closure yang
menangkap ViewModel, terbentuk siklus `ViewModel → Store → closure → ViewModel` dan
tidak ada yang pernah dilepas. Dengan ID, model tetap jadi data murni; handler-nya
dimiliki View yang mengikuti lifecycle layar.

---

## 6. CoreGuards — kondisi tingkat aplikasi

| File | Kegunaan | Kalau dihapus |
|---|---|---|
| `RootGuardMonitor.swift` | Memantau internet (`NWPathMonitor`), panggilan aktif (`CXCallObserver`), dan integritas perangkat. Menerbitkan satu alasan blocker dengan prioritas: perangkat tidak aman → sedang menelepon → tidak ada internet. | Transaksi bisa dimulai saat offline, saat ada panggilan, atau di perangkat yang sudah di-root. |

`DeviceIntegrityChecking` sengaja hanya protokol. Implementasi bawaan cuma membaca
launch argument untuk demo — **wajib** diganti RASP/device-integrity SDK resmi sebelum
production.

---

## 7. DesignSystem — konsistensi visual

| File | Kegunaan | Kalau dihapus |
|---|---|---|
| `Tokens.swift` | `AppColor`, `AppSpacing`, `AppRadius`, `AppTypography`. Satu sumber kebenaran. | Warna dan jarak jadi angka ajaib yang berbeda-beda di tiap layar. |
| `Components.swift` | Tombol, input card, text field, card, section header, logo. | Setiap feature bikin tombol sendiri dan tampilannya tidak seragam. |
| `ScreenScaffold.swift` | Pembungkus setiap layar. Otomatis memberi kemampuan bottom sheet, blocker, dan snackbar. `ScreenStyle` mengatur background dan padding. | Setiap layar harus merakit sendiri overlay-nya, dan pasti ada yang lupa. |
| `TabBarAppearance.swift` | Styling `UITabBar` lewat appearance proxy. | Tab bar kembali ke tampilan default. |

---

## 8. Feature packages

Setiap flow adalah satu local Swift Package. Pola isinya selalu sama:

| Berkas | Perannya |
|---|---|
| `NamaDomain.swift` | Model domain dan **protokol** repository. Tidak ada DTO, tidak ada Alamofire. |
| `NamaRepositories.swift` | `Remote…` (mapping DTO ke domain) dan `Mock…` (data deterministik untuk demo dan test). |
| `NamaUseCase.swift` | Satu business intent. Validasi dan aturan bisnis tinggal di sini. |
| `NamaViewModel.swift` | `@MainActor final class`. Mengelola loading/error/success, memanggil UseCase, membatalkan task pada `deinit`. |
| `NamaView.swift` | Render murni. Menerima ViewModel lewat `@ObservedObject`. |
| `NamaScreen.swift` | Ownership boundary. Membuat ViewModel lewat `@StateObject`, merakit UseCase. |
| `NamaStyle.swift` | Konstanta visual khusus layar itu. Tidak boleh berisi logika. |
| `NamaFlowView.swift` | Hanya untuk flow yang punya push/pop. Mendeklarasikan route enum dan memetakannya ke Screen. |

Package yang ada:

| Package | Isi | Catatan |
|---|---|---|
| `FeatureSplash` | Inquiry startup, keputusan launch, blocker maintenance/force update. | Timer minimum tampil dan network berjalan **paralel**, bukan berurutan. |
| `FeatureAuth` | Username → Password, validasi, login. | Punya `AuthFlowView` + `AuthRoute`. |
| `FeatureMain` | Composition boundary lima tab dan route `.transfer`. | Satu-satunya package yang boleh mengimpor feature lain. |
| `FeatureDashboard` | Inquiry dashboard, saldo, menu, transaksi. | |
| `FeatureTransfer` | Daftar penerima, nominal, konfirmasi, submit. | Di-push dari Dashboard. |
| `FeatureFinancial`, `FeatureQRIS`, `FeatureRewards`, `FeatureMore` | Placeholder tiap tab. | Belum ada network. |
| `FeatureTemplate` | Contoh lengkap satu feature. | **Salin ini** saat membuat flow baru. |

---

## 9. Kenapa View dan Screen dipisah

Ini pertanyaan yang paling sering muncul, jadi ditulis terpisah.

```swift
// Screen: yang MEMILIKI. Dibuat sekali oleh SwiftUI per identitas layar.
public struct TransferScreen: View {
    @StateObject private var viewModel: TransferViewModel

    public init(dependencies: any TransferDependencies) {
        _viewModel = StateObject(wrappedValue: TransferViewModel(
            submitTransfer: SubmitTransferUseCase(
                repository: dependencies.makeTransferRepository()
            )
        ))
    }

    public var body: some View { TransferView(viewModel: viewModel) }
}

// View: yang MERENDER. Tidak memiliki apa pun.
public struct TransferView: View {
    @ObservedObject private var viewModel: TransferViewModel
    ...
}
```

Perbedaannya nyata, bukan gaya-gayaan:

- `@StateObject` → SwiftUI membangun ViewModel **tepat sekali** per identitas layar.
  Berapa kali pun `body` dievaluasi ulang, ViewModel-nya sama. Kalau memakai
  `@ObservedObject` di sini, ViewModel dibuat ulang setiap render dan semua state
  hilang.
- Saat route di-pop, SwiftUI melepas Screen → melepas ViewModel → `deinit` membatalkan
  task yang masih jalan. Itulah rantai yang menjaga tidak ada request menggantung.
- `TransferView` tetap bisa dipakai di Preview dan test dengan ViewModel buatan sendiri,
  karena ia tidak tahu cara membuat UseCase.

---

## 10. Alur satu request, dari ketukan sampai layar

```text
Tombol ditekan di View
  └→ viewModel.didTapReview()                    ViewModel, @MainActor
       └→ useCase.execute(...)                   UseCase, business rule
            └→ repository.submit(...)            Protokol, domain tidak tahu HTTP
                 └→ APIClient.request(Endpoint)  CoreNetwork
                      └→ Alamofire Session       satu-satunya yang bicara HTTP
```

Hasilnya kembali ke arah sebaliknya, dan routing dikirim lewat closure output:

```text
ViewModel output → router.push/pop → NavigationStack path berubah → layar berpindah
```

Aturan yang menjaga arah ini tetap lurus dijalankan otomatis oleh
`Scripts/check_architecture.sh` setiap kali `make check`.
