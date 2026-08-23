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
public struct MainTabView<DashboardDestination: View>: View {
    private let dependencies: any DashboardDependencies
}
```

Setelah gap 1 diterapkan, `MainTabView` bahkan tidak lagi menyebut `TransferDependencies`:
layar Transfer dibangun composition root, jadi kebutuhannya pun tidak lagi menular ke
shell tab bar.

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

## Gap 2 — Deep link dan navigasi lintas flow — **sudah diterapkan**

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
// Packages/FeatureDashboard/Sources/FeatureDashboard/DashboardFlowView.swift
extension DashboardRoute {
    public static func path(for link: DeepLink) -> [DashboardRoute] {
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
    MainTabView(
        dependencies: coordinator.dependencies,
        dashboardInitialPath: coordinator.rootState.deepLink.map(DashboardRoute.path(for:)) ?? [],
        onLogout: coordinator.handleLogout
    ) { route in ... }
```

### Yang didapat

- **Bisa diuji tanpa UI.** `XCTAssertEqual(DashboardRoute.path(for: link), [.transfer])`
  adalah test biasa, tanpa simulator dan tanpa layar.
- **Auth gating tidak mungkin terlupa**, karena hanya ada satu jalur masuk.
- **Tidak ada registry pusat.** Tiap flow memetakan URL-nya sendiri, sehingga menambah
  deep link baru tidak menyentuh file milik flow lain.
- **Deep link yang tidak dikenal jatuh ke root**, bukan crash atau layar kosong.

### Ongkosnya

Satu tipe baru di Core dan satu `static func path(for:)` per flow. `SceneDelegate` perlu
meneruskan `url` masuk ke `coordinator.handle(_:)`.

---

## Gap 1 — `FeatureMain` yang tumbuh jadi god module — **sudah diterapkan**

### Masalahnya

Ada dua jenis import, dan hanya satu yang berbahaya:

| Jenis | Contoh | Tumbuh? |
|---|---|---|
| Tab yang **dirender** | Dashboard, Financial, QRIS, Rewards, More | ❌ Lima tab tetap lima tab |
| Layar yang **di-push** | Transfer, detail poin, dan seterusnya | ✅ Bertambah terus |

Jadi masalahnya bukan jumlah import, melainkan bahwa `FeatureMain` harus mengenal setiap
layar yang bisa dituju dari dalamnya.

### Yang dipakai: satu stack per tab

`MainFlowView` dan `MainRoute` dihapus. Sekarang **tiap tab memiliki stack dan route-nya
sendiri**, di dalam package tab itu sendiri:

```swift
// Packages/FeatureDashboard/Sources/FeatureDashboard/DashboardFlowView.swift
public enum DashboardRoute: Hashable, Sendable {
    case transfer
}

public struct DashboardFlowView<Destination: View>: View {
    @StateObject private var router = NavigationRouter<DashboardRoute>()
    @ObservedObject private var viewModel: DashboardViewModel
    private let destination: (DashboardRoute) -> Destination

    public var body: some View {
        NavigationStack(path: $router.path) {
            DashboardView(viewModel: viewModel)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: DashboardRoute.self, destination: destination)
        }
        .onReceive(viewModel.transferRequested) { _ in
            guard router.current != .transfer else { return }
            router.push(.transfer)
        }
    }
}
```

Composition root yang membangun layar tujuannya:

```swift
// App/AppRootView.swift
MainTabView(
    dependencies: coordinator.dependencies,
    onLogout: coordinator.handleLogout
) { route in
    switch route {
    case .transfer:
        TransferScreen(dependencies: coordinator.dependencies)
            .navigationTitle("Transfer")
            .toolbar(.hidden, for: .tabBar)
    }
}
```

Empat hal yang membuat ini bekerja:

1. **`@ViewBuilder` pada parameter closure.** `switch` di sisi pemanggil menghasilkan satu
   tipe konkret, jadi tidak perlu type erasure dan `switch`-nya tetap exhaustive — lupa
   menangani case baru tetap gagal saat build.
2. **`FeatureDashboard` tidak mengimpor `FeatureTransfer`.** Ia hanya mendeklarasikan
   bahwa ada route bernama `.transfer`; yang membangun layarnya composition root.
3. **ViewModel tidak mengenal navigasi.** `DashboardViewModel` mengirim
   `transferRequested`, tanpa tahu itu route apa atau di stack mana. Flow view yang
   menerjemahkan sinyal menjadi `push`.
4. **Layar tujuan menutup dirinya sendiri.** `TransferScreen` memakai
   `@Environment(\.dismiss)`, jadi ia bisa di-push dari stack mana pun tanpa perubahan —
   tidak ada lagi closure `onFinished` yang mengikat layar pada pemanggilnya.

Tab bar tetap hilang saat push lewat `.toolbar(.hidden, for: .tabBar)` pada layar tujuan,
jadi kepemilikan route per tab tidak mengorbankan perilaku UI. Bonusnya, back stack tiap
tab jadi independen.

### Kalau tujuannya berada di tab lain

Untuk kasus seperti bottom sheet dormant account yang bisa mengarah ke layar milik tab
lain, angkat kepemilikan router satu tingkat ke `MainTabView`, lalu perpindahan tab dan
penyemaian path dilakukan bersamaan:

```swift
case .openDashboardRoute(let route):
    viewModel.selection = .dashboard
    dashboardRouter.path = [route]
}
```

Yang dijaga tetap sama: Financial tidak pernah mengimpor Dashboard. Ia hanya menyatakan
maksud, dan `MainTabView` — yang memang sudah menyusun kelima tab — yang menerjemahkan.
Karena semua perpindahan lintas tab lewat satu titik, di sinilah analytics screen-view
bisa dicatat sekali dan valid.

## Kapan menerapkan yang mana

| Gap | Status | Catatan |
|---|---|---|
| 3 — dependency | ✅ Diterapkan | Feature mendeklarasikan kebutuhannya; `AppDependencies` memenuhinya. |
| 1 — god module | ✅ Diterapkan | Satu stack per tab; layar tujuan dibangun composition root. |
| 2 — deep link | ✅ Diterapkan | `DeepLink` di CoreNavigation, pemetaan dimiliki tiap flow, gating auth di `AppCoordinator`. |

Gap 2 berdiri sendiri dan tidak bergantung pada dua lainnya.

---

## Yang **tidak** perlu diubah

Supaya jelas batasnya, ini bagian yang sudah menskala dan sebaiknya dibiarkan:

- Route bertipe dengan `switch` exhaustive.
- `ScreenPresentationStore` per layar — tidak ada global UI state yang bisa bertabrakan.
- Pasangan `NamaView` dan `NamaScreen`.
- `CoreNetwork` yang terpusat. Dua ratus layar tetap satu tempat untuk auth, signing,
  dan mTLS.
- Batas package yang ditegakkan compiler dan `Scripts/check_architecture.sh`.
