# ModularBank iOS Template

Template aplikasi mobile banking iOS 16+ dengan:

- SwiftUI untuk seluruh screen dan komponen UI.
- `NavigationStack` sebagai satu-satunya navigation engine.
- MVVM + Router + UseCase + Repository.
- Local Swift Package per core concern dan per feature flow.
- Swift 6 language mode dengan strict concurrency penuh; lihat `Docs/SWIFT_CONCURRENCY.md`.
- Alamofire `5.12.0` dengan `Encodable`/`Decodable`, async/await, mTLS, Bearer authentication, controlled token refresh, request signing, download, dan tracing adapter.
- Bottom sheet, screen-level error blocker, dan snackbar pada setiap halaman.
- Root blocker untuk tidak ada internet, compromised/rooted device, dan panggilan aktif.
- Lifecycle logger, leak watchdog, signpost, FPS/hitch monitor, serta rule untuk menjaga frame time.

UI menggunakan komposisi, warna, spacing, dan hierarchy yang mendekati referensi yang diberikan. Logo dan ilustrasi promosi di template berupa code-native placeholder; ganti dengan vector/raster asset resmi perusahaan sebelum production.

## 1. Cara menjalankan

Kebutuhan:

- macOS dengan Xcode 16 atau lebih baru.
- XcodeGen 2.42 atau lebih baru.
- `ripgrep` untuk architecture check.

Cara termudah:

1. Clone repository ini.
2. Double-click `bootstrap.command`.
3. Buka target `ModularBank`.
4. Pilih Signing Team jika menjalankan pada device.
5. Run pada iOS Simulator atau device iOS 16+.

Alternatif melalui Terminal:

```bash
brew install xcodegen ripgrep
git clone https://github.com/wendrawang/sample-architect.git
cd sample-architect
make project
open ModularBank.xcodeproj
```

Xcode mengambil Alamofire melalui Swift Package Manager. Versi dipin exact ke `5.12.0` supaya build reproducible.

Mock service aktif secara default sehingga project dapat dieksplorasi tanpa backend:

- Username minimal 3 karakter, contoh: `wendra`.
- Password minimal 6 karakter, contoh: `secret123`.

## 2. Flow aplikasi

```text
SceneDelegate
  -> AppCoordinator (state root)
      -> AppRootView
          ├─ Splash + startup inquiry
          ├─ AuthFlowView
          │   └─ NavigationStack<AuthRoute>
          │       └─ Username -> .password
          ├─ MainFlowView
          │   └─ NavigationStack<MainRoute>
          │       └─ TabView
          │           ├─ Beranda / Dashboard -> .transfer
          │           ├─ Finansial
          │           ├─ QRIS Scan (tombol bulat besar di tengah)
          │           ├─ Rewards
          │           └─ Lainnya
          └─ Root blocker overlay
              ├─ Tidak ada internet
              ├─ Compromised/rooted device
              └─ Panggilan aktif
```

`AppRootView` menukar seluruh flow ketika root state berubah dan memasang blocker global di atasnya. Error inquiry sebuah halaman menggunakan blocker milik halaman, bukan mengubah root state.

## 3. Kegunaan setiap layer

| Layer | Kegunaan | Boleh melakukan | Tidak boleh melakukan |
|---|---|---|---|
| View | Render state dan meneruskan intent pengguna | Binding, layout, accessibility, memanggil method ViewModel | Network, business rule, push/pop |
| Screen | Ownership boundary satu layar | Membuat ViewModel lewat `@StateObject`, merakit UseCase | Layout dan business rule |
| ViewModel | Mengelola presentation state sebuah screen | Loading/error/success, memanggil UseCase, membentuk model bottom sheet/blocker/snackbar | Import UIKit, membuat controller, memanggil Alamofire |
| UseCase | Business logic untuk satu intent | Validasi, policy, orchestration repository | Menampilkan UI dan mengetahui navigation |
| Repository Protocol | Kontrak data yang dibutuhkan domain | Mendefinisikan operasi berbasis domain model | Mengekspos DTO/Alamofire ke ViewModel |
| Remote Repository | Adapter backend | Membuat `Endpoint`, mapping Codable DTO ke domain | Menyimpan state UI |
| Mock Repository | Data deterministik untuk demo/test | Delay/case success/failure terkontrol | Menjadi implementasi production |
| Flow view + Router | Ownership flow dan navigation | Mendeklarasikan route, memetakan route ke Screen, push/pop | Business validation dan render UI |
| Design System | Konsistensi visual dan presentation shell | Token, reusable component, `ScreenScaffold` | Business logic feature |
| App Composition | Wiring konkret seluruh dependency | Memilih mock/live, secret adapter, tracer, root route | Menjadi tempat logic tiap feature |

Alur request feature yang wajib diikuti:

```text
SwiftUI View
  -> @MainActor ViewModel
      -> UseCase
          -> Repository Protocol
              -> Remote Repository
                  -> APIClient
                      -> Alamofire Session
```

Hasil routing berjalan ke arah sebaliknya melalui output closure:

```text
ViewModel output -> Router.push/pop -> NavigationStack path
```

## 4. Kegunaan setiap package

| Package/product | Isi dan kegunaan | Dipakai ketika |
|---|---|---|
| `Core/CoreKit` | `AppLogger`, `LifecycleProbe`, `LeakWatchdog`, `MainThreadGuard`, signpost, FPS/hitch monitor | Semua feature yang membutuhkan observability/lifecycle guard |
| `Core/CoreNavigation` | `NavigationRouter<Route>`, global nav bar appearance | Flow melakukan push/pop lewat `NavigationStack` |
| `Core/CoreNetwork` | API client, endpoint, Codable, Alamofire session, mTLS, auth refresh, signature, metadata header, download, tracing | Remote repository berkomunikasi dengan backend |
| `Core/CorePresentation` | Model dan store bottom sheet, blocker, snackbar | Setiap screen menampilkan transient/global-on-screen state |
| `Core/CoreGuards` | Internet monitor, call observer, integrity adapter, root blocker reason | App-level condition harus menutup seluruh navigation content |
| `DesignSystem` | Color/spacing/radius/typography, reusable controls, logo placeholder, tab/nav style, `ScreenScaffold` | Semua SwiftUI screen |
| `FeatureSplash` | Splash UI, startup inquiry, launch decision, retry/maintenance/force-update | Cold launch sebelum masuk pre-login/main |
| `FeatureAuth` | Username, password, validation/login UseCase, `AuthFlowView` + `AuthRoute` | Pre-login dan autentikasi |
| `FeatureMain` | Composition boundary lima tab, `MainFlowView` + `MainRoute` | Setelah autentikasi berhasil |
| `FeatureDashboard` | Dashboard inquiry, hero/menu/balance/transaction UI | Tab Beranda |
| `FeatureTransfer` | Daftar penerima, nominal, confirmation, submit UseCase, `TransferScreen` | Route `.transfer` dari Dashboard |
| `FeatureFinancial` | Portfolio/product placeholder | Tab Finansial |
| `FeatureQRIS` | QR scanner shell dan camera/gallery adapter point | Tombol QRIS di tengah tab bar |
| `FeatureRewards` | Point/redeem placeholder | Tab Rewards |
| `FeatureMore` | Profile/menu/logout | Tab Lainnya |
| `FeatureTemplate` | Rule lengkap satu feature baru | Disalin saat memulai flow baru |

`FeatureMain` sengaja menjadi composition boundary yang bergantung pada seluruh tab dan `FeatureTransfer`. Feature bisnis lain tidak saling mengimpor; shared helper harus masuk ke Core atau Design System.

## 5. Navigation dengan NavigationStack

Satu flow memiliki satu `NavigationRouter<Route>`. Router hanya menyimpan array route
bertipe — tidak pernah menyimpan View, ViewModel, atau controller:

```swift
public enum MainRoute: Hashable {
    case transfer
}

NavigationStack(path: $router.path) {
    MainTabView(
        dependencies: dependencies,
        onTransfer: { [weak router] in
            guard let router, router.current != .transfer else { return }
            router.push(.transfer)
        },
        onLogout: onLogout
    )
    .toolbar(.hidden, for: .navigationBar)
    .navigationDestination(for: MainRoute.self) { route in
        destination(for: route)
    }
}
```

Aturan yang dijaga template:

- `navigationDestination(for:)` dipasang **sekali** pada root stack, tidak di dalam
  `ForEach`, `List`, atau container lazy. Memasangnya per baris membuat SwiftUI
  mendaftarkan satu destination table per baris.
- Route memakai `enum` bertipe, bukan `NavigationPath`. Tidak ada boxing `AnyHashable`,
  dan route menjadi unit-testable seperti nilai biasa.
- Route membawa **data** untuk membangun ulang layar, bukan layar itu sendiri.
- `NavigationLink(value:)` atau `router.push` — jangan `NavigationLink(destination:)`,
  karena bentuk itu membangun destination sebelum dibutuhkan.

Karena `NavigationStack` membungkus `TabView` pada Main, layar yang di-push menutupi tab
bar sama seperti `hidesBottomBarWhenPushed` sebelumnya.

### Ownership: pasangan View dan Screen

Setiap layar terdiri dari dua tipe dengan tanggung jawab berbeda:

| Tipe | Tanggung jawab | Kepemilikan ViewModel |
|---|---|---|
| `NamaView` | Render murni, menerima ViewModel | `@ObservedObject`, tidak memiliki |
| `NamaScreen` | Ownership boundary, merakit UseCase | `@StateObject`, memiliki |

```swift
public struct TransferScreen: View {
    @StateObject private var viewModel: TransferViewModel

    public init(
        repository: any TransferRepositoryProtocol,
        onFinished: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: TransferViewModel(
                submitTransfer: SubmitTransferUseCase(repository: repository),
                onFinished: onFinished
            )
        )
    }

    public var body: some View {
        TransferView(viewModel: viewModel)
    }
}
```

Pemisahan ini bukan formalitas. `@StateObject` membuat SwiftUI membangun ViewModel tepat
sekali per identitas layar, sehingga re-render tidak pernah membuat ViewModel baru, dan
pop melepas ViewModel sehingga `deinit`-nya membatalkan task yang masih berjalan.
Sementara itu `NamaView` tetap bisa dipreview dan diuji dengan ViewModel buatan sendiri.

Argumen `StateObject(wrappedValue:)` adalah `@autoclosure`, jadi ekspresi pembuatan
ViewModel hanya dievaluasi pada render pertama — bukan setiap kali `body` dievaluasi.

### Root state bukan navigation

Perpindahan Splash -> Pre-login -> Main **bukan** push/pop. `AppCoordinator` mengubah
`rootState.content`, lalu `AppRootView` menukar seluruh flow. SwiftUI membongkar flow lama
berikut router, screen, dan ViewModel-nya, jadi tidak ada child coordinator yang perlu
dilepas secara manual.

## 6. Bottom sheet, blocker, dan snackbar di setiap halaman

Setiap ViewModel memiliki satu `ScreenPresentationStore`, kemudian View dibungkus oleh `ScreenScaffold`:

```swift
@MainActor
final class ExampleViewModel: ObservableObject {
    let presentation = ScreenPresentationStore()

    func handlePresentationAction(_ id: String) {
        switch id {
        case "confirm": performAction()
        case "retry": retryInquiry()
        default: break
        }
    }
}

ScreenScaffold(
    presentation: viewModel.presentation,
    style: .standard,
    onAction: viewModel.handlePresentationAction
) {
    ScreenContent()
}
```

### Bottom sheet dengan custom action

```swift
presentation.present(
    bottomSheet: BottomSheetModel(
        iconSystemName: "arrow.left.arrow.right.circle.fill",
        title: "Konfirmasi transfer",
        message: "Lanjutkan transaksi?",
        actions: [
            PresentationAction(id: "confirm", title: "Lanjut"),
            PresentationAction(
                id: "cancel",
                title: "Periksa Lagi",
                role: .secondary
            )
        ],
        isDismissible: true
    )
)
```

### Blocker saat inquiry/error

```swift
presentation.present(
    blocker: ScreenBlockerModel(
        title: "Inquiry gagal",
        message: error.localizedDescription,
        actions: [
            PresentationAction(id: "retry", title: "Coba Lagi"),
            PresentationAction(id: "dismiss", title: "Tutup", role: .secondary)
        ]
    )
)
```

### Snackbar

```swift
presentation.show(
    snackbar: SnackbarModel(
        message: "Data berhasil disimpan",
        iconSystemName: "checkmark.circle.fill",
        duration: 3
    )
)
```

Action disimpan sebagai string ID, bukan closure di model presentation. Pola ini menghindari cycle `ViewModel -> Store -> closure -> ViewModel`. Closure handler hanya dimiliki oleh View yang mengikuti lifecycle screen.

## 7. Root blocker

`RootGuardMonitor` memberi prioritas:

1. Compromised/rooted device.
2. Panggilan aktif.
3. Tidak ada internet.

Implementasi:

- Internet: `NWPathMonitor`.
- Call: `CXCallObserver`.
- Device integrity: protocol `DeviceIntegrityChecking`.

Checker root bawaan hanya launch-argument adapter untuk demo, karena pemeriksaan file sederhana bukan proteksi jailbreak yang memadai. Production wajib mengganti `LaunchArgumentDeviceIntegrityChecker` dengan RASP/device-integrity SDK resmi perusahaan.

Root blocker tidak mem-pop screen. Ketika kondisi pulih, overlay dilepas dan flow melanjutkan dari state sebelumnya.

Pada cold launch, compromised-device dan active-call result yang tersedia sinkron akan menahan pembuatan Splash flow/inquiry sampai root gate aman. Setelah initial flow dimulai, perubahan internet/call menggunakan overlay tanpa merusak navigation stack.

## 8. Network infrastructure

### Versi dan komponen

Template menggunakan Alamofire `5.12.0` dengan request setup lazy. Urutan request:

```text
Endpoint<Decodable & Sendable>
  -> JSONEncoder / URLQueryItem
  -> AuthenticationInterceptor (Bearer)
  -> RequestHeaderAdapter (metadata + fresh signature)
  -> request.authenticate(with: clientCertificateCredential)
  -> validate 2xx
  -> JSONDecoder
  -> Domain mapping di Remote Repository
```

Auth adapter dijalankan sebelum signature adapter. Setelah token di-refresh, Alamofire mengulang seluruh adaptation sehingga `Authorization`, timestamp, dan signature selalu konsisten.

### Pengganti struktur service lama

| Pola lama | Pengganti di template | Alasan |
|---|---|---|
| `BaseService.request(... Any ...)` | `APIClient.request(Endpoint<Response>)` | Compile-time response type dan async/await |
| `responseJSON` | `serializingData` + `JSONDecoder` | Tidak ada `Any`/ObjectMapper |
| `ObjectMapper` | DTO `Encodable`/`Decodable` | Native, testable, type-safe |
| Subclass Alamofire `Session` | Satu configured `Session` | Ownership dan queue lebih sederhana |
| Custom delegate memanggil challenge sender dan completion | Lazy request + `.authenticate(with: URLCredential)` | Satu jalur challenge, menghindari double handling |
| Manual `attemptCounter` per service | `AuthenticationInterceptor` + `RefreshWindow` | Request 401 diantre dan refresh storm dibatasi |
| Global `NotificationCenter` unauthorized | Typed unauthorized callback ke `AppCoordinator` | Ownership route eksplisit dan mudah diuji |
| Global singleton token di feature | `OAuthCredential` di composition/network layer | Feature hanya mengenal domain/APIClient |
| Header/signature dirakit di setiap service | `RequestHeaderAdapter` + `RequestSigning` | Konsisten dan diulang saat retry |
| Dynatrace hard-coded di BaseService | `NetworkTracing` adapter | Bisa dihubungkan ke Dynatrace/APM tanpa CoreNetwork bergantung pada SDK |

### Membuat inquiry Codable

DTO tetap private di Remote Repository agar tidak bocor ke domain:

```swift
private struct AccountInquiryDTO: Decodable, Sendable {
    let accountNumber: String
    let availableBalance: Decimal
}

public func inquireAccount() async throws -> AccountSummary {
    let endpoint = Endpoint<AccountInquiryDTO>(
        path: "/v1/accounts/summary",
        method: .get,
        authorization: .bearer,
        signature: .required
    )
    let dto = try await apiClient.request(endpoint)
    return AccountSummary(
        accountNumber: dto.accountNumber,
        balance: dto.availableBalance
    )
}
```

`JSONDecoder` dan `JSONEncoder` memakai snake-case conversion dan ISO-8601 date strategy. Encoder juga memakai sorted keys agar raw JSON body deterministik saat ikut ditandatangani. Sesuaikan secara terpusat di `AlamofireAPIClient` bila contract backend berbeda.

### Download

Untuk unduhan gunakan capability terpisah:

```swift
let fileURL = try await downloader.download(
    DownloadEndpoint(
        path: "/v1/statements/monthly",
        authorization: .bearer,
        signature: .required
    )
)
```

File diarahkan ke Caches dan previous file dengan nama yang sama diganti.

## 9. mTLS

Ya, inquiry Splash dan seluruh remote inquiry dapat memakai mTLS pada infra baru. `MTLSConfiguration` berlaku untuk host API yang di-allowlist, termasuk endpoint Splash, Login, Dashboard, Transfer, download, dan OAuth token.

### Cara mengaktifkan

1. Sediakan identity PKCS#12 (`.p12`) lewat mekanisme aman perusahaan. Untuk demo dapat dimasukkan ke app target; untuk production sebaiknya di-inject CI/MDM dan jangan di-commit.
2. Pastikan file masuk ke Copy Bundle Resources.
3. Isi nama file tanpa ekstensi pada `MTLS_CERTIFICATE_NAME`.
4. Ubah `MTLS_ENABLED` menjadi `true`.
5. Implementasikan `AppSecretProviding` dengan Keychain/secure configuration perusahaan.
6. Inject implementasi tersebut saat membuat `AppCoordinator`.
7. Jalankan dengan live service dan uji pada device/staging server yang benar-benar meminta client certificate.

Contoh composition adapter:

```swift
struct CompanySecrets: AppSecretProviding {
    func clientID() throws -> String {
        try SecureConfig.value(for: "oauth_client_id")
    }

    func clientSecret() throws -> String {
        try SecureConfig.value(for: "oauth_client_secret")
    }

    func mtlsPassword() throws -> String {
        try SecureConfig.value(for: "mtls_password")
    }

    func apiKey() -> String? {
        try? SecureConfig.value(for: "api_key")
    }

    func sign(_ input: RequestSigningInput) throws -> String? {
        try CompanyRequestSigner.sign(input)
    }
}

let coordinator = AppCoordinator(
    window: window,
    configuration: AppConfiguration.load(),
    secrets: CompanySecrets(),
    networkTracer: CompanyNetworkTracer(),
    initialCredential: restoredCredentialFromKeychain
)
```

`SecureConfig`, `CompanyRequestSigner`, `CompanyNetworkTracer`, dan `restoredCredentialFromKeychain` pada contoh adalah adapter/state milik perusahaan dan sengaja tidak ada di repository ini.

Karena request adaptation dan refresh dapat berjalan pada queue berbeda, concrete secret/signer/tracer adapter harus memenuhi kontrak `Sendable` dan menjaga mutable state secara thread-safe.

`PKCS12ClientCredentialProvider`:

- Membaca PKCS#12 hanya untuk host API yang diizinkan.
- Mengimpor identity dan certificate chain dengan Security framework.
- Menyimpan hasil `URLCredential` hanya di memory untuk satu app session.
- Gagal secara eksplisit jika mTLS berstatus required tetapi credential tidak tersedia/invalid.
- Menolak request mTLS required yang tidak memakai HTTPS.
- Fail closed ketika mTLS diaktifkan tetapi certificate name/credential tidak tersedia atau host berada di luar allowlist.
- Tidak pernah mencetak password, token, header authorization, signature, atau response body.

Session hanya mengikuti redirect yang tetap berada pada scheme, host, dan effective port base API yang sama. Cross-origin redirect ditolak agar Bearer header dan client identity tidak berpindah ke origin lain.

Jika identity berasal langsung dari Keychain/MDM dan bukan bundle `.p12`, buat implementation `ClientCredentialProviding` sendiri lalu gunakan pada `MTLSConfiguration`.

Penting: mTLS/client certificate berbeda dari server certificate pinning. Template tetap memakai platform server-trust default. Jika security policy mewajibkan pinning, tambahkan `ServerTrustManager`/evaluator resmi secara terpisah; jangan memakai evaluator yang menerima seluruh certificate.

## 10. Authentication, refresh, header, dan signature

### Bearer token

Endpoint memilih kebutuhan auth secara eksplisit:

```swift
authorization: .none               // login/public
authorization: .bearerIfAvailable  // splash/session bootstrap
authorization: .bearer             // dashboard/transfer/private
```

`.bearerIfAvailable` memasang dan me-refresh credential bila sesi dipulihkan dari Keychain, tetapi tetap mengizinkan first-install Splash inquiry tanpa credential. `.bearer` memakai fail-fast `AuthenticationInterceptor` bila credential tidak tersedia.

Setelah login, `AppCoordinator` membentuk `OAuthCredential`, menyimpannya di `AppSessionStore`, dan memasangnya ke `AlamofireAPIClient`.

`AppSessionStore` pada template sengaja hanya in-memory. Jika aplikasi harus memulihkan sesi setelah relaunch, tambahkan adapter Keychain milik perusahaan dan seed credential yang masih valid di composition root sebelum keputusan Splash diterapkan. Jangan masuk ke Main hanya berdasarkan flag server tanpa local credential yang tervalidasi.

### Controlled refresh

`AuthenticationInterceptor`:

- Mengantrikan request ketika satu refresh sedang berjalan.
- Membatasi refresh maksimum dua kali dalam jendela 30 detik.
- Memasang credential baru dan retry request asli.
- Menjalankan ulang header/signature adapter setelah refresh.
- Memperbarui `AppSessionStore` tanpa mengubah session ID.
- Mengirim typed unauthorized callback ke `AppCoordinator` bila refresh/retry akhirnya tetap gagal; redirect ke Pre-login hanya dilakukan saat root sedang berada di Main.

Default refresher mengikuti pola service lama: OAuth `client_credentials` dengan Basic Authorization dan mTLS. Bila backend menggunakan `refresh_token`, ubah body pada `ClientCredentialsTokenRefresher` atau buat implementation `TokenRefreshing` baru.

Konfigurasikan `AUTH_FAILURE_HEADER` dan `AUTH_FAILURE_VALUE` jika backend memberi marker khusus untuk access-token expiry. Ini penting agar 401 milik business/downstream service tidak selalu dianggap sebagai alasan refresh token.

### Request header dan signature

`RequestHeaderAdapter` menyediakan:

- Request ID.
- Platform.
- App version.
- Accept language.
- Session ID.
- Channel.
- API key.
- Timestamp dan signature.

Nama header tersentral di `RequestHeaderNames`. Ganti nilainya sesuai header confidential perusahaan tanpa mengubah feature.

Implementation signer perusahaan wajib mendefinisikan canonicalization secara eksplisit: normalisasi method/path/query, pilih dan sort header yang ditandatangani, gunakan timestamp dari input, serta hash body yang sudah encoded. Jangan mengandalkan urutan iterasi Swift `Dictionary`.

Signature memiliki tiga mode:

- `.none`: tidak dihitung.
- `.ifAvailable`: dipasang jika signer menghasilkan nilai.
- `.required`: request gagal sebelum dikirim bila signature tidak tersedia.

Dashboard dan Transfer memakai `.required`; Splash dan Login memakai `.ifAvailable` agar dapat menyesuaikan contract pre-auth.

## 11. Network tracing/APM

`NetworkTracing` memisahkan CoreNetwork dari Dynatrace atau APM lain:

```swift
let tracer = ClosureNetworkTracer { context in
    CompanyTrace(
        requestID: context.requestID,
        method: context.method,
        url: context.url
    )
}
```

Implementasi `NetworkTrace.finish(statusCode:error:)` harus menghentikan tracker tepat satu kali. Jangan kirim access token, certificate, request body sensitif, atau full response ke telemetry.

Tanpa adapter perusahaan, `NoOpNetworkTracer` dipakai. `AppLogger.network` tetap mencetak request ID, HTTP method, path, dan status secara privacy-aware.

## 12. Konfigurasi live service

Nilai non-secret ada di `App/Resources/Info.plist`:

| Key | Kegunaan | Default |
|---|---|---|
| `API_BASE_URL` | Base URL seluruh endpoint | `https://api.example.com` |
| `USE_MOCK_SERVICES` | Memilih repository mock/live | `true` |
| `MTLS_ENABLED` | Mengaktifkan client certificate required | `false` |
| `MTLS_CERTIFICATE_NAME` | Nama resource `.p12` tanpa ekstensi | kosong |
| `OAUTH_TOKEN_PATH` | OAuth client-credentials endpoint | `/oauth2/token` |
| `SPLASH_INQUIRY_PATH` | Startup inquiry endpoint | `/v1/app/bootstrap` |
| `API_CHANNEL` | Header channel | `mobile` |
| `AUTH_FAILURE_HEADER` | Marker header token expiry | kosong |
| `AUTH_FAILURE_VALUE` | Marker value token expiry | kosong |
| `APP_STORE_URL` | Tujuan blocker force update | kosong |

Langkah live mode:

1. Ganti base URL dan path staging.
2. Sesuaikan DTO di Remote Repository dengan contract aktual.
3. Implementasikan secrets, signer, dan tracer adapter.
4. Pasang `.p12`/Keychain identity dan aktifkan mTLS.
5. Ubah `USE_MOCK_SERVICES` ke `false` atau aktifkan launch argument `-useLiveServices`.
6. Pastikan protected endpoint memakai `.bearer` dan policy signature yang tepat.
7. Uji error envelope, token expiry, timeout, cancellation, offline, dan certificate rotation.

Jangan simpan client ID/secret, API key, access token, certificate password, private key, atau production signing material di Info.plist/repository.

## 13. Splash inquiry pada infra baru

`FeatureSplash` sudah melakukan inquiry nyata melalui infra baru:

```text
SplashView.onAppear
  -> SplashViewModel.startIfNeeded()
      -> PrepareLaunchUseCase.execute()
          ├─ minimum splash display 700 ms
          └─ SplashRepository.inquireLaunchState()
               -> APIClient.request(Endpoint<SplashInquiryDTO>)
```

Minimum display timer dan network inquiry berjalan paralel, bukan berurutan. Jika service selesai cepat, logo tetap stabil; jika service lambat, app tidak menambah delay kedua.

Response placeholder:

```json
{
  "next_route": "preLogin",
  "is_maintenance": false,
  "force_update": false,
  "is_authenticated": false,
  "message": null
}
```

Mapping keputusan:

- `force_update == true` -> blocker wajib update.
- `is_maintenance == true` -> blocker maintenance + retry.
- `is_authenticated == true` atau `next_route == "main"` -> Main hanya jika local credential tersedia; jika tidak, kembali ke Pre-login.
- Selain itu -> Pre-login.
- Transport/decode/service error -> blocker error + retry.

`onAppear` idempotent sehingga SwiftUI re-render tidak mengirim inquiry berulang. Task dibatalkan saat ViewModel dilepas.

## 14. Dashboard ke Transfer

Menu Transfer pada Dashboard tidak memakai `NavigationLink(destination:)`:

```text
Dashboard button
  -> DashboardViewModel.onTransfer
  -> router.push(.transfer)
  -> NavigationStack membangun TransferScreen
  -> Transfer selesai/Back/swipe
  -> route dilepas dari path
  -> TransferScreen + TransferViewModel deinit
```

Transfer screen menyediakan tab jenis transfer, search, penerima baru, favorite recipient, amount input, confirmation bottom sheet, validation snackbar, service error blocker, dan submit UseCase.

## 15. Rule membuat halaman/feature baru

Salin `Packages/FeatureTemplate`, lalu ikuti rule ini:

1. Buat satu local package untuk satu bounded feature/flow.
2. Definisikan domain model dan repository protocol.
3. Buat satu UseCase per business intent.
4. Buat Remote Repository untuk DTO/endpoint dan Mock Repository untuk demo/test.
5. Buat ViewModel `@MainActor final` dengan `ScreenPresentationStore` dan `LifecycleProbe`.
6. Simpan long-running `Task`, gunakan `[weak self]`, dan cancel di `deinit`.
7. Buat `FeatureNameStyle.swift` untuk konstanta visual khusus halaman.
8. Ambil color, typography, spacing, radius, button, field, dan card dasar dari `DesignSystem`.
9. Bungkus View dengan `ScreenScaffold`.
10. Buat `NamaScreen` dengan `@StateObject` sebagai ownership boundary ViewModel.
11. Tambahkan case pada route enum flow jika layar perlu di-push; callback ViewModel menangkap router dengan `[weak router]`.
12. Tambahkan package hanya ke composition boundary yang memakainya.
13. Tambahkan test UseCase, mapping, retry, dan presentation state penting.
14. Jalankan architecture check, unit test, Memory Graph, Leaks, Time Profiler, dan Core Animation.

File Style hanya boleh menyimpan visual constant/composition; jangan menaruh network, state, navigation, atau business rule di sana. Dengan kontrak ini, feature baru memiliki bentuk yang konsisten tetapi tetap dapat mempunyai identitas visual sendiri.

Definition of done screen:

- Tidak ada `NavigationView` maupun `NavigationLink(destination:)`.
- `navigationDestination(for:)` hanya dipasang sekali pada root stack.
- ViewModel dibuat lewat `@StateObject` di `NamaScreen`, bukan di dalam closure destination.
- View/ViewModel tidak mengimpor Alamofire.
- ViewModel tidak mengimpor UIKit.
- Loading, empty, success, dan error state terdefinisi.
- `onAppear` idempotent.
- Task dapat dibatalkan.
- Bottom sheet, blocker, dan snackbar tersedia melalui scaffold.
- Dynamic Type, VoiceOver, keyboard, safe area, dan dark mode diuji.
- Back dan interactive-pop mengembalikan jumlah ViewModel ke baseline.

## 16. Memory leak guard

Ownership rule:

- `SceneDelegate` strong-own `AppCoordinator`.
- `AppCoordinator` tidak memiliki satu pun flow; ia hanya mengubah `rootState`.
- `NavigationRouter` hanya memiliki array route bertipe nilai — tidak pernah View atau ViewModel.
- `NamaScreen` memiliki ViewModel-nya lewat `@StateObject`; SwiftUI melepasnya saat route dipop.
- ViewModel tidak memiliki router; callback ke router memakai `[weak router]`.
- Snackbar dan network task dibatalkan pada `deinit` ViewModel.

Arah kepemilikan berjalan satu arah dan tidak membentuk cycle:

```text
AppCoordinator  ->  rootState (nilai)
NavigationRouter ->  [Route] (nilai)
NamaScreen      ->  ViewModel  ->  closure -> [weak router]
```

Debug guard:

- `LifecycleProbe` log `INIT`/`DEINIT` untuk ViewModel dan router.
- `NavigationRouter` log `PUSH`/`POP` pada kategori navigation, termasuk pop yang dilakukan
  SwiftUI sendiri lewat tombol Back atau swipe.
- `LeakWatchdog` tersedia untuk dipanggil manual pada titik yang Anda tahu sebuah object
  seharusnya sudah dilepas. Template tidak memanggilnya otomatis per layar: `onDisappear`
  milik SwiftUI tidak dapat membedakan layar yang dipop dari layar yang tertimbun push
  berikutnya, sehingga wiring otomatis akan menghasilkan false positive.
- Launch argument `-assertLeaks` mengubah warning `LeakWatchdog` menjadi DEBUG assertion,
  dan hanya berpengaruh pada pemanggilan manual tersebut.
- `AppLogger` membagi kategori app/navigation/network/lifecycle/performance/security.

Cara membaca log: satu baris `POP` harus diikuti `DEINIT` milik ViewModel layar tersebut.
`POP` tanpa `DEINIT` adalah tanda layar masih tertahan.

Logger tidak menjamin aplikasi bebas leak; lakukan Dashboard -> Transfer -> Back minimal 10 kali dan pastikan instance kembali ke baseline pada Xcode Memory Graph dan Instruments Leaks.

## 17. Target performance 60 FPS

Target 60 Hz memiliki frame budget sekitar 16,67 ms. Template menyediakan guardrail, bukan janji bahwa seluruh feature masa depan selalu 60 FPS:

- Destination dibangun hanya saat route di-push, bukan saat layar asal dirender.
- `navigationDestination(for:)` didaftarkan sekali per stack, tidak per baris list.
- Route memakai enum bertipe, bukan `NavigationPath`, sehingga tidak ada boxing `AnyHashable`.
- ViewModel dibuat sekali lewat `@StateObject`, jadi re-render tidak merakit ulang UseCase.
- Tidak ada `AnyView` pada hot path.
- List panjang memakai `LazyVStack`/`LazyVGrid`.
- Tidak ada image decoding, formatter berat, atau JSON parsing di `body`.
- Network/decode berjalan di luar render pass; state UI diterapkan pada MainActor.
- Animasi presentation singkat dan tidak memakai blur berat.
- `PerformanceTracer` menghasilkan Points of Interest signpost.
- Launch argument `-showFPS` menampilkan FPS dan hitch badge.

Verifikasi pada device fisik:

1. Record Time Profiler + Core Animation pada cold launch, switch tab, Dashboard -> Transfer, dan Back.
2. Periksa hitch/frame time, bukan hanya FPS rata-rata.
3. Uji response besar dan low-power mode.
4. Pindahkan transformasi/formatting berat dari main actor.
5. Resize/cache approved promotional images sesuai display size.
6. Uji dengan SDK security/APM production karena overhead-nya tidak ada pada mock template.

## 18. Launch arguments untuk QA

| Argument | Hasil |
|---|---|
| `-showFPS` | Menampilkan FPS/hitch badge |
| `-assertLeaks` | DEBUG assertion jika object yang dilaporkan ke `LeakWatchdog` belum deinit setelah grace period |
| `-simulateRootedDevice` | Menampilkan compromised-device root blocker |
| `-simulateActiveCall` | Menampilkan active-call root blocker |
| `-simulateSplashFailure` | Splash inquiry mock gagal dan menampilkan retry blocker |
| `-simulateMaintenance` | Splash menampilkan maintenance blocker |
| `-simulateForceUpdate` | Splash menampilkan force-update blocker |
| `-useLiveServices` | Memaksa Remote Repository walau mock default aktif |

Untuk no-internet blocker, gunakan Network Link Conditioner, matikan koneksi pada device, atau uji adapter `NWPathMonitor` melalui integration test.

## 19. Check dan test

```bash
make check
xcodebuild \
  -project ModularBank.xcodeproj \
  -scheme ModularBank \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Jalankan test target dari package `Core`, `FeatureSplash`, `FeatureAuth`, `FeatureDashboard`, dan `FeatureTemplate` melalui Xcode Package navigator/scheme masing-masing. Ini menjaga test tetap tinggal bersama micropackage yang dimilikinya.

Unit test contoh tersedia untuk:

- Presentation store.
- Navigation router: push, pop, popToRoot, dan pop yang dipicu SwiftUI sendiri.
- Authenticator Bearer/header failure marker.
- Required-mTLS fail-fast saat credential tidak tersedia.
- Splash launch decision.
- Username validation.
- Dashboard summary UseCase.

Sesuaikan nama simulator dengan runtime yang terpasang.

## 20. Checklist sebelum production

- Ganti placeholder logo/illustration dengan approved asset dan periksa lisensi.
- Ganti seluruh endpoint/DTO placeholder dengan contract backend.
- Inject secrets dari Keychain/secure configuration, bukan source/Info.plist.
- Validasi PKCS#12 rotation, expiry, revocation, dan staging/production host allowlist.
- Tambahkan server pinning hanya jika policy perusahaan mewajibkan dan sediakan rotation plan.
- Konfigurasikan marker 401 untuk membedakan token expiry dari business authorization failure.
- Hubungkan network tracer ke APM tanpa merekam data sensitif.
- Ganti root checker demo dengan RASP/device integrity SDK resmi.
- Implementasikan camera/gallery permission untuk QRIS.
- Implementasikan LocalAuthentication untuk biometric action.
- Tambahkan localization dan accessibility audit.
- Jalankan unit/UI/security test, Instruments, dan test pada device minimum-supported.

## 21. Dokumen tambahan

- `Docs/ARCHITECTURE.md` — dependency direction dan ownership.
- `Docs/API_CONTRACT.md` — placeholder contract Codable.
- `Docs/NEW_FEATURE_GUIDE.md` — checklist feature baru.
- `Docs/PERFORMANCE_AND_LEAKS.md` — prosedur Instruments.
- `Docs/SWIFT_CONCURRENCY.md` — `async`/`await`, `Task`, `@MainActor`, dan `Sendable` untuk pembaca yang terbiasa GCD.
- `Docs/CODE_MAP.md` — kegunaan setiap file, dan apa yang rusak kalau file itu dihapus.
- `Docs/FROM_IOS13.md` — untuk yang sudah menulis SwiftUI sejak iOS 13: beda `@StateObject` vs `@ObservedObject`, `NavigationStack`, `Task`, `@MainActor`, `Sendable`, dan lima keluhan lama (layar blank, `onAppear` dobel, object tidak deinit, whitelist routing, cold launch).
- `Docs/SCALING.md` — rancangan untuk ratusan layar: dependency per feature, deep link, dan cara menahan composition boundary agar tidak jadi god module.

Referensi upstream:

- Alamofire releases: <https://github.com/Alamofire/Alamofire/releases>
- Alamofire documentation: <https://alamofire.github.io/Alamofire/>
- Apple authentication challenges: <https://developer.apple.com/documentation/foundation/handling-an-authentication-challenge>
- Apple identity import: <https://developer.apple.com/documentation/security/importing-an-identity>
