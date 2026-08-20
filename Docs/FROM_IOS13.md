# Dari SwiftUI iOS 13 ke SwiftUI iOS 16 + Swift 6

Untuk pembaca yang sudah menulis SwiftUI sejak iOS 13 dengan `@State`, `@Binding`,
`@ObservedObject`, dan `@EnvironmentObject` — lalu menemukan template ini penuh istilah
yang belum pernah dipakai: `@StateObject`, `Task`, `@MainActor`, `Sendable`.

Anda tidak ketinggalan sejauh yang Anda kira. Yang berubah sejak iOS 13 sebenarnya cuma
tiga hal:

1. **Kepemilikan object** jadi eksplisit (`@StateObject`).
2. **Navigasi** jadi data, bukan perintah (`NavigationStack`).
3. **Aturan thread** pindah dari kepala Anda ke compiler (`@MainActor`, `Sendable`).

Sisanya sama persis.

---

## 1. `@StateObject` — satu-satunya property wrapper baru yang wajib Anda pahami

Di iOS 13 `@StateObject` **belum ada**. Baru muncul di iOS 14. Jadi kalau Anda belajar
SwiftUI di era iOS 13, Anda diajarkan `@ObservedObject` untuk segalanya — dan itu
memang satu-satunya pilihan waktu itu.

Masalahnya, `@ObservedObject` tidak pernah dimaksudkan untuk *membuat* object.

```swift
// Cara iOS 13 yang dulu terpaksa dipakai
struct TransferView: View {
    @ObservedObject var viewModel = TransferViewModel()
}
```

Struct `View` di SwiftUI dibuat ulang terus-menerus — puluhan kali per detik saat
scroll. Itu normal dan murah, karena `View` cuma *deskripsi*, bukan object di layar.

Tapi `@ObservedObject` **tidak menyimpan apa pun**. Ia hanya "mengamati" object yang
diberikan. Jadi setiap kali struct View dibuat ulang, `TransferViewModel()` ikut
dijalankan lagi:

- nominal yang sudah diketik hilang,
- request yang sedang jalan ditinggalkan,
- instance ViewModel menumpuk.

```swift
// Cara sekarang
struct TransferScreen: View {
    @StateObject private var viewModel: TransferViewModel
}
```

`@StateObject` menyimpan object di penyimpanan internal SwiftUI yang terikat pada
**identitas layar**, bukan pada struct View. Dibuat tepat sekali, bertahan selama layar
itu ada, dilepas saat layar hilang.

**Aturannya satu kalimat:** yang **membuat** object pakai `@StateObject`; yang cuma
**menerima** object pakai `@ObservedObject`.

Itulah — dan hanya itu — alasan template ini memisahkan `NamaScreen` dari `NamaView`:

```swift
struct TransferScreen: View {                    // yang MEMILIKI
    @StateObject private var viewModel: TransferViewModel
    var body: some View { TransferView(viewModel: viewModel) }
}

struct TransferView: View {                      // yang MERENDER
    @ObservedObject private var viewModel: TransferViewModel
}
```

Property wrapper lain yang Anda sudah pakai tidak berubah sama sekali: `@State`,
`@Binding`, `@EnvironmentObject`, `@Published` berfungsi persis seperti di iOS 13.

---

## 2. `NavigationStack` — navigasi jadi data

Di iOS 13 navigasi SwiftUI adalah `NavigationLink` dengan `isActive`:

```swift
NavigationLink(destination: TransferView(), isActive: $showTransfer) { ... }
```

Ini sumber banyak penderitaan: destination dibangun lebih awal walaupun belum
dibuka, `isActive` gampang tidak sinkron, dan pada list panjang sering muncul layar
blank atau pop sendiri.

Sekarang path adalah array biasa:

```swift
enum MainRoute: Hashable, Sendable {
    case transfer
}

NavigationStack(path: $router.path) {
    MainTabView(...)
        .navigationDestination(for: MainRoute.self) { route in
            switch route {
            case .transfer: TransferScreen(...)
            }
        }
}

router.push(.transfer)      // cuma menambah nilai ke array
```

Tiga hal yang berubah drastis:

- **Tidak ada lagi `isActive`.** Tidak ada boolean yang bisa tidak sinkron.
- **Destination dibangun saat dibutuhkan**, bukan saat layar asal dirender.
- **Back stack bisa dites.** `XCTAssertEqual(router.path, [.transfer])` — mustahil
  dilakukan dulu.

`switch` di `navigationDestination` bersifat **exhaustive**. Tambah satu case di enum
tanpa menanganinya, dan build gagal. Ini penting; lihat bagian 5.

---

## 3. `Task` — pengganti `DispatchQueue`

`Task` adalah kotak untuk menjalankan kode `async`. Padanan kasarnya
`DispatchQueue.global().async { }`, dengan dua kemampuan tambahan.

**Bisa dibatalkan:**

```swift
private var loginTask: Task<Void, Never>?

func didTapLogin() {
    loginTask?.cancel()                    // batalkan yang lama
    loginTask = Task { [weak self] in
        let session = try await useCase.execute(...)
        guard !Task.isCancelled else { return }
        self?.finishLogin(with: session)
    }
}

deinit { loginTask?.cancel() }             // layar ditutup, request dihentikan
```

Dulu untuk membatalkan `URLSessionDataTask` Anda harus menyimpan referensinya sendiri
dan ingat memanggil `cancel()` di banyak jalur keluar. Sekarang polanya seragam.

**Mewarisi thread dari tempat pembuatannya.** `Task` yang dibuat di dalam class
`@MainActor` otomatis jalan di main thread. Anda tidak perlu menulis
`DispatchQueue.main.async` lagi setelah `await` selesai — itu sebabnya di kode di atas
`self?.finishLogin(...)` langsung dipanggil tanpa hop manual.

---

## 4. `@MainActor` dan `Sendable` — aturan thread yang dicek compiler

Ini yang paling terasa asing, jadi pelan-pelan.

### Masalah yang ingin diselesaikan

Dulu aturan thread hanya hidup di komentar:

```swift
// HARUS dipanggil dari main thread!
func updateUI() { ... }
```

Compiler tidak tahu apa-apa soal komentar itu. Kalau ada yang memanggilnya dari
background, aplikasi crash — atau lebih buruk, cuma kadang-kadang rusak, di perangkat
pengguna, yang tidak bisa Anda reproduksi.

### `@MainActor` = "kode ini cuma boleh jalan di main thread"

```swift
@MainActor
public final class TransferViewModel: ObservableObject { ... }
```

Satu label di atas class, dan seluruh isinya terikat main thread. Bedanya dengan
komentar: **compiler menolak** siapa pun yang memanggil dari thread lain tanpa `await`.

Dulu Anda menulis `DispatchQueue.main.async { }` berkali-kali karena tidak yakin sedang
di thread mana. Sekarang Anda menandai sekali di class, dan compiler yang menjaga.

### `Sendable` = "nilai ini aman dipindah antar thread"

Anggap saja stempel. Compiler memakainya untuk menolak kode yang memindahkan benda
tidak aman antar thread.

| Tipe | Aman dipindah? | Kenapa |
|---|---|---|
| `struct` isi `String`, `Int`, `Bool` | ✅ ya | Dicopy saat dipindah, tidak ada yang berbagi |
| `enum` tanpa payload aneh | ✅ ya | Sama, nilai |
| `class` dengan `var` mutable | ❌ tidak | Dua thread bisa menulis bersamaan |
| `class` dengan `@MainActor` | ✅ ya | Semua akses diantre di main thread |
| `NumberFormatter`, `CADisplayLink` | ❌ tidak | Class mutable milik Apple |

Kenapa terasa asing padahal sudah lama ada: di Swift 5 stempel ini **tidak ditagih**.
Aturannya ada, tapi tidak ada yang memeriksa. Swift 6 mulai memeriksa. Kode Anda tidak
berubah — yang berubah cuma siapa yang menagih.

### Satu jebakan: tipe `public` tidak dapat stempel otomatis

```swift
public struct ScreenStyle {          // ❌ error di static let
    public let background: Color
    public let horizontalPadding: CGFloat

    public static let standard = ScreenStyle()
}
```

Isinya `Color` dan `CGFloat` yang dua-duanya aman. Tapi Swift **tidak pernah**
menyimpulkan `Sendable` otomatis untuk tipe `public`, karena konformansi itu bagian
dari kontrak API Anda — kalau suatu hari Anda menambah satu property tidak aman,
stempel itu hilang diam-diam dan semua modul yang memakainya rusak.

Perbaikannya satu kata:

```swift
public struct ScreenStyle: Sendable { ... }
```

Untuk `struct` internal, Swift menyimpulkannya sendiri. Jadi aturan praktisnya: **tiap
tipe `public` yang isinya nilai, tulis `Sendable` sekalian.**

---

## 5. Lima keluhan lama, dan apa yang menanganinya di sini

Bagian ini menjawab masalah nyata, bukan teori.

### a. Layar tiba-tiba blank

Penyebab tersering di era iOS 13–15: `NavigationLink` + `isActive` yang tidak sinkron,
`AnyView` yang menghapus type identity sehingga SwiftUI salah membongkar view, dan
ViewModel yang lahir ulang karena `@ObservedObject`.

Di sini: tidak ada `isActive` (path berupa array), `AnyView` dilarang oleh
`Scripts/check_architecture.sh`, dan ViewModel dipegang `@StateObject`.

**Bukan jaminan.** `NavigationStack` punya bug sendiri. Tapi tiga penyebab paling umum
itu memang hilang secara struktural.

### b. `onAppear` bolak-balik, analytics visit jadi tidak valid

Ini yang paling penting. `onAppear` di SwiftUI **memang** dipanggil berkali-kali:
saat re-render, saat kembali dari background, saat pindah tab, saat layar di atasnya
di-pop. Menembakkan analytics dari `onAppear` pasti menghasilkan angka yang membengkak.

Template ini membuat `onAppear` idempotent supaya *inquiry* tidak berulang:

```swift
public func onAppear() {
    guard content == nil, task == nil else { return }   // sudah jalan, jangan ulangi
    load()
}
```

Tapi untuk **analytics**, cara yang benar bukan `onAppear` sama sekali. Tembakkan dari
**perubahan path**, karena path berubah tepat sekali per navigasi:

```swift
// di NavigationRouter — satu tempat, tidak mungkin lupa, tidak mungkin dobel
public func push(_ route: Route) {
    path.append(route)
    Analytics.screenView(String(describing: route))
}
```

Ini keuntungan konkret dari navigasi berbentuk data: kejadian "pindah layar" jadi
punya satu titik yang bisa diukur. Template belum memasang ini — sengaja, karena
SDK analytics tiap perusahaan berbeda — tapi tempatnya sudah tersedia.

### c. Object tidak pernah `deinit`

Perlu diluruskan dulu: **Anda tidak perlu menulis `deinit` supaya object hilang.**
`deinit` bukan perintah "hapus" — dia hanya pemberitahuan bahwa object *sudah* dihapus.
Object hilang otomatis saat tidak ada lagi yang memegangnya.

Jadi pertanyaan yang benar bukan "apakah tiap ViewModel perlu `deinit`", melainkan
**"siapa yang masih memegang ViewModel ini?"**. Tersangka biasanya:

- closure yang menangkap `self` secara kuat, lalu disimpan sebagai property,
- ViewModel yang disimpan di singleton, cache, atau router,
- ViewModel dibuat di luar lalu dioper masuk, sementara pembuatnya hidup lebih lama.

Di template ini rantai kepemilikannya sengaja dibuat satu arah:

```text
Screen (@StateObject) → ViewModel → closure → [weak router]
Router → [Route]  (nilai, bukan object)
```

Router tidak pernah memegang layar, jadi begitu route dihapus dari array, tidak ada
yang tersisa memegang ViewModel dan ia hilang sendiri.

`deinit` tetap ditulis di ViewModel template — tapi **hanya untuk membatalkan task**,
bukan untuk menghapus apa pun:

```swift
deinit { loginTask?.cancel() }
```

Cara memeriksanya: jalankan, buka Console, filter kategori `lifecycle` dan
`navigation`. Satu baris `POP` harus diikuti `DEINIT` milik ViewModel layar itu. Kalau
`POP` ada tapi `DEINIT` tidak muncul, berarti masih ada yang memegang.

### d. Routing perlu whitelist di tiap layar, berat, gampang lupa

Kalau dulu Anda punya registry pusat tempat setiap layar harus mendaftar, dan lupa
mendaftar berarti layar itu tidak bisa dituju — masalah itu hilang di sini, karena
`switch` di `navigationDestination` bersifat **exhaustive**:

```swift
enum MainRoute: Hashable, Sendable {
    case transfer
    case history          // ← tambah case baru
}

switch route {
case .transfer: TransferScreen(...)
// tidak menangani .history → BUILD GAGAL
}
```

Lupa mendaftar berubah dari **kegagalan runtime yang sunyi** menjadi **error compile**.
Ini perbedaan besar: yang dulu baru ketahuan saat QA menekan tombol dan tidak terjadi
apa-apa, sekarang ketahuan sebelum aplikasi sempat jalan.

### f. Takut re-render: apa yang sebenarnya terjadi

Perlu diluruskan, karena mudah salah paham: **`@Published` tidak pernah memeriksa
kesamaan nilai.** Menyetel `isLoading = false` ketika nilainya memang sudah `false` tetap
mengirim `objectWillChange`, tetap membuat View invalid, dan `body` tetap dievaluasi ulang.

Membuat state `Equatable` **tidak** mengubah hal itu. Yang dibantu `Equatable` adalah
langkah berikutnya: setelah `body` dievaluasi, SwiftUI membandingkan hasilnya dengan yang
lama dan melewatkan penggambaran untuk bagian yang tidak berubah.

Jadi ada dua hal berbeda:

| Tahap | Dicegah oleh |
|---|---|
| `body` dievaluasi ulang | menjaga agar `@Published` tidak disetel ulang |
| Layar benar-benar digambar ulang | `Equatable` pada tipe yang dirender |

Kalau Anda benar-benar ingin menghentikan publish-nya, jangan menulis `if` di setiap
property — kumpulkan state layar jadi satu struct `Equatable`, lalu pasang **satu**
penjaga di jalur penyetelannya:

```swift
struct DashboardState: Equatable {
    var isLoading = false
    var summary: DashboardSummary?
}

@Published private(set) var state = DashboardState()

private func update(_ newState: DashboardState) {
    guard newState != state else { return }   // satu penjaga untuk seluruh layar
    state = newState
}
```

Sekilas soal `Equatable`: hampir semua tipe standar sudah `Equatable`, termasuk `Bool`,
`Int`, `String`, `Date`, serta `Array` dan `Optional` yang isinya `Equatable`. Struct
buatan sendiri yang seluruh property-nya `Equatable` cukup ditulis `: Equatable` dan
Swift menyusun perbandingannya sendiri.

Terakhir, dan ini yang paling sering keliru: **`body` yang dievaluasi ulang bukan masalah
performa.** `body` memang dirancang untuk sering dipanggil. Yang membuat lag hampir
selalu **kerja berat di dalam `body`** — memformat angka, mendecode gambar, menyaring
array besar. Pindahkan pekerjaan itu keluar dulu, dan ukur dengan Time Profiler sebelum
memburu jumlah re-render.

### e. Cold launch lambat karena banyak SDK

Sejujurnya, **template tidak bisa memperbaiki ini.** Kalau sepuluh SDK melakukan
inisialisasi sinkron di `didFinishLaunching`, arsitektur apa pun akan lambat.

Yang template lakukan cuma tidak memperburuk:

- `AppDelegate` sengaja tipis — hanya memasang appearance.
- Splash menjalankan timer tampil minimum dan network inquiry **paralel**, bukan
  berurutan. Kalau service cepat, logo tetap stabil; kalau lambat, aplikasi tidak
  menambah delay kedua.
- Local package default-nya static library, jadi tidak menambah beban dyld seperti
  puluhan dynamic framework.

Untuk mendiagnosis SDK Anda sendiri, ukur dulu sebelum menebak. Di scheme, tambahkan
environment variable `DYLD_PRINT_STATISTICS = 1`; Console akan mencetak berapa lama
dyld memuat framework sebelum `main()` dijalankan. Kalau angka itu besar, masalahnya
di jumlah dynamic framework. Kalau kecil tapi launch tetap lama, masalahnya di kode
inisialisasi SDK — dan itu diukur dengan Time Profiler pada cold launch.

---

## 6. Yang tidak berubah

- MVVM, pemisahan lapisan, `Codable`, `URLSession`, Keychain — sama persis.
- Aturan `[weak self]`. Retain cycle masih retain cycle.
- Instruments: Time Profiler, Allocations, Leaks, Core Animation.
- Naluri performa Anda. "Jangan kerja berat di jalur render" tetap berlaku; sekarang
  jalur itu bernama `body`.
