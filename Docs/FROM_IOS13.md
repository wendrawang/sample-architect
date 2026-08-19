# Dari iOS 13 / Swift 5 ke Template Ini

Dokumen ini untuk pembaca yang sudah lama menulis iOS dengan UIKit, Storyboard,
delegate, dan `DispatchQueue`, lalu menemukan template ini penuh istilah asing.

Formatnya selalu sama: **dulu Anda menulis apa**, **sekarang jadi apa**, dan
**kenapa berubah**. Kalau alasannya tidak meyakinkan Anda, katakan — tidak semua
perubahan wajib diikuti.

Dua dokumen pendamping:

- `Docs/SWIFT_CONCURRENCY.md` — `async`/`await`, `Task`, `@MainActor`, `Sendable`.
- `README.md` bagian 8 — tabel pengganti `BaseService`, `ObjectMapper`, `responseJSON`.

---

## 1. Property wrapper: yang paling sering salah

Ini bagian terpenting untuk Anda. Di iOS 13, SwiftUI **belum punya `@StateObject`** —
baru ada di iOS 14. Jadi banyak tutorial lama mengajarkan `@ObservedObject` untuk
segalanya, dan kebiasaan itu sekarang menjadi bug.

| Wrapper | Sejak | Artinya | Analogi UIKit |
|---|---|---|---|
| `@State` | iOS 13 | Nilai sederhana milik View (`Bool`, `String`). | Property biasa di ViewController. |
| `@Binding` | iOS 13 | Pinjaman *dua arah* ke `@State` milik orang lain. | `inout`, atau delegate untuk melapor balik. |
| `@ObservedObject` | iOS 13 | View **memakai** object, tapi tidak memilikinya. | Property `weak var` ke object milik orang lain. |
| `@StateObject` | **iOS 14** | View **memiliki** object. Dibuat sekali seumur hidup View. | `let viewModel = ...` di `init` ViewController. |
| `@Published` | iOS 13 | Property yang otomatis memberi tahu View kalau berubah. | Manual panggil `tableView.reloadData()`. |
| `@EnvironmentObject` | iOS 13 | Object yang diturunkan ke seluruh anak View. | Singleton, tapi terbatas pada subtree. |

### Kenapa salah pakai `@ObservedObject` itu fatal

```swift
// ❌ SALAH — ViewModel lahir ulang setiap kali body dievaluasi
struct TransferView: View {
    @ObservedObject var viewModel = TransferViewModel(...)
}
```

Struct View di SwiftUI **dibuat ulang terus-menerus** — puluhan kali per detik saat
scroll. Itu normal dan murah, karena View hanyalah deskripsi, bukan object di layar.

Tapi `@ObservedObject` tidak menyimpan apa pun. Jadi setiap kali View dibuat ulang,
`TransferViewModel(...)` dijalankan lagi: nominal yang sudah diketik hilang, request
yang sedang jalan ditinggalkan, dan `deinit` menumpuk.

```swift
// ✅ BENAR — SwiftUI menyimpan object ini, dibuat tepat sekali
struct TransferScreen: View {
    @StateObject private var viewModel: TransferViewModel
}
```

`@StateObject` menyimpan object di luar struct View, di penyimpanan internal SwiftUI
yang terikat pada *identitas* layar, bukan pada struct-nya. Inilah alasan template ini
memisahkan `NamaScreen` (yang punya `@StateObject`) dari `NamaView` (yang cuma
menerima `@ObservedObject`).

**Cara mengingat:** yang membuat, pakai `@StateObject`. Yang menerima, pakai
`@ObservedObject`.

---

## 2. ViewController → View + ViewModel

Dulu satu `UIViewController` memegang semuanya:

```swift
final class TransferViewController: UIViewController {
    @IBOutlet weak var amountField: UITextField!
    var service = TransferService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        amountField.delegate = self
    }

    @IBAction func submitTapped() {
        service.submit(...) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                // ...
            }
        }
    }
}
```

Sekarang dipecah tiga:

```swift
// TransferView.swift — hanya menggambar
TextField("Nominal", text: $viewModel.amount)
PrimaryButton("Lanjut", isLoading: viewModel.isLoading, action: viewModel.didTapReview)

// TransferViewModel.swift — hanya state, tidak tahu UIKit
@Published public var amount = ""
@Published public private(set) var isLoading = false

// SubmitTransferUseCase.swift — hanya aturan bisnis
func execute(destinationAccount: String, amountText: String) async throws -> TransferReceipt
```

**Kenapa:** ViewController lama tidak bisa dites tanpa membuat layar. ViewModel bisa
dites sebagai object biasa, dan UseCase bahkan tidak butuh UI sama sekali. Yang
tersisa di View cuma tata letak — bagian yang memang paling baik diperiksa dengan mata.

`$viewModel.amount` itu `@Binding`: tanda `$` berarti "beri saya jalur dua arah ke
property ini", pengganti `textFieldDidChange`.

---

## 3. Delegate → closure

Dulu, mengirim hasil kembali ke pemanggil butuh protokol:

```swift
protocol PasswordViewControllerDelegate: AnyObject {
    func passwordViewController(_ vc: PasswordViewController, didAuthenticate session: AuthSession)
}

weak var delegate: PasswordViewControllerDelegate?
```

Sekarang cukup closure (`PasswordViewModel.swift`):

```swift
private let onAuthenticated: (AuthSession) -> Void
```

**Kenapa:** protokol delegate butuh tiga tempat (deklarasi, property `weak`,
implementasi di sisi lain) untuk menyampaikan satu kejadian. Closure cuma satu baris,
dan tipenya sudah menjelaskan apa yang dikirim.

**Yang tetap sama:** aturan `[weak self]`. Dulu `weak var delegate` mencegah siklus;
sekarang `[weak self]` di dalam closure yang melakukannya. Bahayanya identik — closure
yang menangkap `self` secara kuat lalu disimpan sebagai property adalah retain cycle,
persis seperti `var delegate` yang lupa `weak`.

Delegate masih tepat kalau satu pihak perlu melaporkan **banyak** kejadian berbeda.
Untuk satu kejadian, closure lebih ringan.

---

## 4. NotificationCenter global → callback bertipe

Dulu, sesi kedaluwarsa biasanya disiarkan ke seluruh aplikasi:

```swift
NotificationCenter.default.post(name: .unauthorized, object: nil)
```

Sekarang (`AppCoordinator.swift`):

```swift
apiClient.setUnauthorizedHandler { [weak self] in
    Task { @MainActor in self?.handleUnauthorizedSession() }
}
```

**Kenapa:** dengan `NotificationCenter`, tidak ada satu pun tempat di kode yang bisa
menjawab "siapa yang menangani ini?". Jawabannya baru ketahuan saat runtime, dan kalau
dua layar sama-sama mendengarkan, dua-duanya bereaksi. Callback bertipe punya tepat
satu pemilik, terlihat di `AppCoordinator`, dan bisa dites.

---

## 5. UINavigationController → NavigationStack

Dulu navigasi adalah perintah:

```swift
let vc = TransferViewController()
vc.hidesBottomBarWhenPushed = true
navigationController?.pushViewController(vc, animated: true)
```

Sekarang navigasi adalah **data** (`MainFlowView.swift`):

```swift
enum MainRoute: Hashable, Sendable {
    case transfer
}

router.push(.transfer)     // hanya menambah nilai ke array
```

```swift
NavigationStack(path: $router.path) {
    MainTabView(...)
        .navigationDestination(for: MainRoute.self) { route in
            destination(for: route)          // route mana → layar apa
        }
}
```

**Kenapa:** `push(vc)` berarti Anda menyerahkan **object layar yang sudah jadi**. Siapa
pun yang memegang referensi ke object itu bisa menahannya hidup setelah di-pop — sumber
memory leak paling umum di pola coordinator lama.

`router.push(.transfer)` cuma menambah nilai `enum` ke sebuah array. Router tidak
pernah memegang layar. Saat route dihapus dari array, SwiftUI membongkar layarnya, dan
tidak ada yang tersisa untuk bocor.

Efek sampingnya: back stack Anda sekarang bisa dicetak, disimpan, dan dites.

```swift
XCTAssertEqual(router.path, [.transfer])   // mustahil dilakukan pada UINavigationController
```

---

## 6. Coordinator + childCoordinators → flow view + router

Pola coordinator lama butuh pembukuan manual:

```swift
final class MainCoordinator {
    var childCoordinators: [Coordinator] = []

    func showTransfer() {
        let child = TransferCoordinator(navigationController: nav)
        childCoordinators.append(child)          // ingat menambah
        child.parent = self
        child.start()
    }

    func childDidFinish(_ child: Coordinator) {
        childCoordinators.removeAll { $0 === child }   // dan ingat menghapus
    }
}
```

Kalau `childDidFinish` tidak terpanggil — misalnya pengguna swipe-back, bukan menekan
tombol Back — coordinator itu bocor bersama seluruh ViewModel-nya.

Sekarang tidak ada pembukuan sama sekali. `AppCoordinator` hanya mengubah `rootState`,
dan SwiftUI membongkar flow lama berikut router dan ViewModel-nya. Yang dulu Anda kerjakan
dengan disiplin, sekarang dikerjakan oleh kepemilikan view tree.

---

## 7. Singleton → injeksi di composition root

Dulu:

```swift
TransferService.shared.submit(...)
```

Sekarang dependency masuk lewat `init`, dan satu-satunya tempat yang memilih
implementasi konkret adalah `AppCoordinator`:

```swift
if configuration.useMockServices {
    authRepository = MockAuthRepository()
} else {
    authRepository = RemoteAuthRepository(apiClient: apiClient)
}
```

**Kenapa:** dengan singleton, mustahil menjalankan test tanpa jaringan, dan mustahil
menjalankan aplikasi demo tanpa backend. Di template ini keduanya cukup dengan
mengubah satu flag. `FeatureAuth` bahkan tidak tahu ada yang namanya mock — ia hanya
tahu protokol `AuthRepositoryProtocol`.

---

## 8. Satu project besar → local Swift Package per flow

Dulu semua file ada di satu target `.xcodeproj`, dan `internal` berarti "terlihat oleh
seluruh aplikasi". Tidak ada yang mencegah layar Transfer memanggil isi layar Dashboard.

Sekarang setiap flow adalah package sendiri, dan batasnya dipaksakan compiler: kalau
`FeatureTransfer` tidak mencantumkan `FeatureDashboard` sebagai dependency, `import`-nya
tidak akan bisa.

Tambahannya, `project.yml` + XcodeGen berarti **`.xcodeproj` tidak lagi di-commit**.
File itu di-generate. Konflik merge pada `project.pbxproj` — yang dulu rutin terjadi
setiap kali dua orang menambah file — hilang sepenuhnya.

Konsekuensi yang harus Anda ingat: setelah clone, jalankan `make project` dulu.

---

## 9. Threading

Ini dibahas lengkap di `Docs/SWIFT_CONCURRENCY.md`. Ringkasnya:

| Dulu | Sekarang |
|---|---|
| `DispatchQueue.main.async { }` | `@MainActor` pada class atau fungsi |
| `DispatchQueue.global().async { }` | `Task { }` |
| completion handler | `async` / `await` |
| komentar `// harus di main thread` | dicek compiler, gagal saat build |
| `// tidak thread-safe, hati-hati` | `Sendable` |

Perbedaan pentingnya: dulu aturan thread hanya ada di kepala Anda dan di komentar.
Sekarang aturan itu ada di tipe, dan compiler menolak kode yang melanggarnya sebelum
aplikasi sempat jalan. Semua error Swift 6 yang Anda temui saat migrasi adalah tagihan
dari janji-janji yang selama ini hanya tertulis di komentar.

---

## 10. Yang **tidak** berubah

Supaya seimbang — banyak yang Anda kuasai tetap berlaku:

- MVVM, UseCase, Repository. Pemisahan lapisan tidak berubah sama sekali.
- Aturan kepemilikan dan `[weak self]`. Retain cycle masih retain cycle.
- Instruments: Time Profiler, Allocations, Leaks, Core Animation. Tetap alat utama.
- Naluri performa Anda. "Jangan parsing JSON di jalur render" dulu berlaku untuk
  `cellForRowAt`, sekarang berlaku untuk `body`. Alasannya sama persis: fungsi itu
  dipanggil sangat sering, jadi harus murah.
- Codable, URLSession, Keychain, mTLS, request signing. Tidak ada yang berubah.

Yang berubah pada dasarnya cuma dua: **siapa yang memiliki layar** (dulu Anda,
sekarang view tree), dan **siapa yang menegakkan aturan thread** (dulu komentar,
sekarang compiler).
