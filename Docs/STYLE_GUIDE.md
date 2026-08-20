# Style Guide: Komponen, Layar, dan Teks

Tujuan dokumen ini satu: **layar yang ditulis orang berbeda tetap terlihat dan terbaca
sama.** Bukan soal selera, tapi soal supaya reviewer bisa menilai kode tanpa berdebat
hal yang sama setiap minggu.

---

## 1. Tiga jenis View, dan hanya tiga

Setiap file View di codebase ini harus jelas masuk kategori mana.

| Jenis | Tinggal di | Punya ViewModel? | Tahu domain? |
|---|---|---|---|
| **Component** | `DesignSystem` | ❌ Tidak pernah | ❌ Tidak |
| **Screen** | package feature | ✅ Ya, lewat `@StateObject` | ✅ Ya |
| **View** & bagian-bagiannya | package feature | ❌ Menerima, tidak memiliki | ✅ Ya |

### Component tidak boleh punya ViewModel

Ini pertanyaan yang paling sering muncul, jadi dijawab tegas: **tidak, dan tidak akan
pernah.**

Component hanya menerima nilai dan closure:

```swift
public struct PrimaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let isEnabled: Bool
    private let action: () -> Void
}
```

Alasannya bukan kemurnian teori:

- Component dipakai lintas feature. Kalau ia punya ViewModel, ViewModel itu harus tahu
  konteks setiap feature — dan tidak mungkin.
- Component tanpa ViewModel bisa dipakai di Preview tanpa menyiapkan apa pun.
- ViewModel adalah object. Satu ViewModel per tombol berarti puluhan object hidup di satu
  layar, masing-masing dengan siklus hidupnya sendiri untuk dijaga.

**Satu-satunya state yang boleh dimiliki component adalah `@State` lokal untuk urusan
visual murni** — misalnya `BankInputCard` yang menyimpan apakah password sedang
ditampilkan. State itu tidak berarti apa-apa di luar tombol mata itu sendiri.

Kalau Anda merasa sebuah component butuh ViewModel, hampir selalu artinya benda itu bukan
component, melainkan Screen yang salah tempat.

### Bagian layar menerima nilai, bukan seluruh ViewModel

Ini berdampak langsung ke performa.

```swift
// ❌ Setiap perubahan @Published apa pun membuat baris ini ikut dievaluasi ulang
private func row(_ viewModel: DashboardViewModel) -> some View

// ✅ Hanya ikut berubah kalau transaction-nya benar-benar berubah
private func row(_ transaction: DashboardTransaction) -> some View
```

Mengoper seluruh ViewModel ke setiap subview membuat semuanya bergantung pada semuanya.
Mengoper nilai yang dibutuhkan saja mempersempit apa yang perlu dihitung ulang — dan
membuat subview itu bisa di-Preview sendirian.

---

## 2. Style: dari mana angka dan warna berasal

Urutannya selalu dari umum ke khusus:

```text
DesignSystem/Tokens.swift     warna, spacing, radius, tipografi   ← dipakai semua
DesignSystem/Components.swift tombol, field, card, section header ← dipakai semua
NamaFeatureStyle.swift        konstanta visual khas satu layar
```

Aturan yang ditegakkan:

1. **Tidak ada angka ajaib di dalam View.** Setiap konstanta visual khas layar masuk ke
   `NamaStyle.swift`.
2. **Tidak ada warna literal di feature.** Ambil dari `AppColor`. Kalau warnanya belum
   ada, tambahkan ke token — jangan tulis `Color(red:green:blue:)` di feature.
3. **File Style hanya berisi nilai visual.** Tidak boleh ada network, state, navigasi,
   atau aturan bisnis di sana.
4. **Setiap layar dibungkus `ScreenScaffold`.** Itu yang memberi bottom sheet, blocker,
   dan snackbar secara seragam, sehingga tidak ada layar yang punya gaya error sendiri.

Kenapa `NamaStyle.swift` dipisah dan bukan langsung di View: supaya sebuah layar boleh
punya identitas visual sendiri tanpa menyelundupkan angka ke tengah kode layout, dan
supaya designer bisa menemukan semua angka satu layar di satu tempat.

---

## 3. Localization: tidak ada string yang di-hardcode

Anda sebelumnya memakai R.swift. Penggantinya di sini **String Catalog + enum tipe aman**,
tanpa code generator dan tanpa build plugin.

### Bentuknya

```text
Packages/FeatureAuth/Sources/FeatureAuth/
  Resources/Localizable.xcstrings   ← diedit lewat editor String Catalog di Xcode
  AuthStrings.swift                 ← satu-satunya tempat key ditulis
```

```swift
enum AuthStrings {
    static var usernameTitle: String { local("auth.username.title") }

    private static func local(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: .module)
    }
}
```

```swift
Text(AuthStrings.usernameTitle)          // ✅
Text("Masuk")                            // ❌ ditolak CI
```

### Dua hal yang menentukan ini bekerja

**`bundle: .module`.** Ini yang paling sering terlewat di project modular. Tanpa itu,
Foundation mencari di `Bundle.main`, tidak menemukan apa-apa, lalu **diam-diam
mengembalikan key mentahnya sebagai teks**. Tidak crash, tidak warning — hanya tulisan
`auth.username.title` muncul di layar produksi. Setiap package punya bundle sendiri, dan
`.module` menunjuk ke bundle package tempat kode itu berada.

**Key tidak pernah ditulis di call site.** Sama seperti R.swift dulu: View memanggil
property, bukan mengetik ulang string. Salah ketik jadi error compile.

### Kenapa bukan R.swift atau SwiftGen

Keduanya masih bekerja. Tetapi keduanya adalah build tool yang harus dipasang di mesin
setiap orang dan di CI, ikut memperlambat build, dan menjadi satu hal lagi yang bisa
rusak saat naik versi Xcode. Enum di atas memberi jaminan yang sama — key salah ketik
gagal saat compile — dengan nol dependency.

Yang hilang dibanding R.swift: enum-nya ditulis tangan. Ini disengaja. Menambah satu
baris saat menambah teks adalah ongkos yang jauh lebih kecil daripada memelihara code
generator di seluruh tim.

### Penegakan

`Scripts/check_architecture.sh` menolak `Text("...")`, `Button("...")`, `Label("...")`,
dan `navigationTitle("...")` pada package yang sudah dilokalisasi. Daftar package-nya ada
di variabel `localized_sources` — **tambahkan satu baris setiap kali selesai memigrasikan
package berikutnya.**

Saat ini baru `FeatureAuth` yang selesai dan berada dalam daftar itu. Package lain masih
memakai string hardcode.

### Resep migrasi satu package

1. Buat `Sources/<Package>/Resources/Localizable.xcstrings`.
2. Tambahkan `resources: [.process("Resources")]` pada target di `Package.swift`.
3. Buat `<Nama>Strings.swift` dengan pola `local(_:)` di atas.
4. Pindahkan teks dari View **dan ViewModel** — judul bottom sheet, pesan error, dan
   judul action juga teks yang dilihat pengguna.
5. Tambahkan path package ke `localized_sources`, lalu jalankan `make check`.

### Yang **tidak** perlu dilokalisasi

Jangan berlebihan. Ini bukan teks yang dibaca pengguna:

- Nama SF Symbol (`"person.fill"`)
- ID action presentation (`"confirm-transfer"`)
- Label `LifecycleProbe` dan pesan log
- Nama route dan analytics
- Path endpoint dan nama header

---

## 4. Checklist review satu layar

Cukup lima pertanyaan. Kalau semuanya "ya", layar itu boleh masuk.

1. ViewModel dibuat lewat `@StateObject` di `NamaScreen`, bukan di dalam closure
   destination atau dengan `@ObservedObject`?
2. Subview menerima nilai yang ia butuhkan, bukan seluruh ViewModel?
3. Semua teks lewat `NamaStrings`, dan semua angka visual lewat token atau `NamaStyle`?
4. `onAppear` idempotent, dan tidak ada analytics yang ditembakkan dari sana?
5. Task panjang disimpan, memakai `[weak self]`, dan dibatalkan di `deinit`?
