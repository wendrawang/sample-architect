# Rancangan untuk Skala Ratusan Layar

Template ini sehat pada 10 layar. Tiga hal di bawah akan menjadi masalah jauh sebelum
layar ke-100, dan ketiganya jauh lebih murah diselesaikan sekarang.

Dokumen ini **rancangan**, belum diterapkan ke kode. Setiap bagian berisi masalahnya,
desainnya, kode konkretnya, apa yang didapat, dan ongkosnya — supaya Anda bisa menolak
bagian yang menurut Anda belum perlu.

Urutan penerapan yang saya sarankan: **3 → 2 → 1**. Nomor 3 paling murah dan langsung
terasa; nomor 1 paling besar dan baru mendesak setelah layar yang bisa di-push bertambah.

---

## Gap 3 — Dependency yang tidak menskala

### Masalahnya

```swift
public struct MainDependencies: Sendable {
    let dashboardRepository: any DashboardRepositoryProtocol
    let transferRepository: any TransferRepositoryProtocol
}
```

Tiga hal memburuk seiring pertumbuhan:

1. **Struct tumbuh tanpa batas.** Lima puluh layar berarti struct berisi puluhan field,
   dan setiap penambahan feature mengubah file yang sama — magnet konflik merge.
2. **Semua dibangun di awal.** `MainDependencies.make(...)` membuat *seluruh* repository
   saat login selesai, termasuk milik layar yang mungkin tidak pernah dibuka. Ini ikut
   membebani perpindahan ke Main.
3. **Composition root harus kenal semua tipe konkret.** `FeatureMain` meng-`import`
   `FeatureDashboard` dan `FeatureTransfer` hanya untuk menyebut nama repository-nya.

### Desain: setiap feature mendeklarasikan kebutuhannya sendiri

Balik arahnya. Bukan composition root yang menyodorkan struct berisi segalanya,
melainkan **feature yang menyatakan apa yang ia butuhkan**, lewat protokol miliknya.

```swift
// Packages/FeatureDashboard/Sources/FeatureDashboard/DashboardDomain.swift
public protocol DashboardDependencies: Sendable {
    func makeDashboardRepository() -> any DashboardRepositoryProtocol
}
```

```swift
// Packages/FeatureTransfer/Sources/FeatureTransfer/TransferDomain.swift
public protocol TransferDependencies: Sendable {
    func makeTransferRepository() -> any TransferRepositoryProtocol
}
```

Composition root punya **satu** object yang memenuhi semua protokol itu:

```swift
// App/AppDependencies.swift
final class AppDependencies: Sendable {
    private let apiClient: any APIClient
    private let useMocks: Bool

    init(apiClient: any APIClient, useMocks: Bool) {
        self.apiClient = apiClient
        self.useMocks = useMocks
    }
}

extension AppDependencies: DashboardDependencies {
    func makeDashboardRepository() -> any DashboardRepositoryProtocol {
        useMocks
            ? MockDashboardRepository()
            : RemoteDashboardRepository(apiClient: apiClient)
    }
}

extension AppDependencies: TransferDependencies {
    func makeTransferRepository() -> any TransferRepositoryProtocol {
        useMocks
            ? MockTransferRepository()
            : RemoteTransferRepository(apiClient: apiClient)
    }
}
```

Flow menyebut kebutuhannya lewat komposisi protokol — tipe parameternya **menjadi
dokumentasi**:

```swift
public struct MainFlowView: View {
    private let dependencies: any DashboardDependencies & TransferDependencies
}
```

### Yang didapat

- **Menambah feature tidak menyentuh file bersama.** Cukup satu protokol baru di package
  feature, dan satu `extension` baru di App. Tidak ada struct pusat yang diedit ramai-ramai.
- **Malas secara alami.** Repository dibuat saat layar dibuat, bukan saat login. Layar
  yang tidak pernah dibuka tidak pernah membayar apa pun.
- **Test feature cukup memenuhi protokolnya sendiri**, bukan membangun seluruh graf
  dependency aplikasi.
- **Compiler yang menagih.** Lupa menambahkan `extension` di App berarti build gagal,
  bukan crash saat runtime.

### Ongkosnya

Satu protokol tambahan per feature. Untuk feature yang butuh banyak dependency,
protokolnya berisi beberapa method — masih jauh lebih ringan daripada satu struct
berisi lima puluh field.

---

## Gap 2 — Deep link dan navigasi lintas flow

### Masalahnya

Route berupa `enum` per flow. Belum ada jalan dari sebuah URL atau push notification
menuju layar spesifik di dalam flow tertentu. Di aplikasi ratusan layar ini kebutuhan
harian, dan kalau ditambal belakangan biasanya jadi `if` bertingkat di `SceneDelegate`.

### Desain: deep link sebagai data murni, resolusi di composition root

**Langkah 1 — deep link tidak tahu apa-apa soal View.** Ia hanya nilai, jadi bisa diuji
tanpa UI sama sekali.

```swift
// Packages/Core/Sources/CoreNavigation/DeepLink.swift
public struct DeepLink: Hashable, Sendable {
    public let segments: [String]
    public let query: [String: String]

    public init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme != nil else { return nil }

        segments = components.path
            .split(separator: "/")
            .map(String.init)
        query = Dictionary(
            (components.queryItems ?? []).compactMap { item in
                item.value.map { (item.name, $0) }
            },
            uniquingKeysWith: { first, _ in first }
        )
    }
}
```

**Langkah 2 — setiap flow memetakan deep link ke path-nya sendiri.** Tidak ada registry
pusat, jadi tidak ada file yang harus diingat untuk diperbarui.

```swift
// Packages/FeatureMain/Sources/FeatureMain/MainFlowView.swift
extension MainRoute {
    public static func path(for link: DeepLink) -> [MainRoute] {
        switch link.segments.first {
        case "transfer": return [.transfer]
        default:         return []
        }
    }
}
```

**Langkah 3 — router bisa dimulai dari path awal.**

```swift
// NavigationRouter
public init(initialPath: [Route] = []) {
    ...
    path = initialPath
}
```

**Langkah 4 — composition root yang memutuskan, termasuk soal autentikasi.** Ini bagian
terpenting: gating auth ada di **satu** tempat, bukan tersebar di tiap layar.

```swift
// AppCoordinator
private var pendingDeepLink: DeepLink?

func handle(_ link: DeepLink) {
    guard sessionStore.currentCredential() != nil else {
        pendingDeepLink = link      // simpan dulu, jalankan setelah login berhasil
        showPreLogin()
        return
    }
    rootState.deepLink = link
    showMain()
}

func handleAuthenticated(_ session: AuthSession) {
    // ... simpan credential seperti sekarang ...
    rootState.deepLink = pendingDeepLink
    pendingDeepLink = nil
    showMain()
}
```

```swift
// AppRootView
case .main:
    MainFlowView(
        dependencies: coordinator.dependencies,
        initialPath: coordinator.rootState.deepLink.map(MainRoute.path(for:)) ?? [],
        onLogout: coordinator.handleLogout
    )
```

### Yang didapat

- **Bisa diuji tanpa UI.** `XCTAssertEqual(MainRoute.path(for: link), [.transfer])`
  adalah test biasa, tanpa simulator dan tanpa layar.
- **Auth gating tidak mungkin terlupa**, karena hanya ada satu jalur masuk.
- **Tidak ada registry pusat.** Tiap flow memetakan URL-nya sendiri, sehingga menambah
  deep link baru tidak menyentuh file milik flow lain.
- **Deep link yang tidak dikenal jatuh ke root**, bukan crash atau layar kosong.

### Ongkosnya

Satu tipe baru di Core dan satu `static func path(for:)` per flow. `SceneDelegate` perlu
meneruskan `url` masuk ke `coordinator.handle(_:)`.

---

## Gap 1 — `FeatureMain` yang tumbuh jadi god module

### Masalahnya

`FeatureMain` sekarang meng-`import` tujuh package. Perlu dibedakan dua jenis import,
karena hanya satu yang berbahaya:

| Jenis | Contoh | Tumbuh? |
|---|---|---|
| Tab yang **dirender** | Dashboard, Financial, QRIS, Rewards, More | ❌ Tidak. Lima tab tetap lima tab. |
| Layar yang **di-push** | Transfer | ✅ Ya. Bertambah tiap ada layar baru yang bisa dituju. |

Jadi masalahnya bukan "FeatureMain meng-import banyak", melainkan **FeatureMain harus
meng-import setiap layar yang bisa di-push dari dalamnya**. Di layar ke-80, ia
meng-import hampir seluruh aplikasi, ikut rebuild setiap kali salah satunya berubah,
dan menjadi satu-satunya pintu bagi semua navigasi lintas fitur.

### Desain: destination dibangun di composition root

`@ViewBuilder` bisa dipakai pada parameter closure. `switch` di dalamnya menghasilkan
satu tipe konkret (`_ConditionalContent`), jadi **tidak perlu `AnyView`** dan aturan
arsitektur tetap terjaga.

```swift
// FeatureMain — tidak lagi meng-import FeatureTransfer
public struct MainFlowView<Destination: View>: View {
    @StateObject private var router: NavigationRouter<MainRoute>

    private let dependencies: any DashboardDependencies
    private let onLogout: () -> Void
    private let destination: (MainRoute) -> Destination

    public init(
        dependencies: any DashboardDependencies,
        initialPath: [MainRoute] = [],
        onLogout: @escaping () -> Void,
        @ViewBuilder destination: @escaping (MainRoute) -> Destination
    ) {
        _router = StateObject(wrappedValue: NavigationRouter(initialPath: initialPath))
        self.dependencies = dependencies
        self.onLogout = onLogout
        self.destination = destination
    }

    public var body: some View {
        NavigationStack(path: $router.path) {
            MainTabView(dependencies: dependencies, onIntent: handle)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: MainRoute.self, destination: destination)
        }
    }
}
```

Composition root yang menyediakan isinya:

```swift
// App/AppRootView.swift — App memang sudah tahu semua feature, dan itu tugasnya
MainFlowView(
    dependencies: coordinator.dependencies,
    onLogout: coordinator.handleLogout
) { route in
    switch route {
    case .transfer:
        TransferScreen(
            repository: coordinator.dependencies.makeTransferRepository(),
            onFinished: { }
        )
        .navigationTitle("Transfer")
    }
}
```

### Intent menggantikan tumpukan closure

Bagian kedua dari gap yang sama. Sekarang setiap kemampuan baru menambah satu parameter
closure:

```swift
MainTabView(dependencies:, onTransfer:, onLogout:)
// nanti: onTransfer, onLogout, onQRIS, onProfile, onHistory, onSettings, ...
```

Ganti dengan satu `enum`, sehingga menambah kemampuan tidak mengubah signature:

```swift
public enum MainIntent: Sendable {
    case openTransfer
    case logout
}

MainTabView(dependencies: dependencies, onIntent: handle)
```

```swift
private func handle(_ intent: MainIntent) {
    switch intent {
    case .openTransfer:
        guard router.current != .transfer else { return }
        router.push(.transfer)
    case .logout:
        onLogout()
    }
}
```

**Aturan yang dijaga:** intent selalu **naik**, tidak pernah **menyamping**. Feature
tidak pernah meng-import feature lain; ia hanya menyatakan maksud, dan yang menyusunnya
di atas sana yang memutuskan artinya. Kalau tujuannya ada di flow lain, intent itu naik
terus sampai `AppCoordinator`, yang bisa mengubah root state sekaligus menyemai path.

### Yang didapat

- **Import `FeatureMain` berhenti tumbuh.** Ia hanya mengenal lima tab yang dirender,
  selamanya. Layar yang bisa di-push tidak lagi menjadi urusannya.
- **Rebuild lebih sempit.** Mengubah `FeatureTransfer` tidak lagi memaksa `FeatureMain`
  ikut dikompilasi ulang.
- **`switch` tetap exhaustive**, jadi menambah case route tanpa menanganinya tetap gagal
  saat build.
- **Menambah kemampuan tidak mengubah signature**, jadi tidak ada lagi init berisi
  sepuluh closure.

### Ongkosnya

`MainFlowView` menjadi generik atas `Destination`. Ini menular ke pemanggilnya, tapi
hanya satu tempat — composition root. Dan `enum MainIntent` adalah satu tipe tambahan
per flow.

---

## Kapan menerapkan yang mana

| Gap | Terapkan saat | Kenapa jangan sekarang-sekarang amat |
|---|---|---|
| 3 — dependency | **Sekarang.** Murah, dan langsung memperbaiki eager-loading saat masuk Main. | Tidak ada alasan menunda. |
| 2 — deep link | Saat kebutuhan deep link atau push notification pertama muncul. | Menebak bentuk URL sebelum ada requirement biasanya salah. |
| 1 — god module | Saat layar yang bisa di-push dari Main melewati tiga atau empat. | Pada satu layar push, generik `Destination` menambah rumit tanpa imbalan. |

Ketiganya berdiri sendiri. Menerapkan gap 3 tidak memaksa Anda menerapkan gap 1.

---

## Yang **tidak** perlu diubah

Supaya jelas batasnya, ini bagian yang sudah menskala dan sebaiknya dibiarkan:

- Route bertipe dengan `switch` exhaustive.
- `ScreenPresentationStore` per layar — tidak ada global UI state yang bisa bertabrakan.
- Pasangan `NamaView` dan `NamaScreen`.
- `CoreNetwork` yang terpusat. Dua ratus layar tetap satu tempat untuk auth, signing,
  dan mTLS.
- Batas package yang ditegakkan compiler dan `Scripts/check_architecture.sh`.
