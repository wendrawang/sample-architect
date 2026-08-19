# Swift Concurrency untuk Developer iOS Generasi GCD

Dokumen ini menjelaskan istilah yang muncul di seluruh template — `async`, `await`,
`Task`, `@MainActor`, `Sendable`, `actor` — untuk pembaca yang terbiasa dengan
`DispatchQueue`, completion handler, dan `[weak self]`.

Semua contoh diambil dari kode di repository ini.

## 1. Masalah lama yang ingin diselesaikan

Dulu aturan thread-safety hanya ada di kepala kita dan di komentar:

```swift
// HARUS dipanggil dari main thread!
func updateUI() { ... }
```

Compiler tidak tahu apa-apa. Kalau ada yang memanggilnya dari background queue,
aplikasi crash atau — lebih buruk — hanya kadang-kadang rusak. Bug seperti ini muncul
di production, sulit direproduksi, dan biasanya baru ketahuan dari laporan pengguna.

Swift Concurrency memindahkan aturan itu dari komentar ke **tipe**, sehingga compiler
bisa menolaknya sebelum aplikasi jalan. Itulah asal semua error yang Anda temui saat
naik ke Swift 6: bukan kode Anda berubah, tapi compiler mulai menagih janji yang
selama ini hanya tertulis di komentar.

## 2. `async` / `await` — pengganti completion handler

Dulu:

```swift
func login(username: String, password: String,
           completion: @escaping (Result<AuthSession, Error>) -> Void)
```

Sekarang (`AuthDomain.swift`):

```swift
func login(username: String, password: String) async throws -> AuthSession
```

`async` artinya "fungsi ini bisa berhenti di tengah jalan lalu dilanjutkan nanti".
`await` adalah titik berhentinya. Selama menunggu, thread **tidak diblokir** — dia
mengerjakan pekerjaan lain, lalu kembali ke sini saat hasilnya siap.

Keuntungan praktisnya: tidak ada lagi nested closure, error lewat `throw` biasa, dan
`return` yang kelupaan di dalam completion handler tidak mungkin terjadi lagi.

## 3. `Task` — pengganti `DispatchQueue.async`

`Task` adalah jembatan dari dunia sinkron ke dunia `async`. Kira-kira setara
`DispatchQueue.global().async { }`, tapi dengan dua kemampuan tambahan yang dipakai
template ini.

**Bisa dibatalkan.** Setiap ViewModel menyimpan task-nya dan membatalkannya saat
dilepas (`PasswordViewModel.swift`):

```swift
private var loginTask: Task<Void, Never>?

deinit {
    loginTask?.cancel()
}
```

Ketika pengguna menekan Back di tengah proses login, request-nya ikut berhenti.
Dengan `DispatchQueue` dulu, closure tetap jalan sampai selesai lalu menulis ke
object yang sudah tidak ada di layar.

**Mewarisi isolation.** Task yang dibuat di dalam class `@MainActor` otomatis
berjalan di main actor. Ini penting, dan menjadi sumber satu error yang kita temui —
lihat bagian 5.

## 4. `@MainActor` — "ini harus di main thread", tapi dicek compiler

Dulu:

```swift
DispatchQueue.main.async {
    self.label.text = "..."   // semoga tidak ada yang lupa
}
```

Sekarang (`ScreenPresentationStore.swift`):

```swift
@MainActor
public final class ScreenPresentationStore: ObservableObject {
```

Semua property dan method di dalamnya kini **hanya boleh** diakses dari main thread.
Kalau ada kode background yang mencoba menyentuhnya, itu error compile, bukan crash
runtime.

Di template ini `@MainActor` dipakai untuk: semua ViewModel, `ScreenPresentationStore`,
`NavigationRouter`, `AppCoordinator`, dan `FrameRateMonitor`. Semuanya memang murni
urusan UI.

Konsekuensinya: memanggil method `@MainActor` dari konteks non-isolated butuh `await`,
karena harus berpindah thread dulu. Perpindahan itu namanya **actor hop**.

## 5. Actor hop dan jebakan `await self?.method()`

Ini error nyata yang muncul di `AppCoordinator`:

```swift
// ❌ gagal compile: "No exact matches in call to initializer"
apiClient.setUnauthorizedHandler { [weak self] in
    Task { [weak self] in
        await self?.handleUnauthorizedSession()
    }
}
```

`setUnauthorizedHandler` menerima closure `@Sendable`, artinya bisa dipanggil dari
thread mana saja. Task di dalamnya karena itu **tidak mewarisi** main actor. Jadi
`handleUnauthorizedSession()` perlu `await` untuk hop ke main.

Masalahnya, `await self?.method()` meminta compiler melakukan dua hal dalam satu
ekspresi: berpindah actor **dan** membuka optional. Type checker menyerah, lalu
melapor pada `Task.init` yang sebenarnya tidak salah.

```swift
// ✅ isolation ditentukan di awal, hop terjadi saat task mulai
apiClient.setUnauthorizedHandler { [weak self] in
    Task { @MainActor in
        self?.handleUnauthorizedSession()
    }
}
```

Aturan praktis: kalau isi task memang urusan UI, tulis `Task { @MainActor in }` dan
jangan pakai `await` pada optional chain.

## 6. `Sendable` — "aman dipindah antar thread"

Sebuah tipe `Sendable` kalau membawanya dari satu thread ke thread lain tidak bisa
menimbulkan data race.

| Kategori | Sendable? | Alasan |
|---|---|---|
| `String`, `Int`, `Bool`, `UUID` | ✅ | value type, disalin bukan dibagi |
| `struct` berisi anggota Sendable | ✅ | ikut aman |
| `enum` tanpa associated value bermasalah | ✅ | sama |
| `class` biasa | ❌ | dibagi, siapa pun bisa mengubah |
| `class` yang `@MainActor` | ✅ | aksesnya diserialkan actor |
| `NumberFormatter`, `CADisplayLink` | ❌ | class mutable dari framework |

### Kenapa tipe `public` tidak dapat Sendable otomatis

Ini yang bikin `ScreenStyle` error padahal isinya cuma `Color` dan `CGFloat`:

```swift
public struct ScreenStyle: Sendable {   // ← harus ditulis sendiri
```

Untuk tipe `internal`, compiler menyimpulkan `Sendable` sendiri. Untuk tipe `public`,
dia menolak — karena `Sendable` adalah **bagian dari kontrak API**. Kalau compiler
memberikannya diam-diam, lalu suatu hari Anda menambah satu property non-Sendable,
konformansi itu hilang dan semua modul pemakai ikut rusak tanpa peringatan. Jadi
Swift menuntut Anda menyatakannya secara sadar.

### `@unchecked Sendable` dan `nonisolated(unsafe)`

Dua pintu darurat, untuk kasus di mana Anda tahu aman tapi compiler tidak bisa
membuktikannya.

`@unchecked Sendable` — "saya sudah menjamin thread-safety-nya sendiri".
`AppSessionStore.swift` memakai `NSLock` di setiap akses:

```swift
final class AppSessionStore: @unchecked Sendable {
    private let lock = NSLock()
    ...
}
```

`nonisolated(unsafe)` — untuk satu property saja. `FrameRateMonitor.swift`:

```swift
private nonisolated(unsafe) var displayLink: CADisplayLink?
```

`deinit` bersifat nonisolated sehingga tidak boleh membaca property main-actor
bertipe non-Sendable. Tapi `deinit` hanya berjalan setelah referensi terakhir hilang,
jadi tidak ada yang bisa menyentuh link itu bersamaan.

Keduanya mematikan pemeriksaan compiler. Pakai hanya kalau Anda bisa menjelaskan
alasannya dalam satu kalimat — dan tulis kalimat itu sebagai komentar, seperti yang
dilakukan di seluruh template ini.

## 7. `actor` — class yang mengantre aksesnya sendiri

`actor` adalah reference type yang menjamin hanya satu tugas mengakses state-nya pada
satu waktu. Anggap saja class yang punya `DispatchQueue` serial bawaan.

```swift
actor TokenStore {
    private var token: String?
    func update(_ new: String) { token = new }   // otomatis aman
}
```

**Template ini tidak memakai `actor` sama sekali.** Kebutuhan serialisasinya sudah
dijawab oleh `@MainActor` (untuk UI) dan `NSLock` (untuk `AppSessionStore`). Tidak
perlu menambahkan actor hanya karena tersedia — setiap actor menambah titik `await`
dan hop yang harus dipikirkan.

## 8. Peta cepat istilah

| Dulu | Sekarang |
|---|---|
| `completion: @escaping (Result<T, Error>) -> Void` | `async throws -> T` |
| `DispatchQueue.global().async { }` | `Task { }` |
| `DispatchQueue.main.async { }` | `Task { @MainActor in }` |
| Komentar "panggil dari main thread" | `@MainActor` |
| "Object ini aman dishare" (harapan) | `Sendable` (dijamin compiler) |
| `DispatchQueue` serial untuk lindungi state | `actor` |
| Membatalkan operasi | `task.cancel()` + `Task.isCancelled` |

## 9. Kalau Anda menemui error Sendable baru

Urutan yang paling sering menyelesaikannya:

1. Tipe `public` berisi value type semua → tambahkan `: Sendable`.
2. Class yang isinya murni UI → tambahkan `@MainActor`.
3. Class dengan state yang Anda lindungi sendiri pakai lock → `@unchecked Sendable`.
4. Satu property yang hanya dibaca dan tidak pernah diubah → `nonisolated(unsafe)`.
5. Butuh state termutasi yang dipakai banyak thread → jadikan `actor`.

Jangan mulai dari nomor 3. Sebagian besar error sebenarnya selesai di nomor 1 atau 2,
dan itu perbaikan yang benar-benar aman, bukan sekadar mendiamkan compiler.
