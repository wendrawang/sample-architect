# Rekomendasi Pondasi untuk Aplikasi Ratusan Layar

Dokumen ini opini, bukan deskripsi kode. Isinya apa yang saya sarankan untuk aplikasi
mobile banking dengan ratusan layar, tim beranggota banyak, banyak SDK pihak ketiga, dan
umur pakai bertahun-tahun — beserta alasannya, supaya Anda bisa menolak bagian yang tidak
Anda setujui.

---

## 1. Yang sebenarnya menentukan

Untuk aplikasi sebesar itu, **pilihan pola arsitektur hampir tidak menentukan apa-apa.**
MVVM, VIPER, TCA — semuanya bisa berakhir kacau di tahun ketiga.

Yang menentukan hanya tiga:

1. **Batas yang tidak bisa dilanggar tanpa sengaja.** Bukan konvensi, bukan code review.
2. **Kesalahan yang gagal saat compile, bukan saat runtime.**
3. **Hal yang diukur otomatis.** Leak, cold launch, frame time.

Setiap keluhan yang biasanya muncul di aplikasi besar adalah gejala dari ketiadaan tiga
hal ini, bukan dari salahnya sebuah pola.

---

## 2. Navigasi: kunci datanya, bukan mesinnya

Ini keputusan tersulit, dan saya sarankan tidak memutuskannya dengan cara memilih satu
pemenang.

**Pertimbangan untuk `UINavigationController`:** sebagian besar SDK bank menyerahkan
`UIViewController` — kamera, biometrik, e-KYC, tanda tangan digital, payment gateway.
Dengan UIKit Anda tinggal `push`. Dengan `NavigationStack` Anda harus membungkusnya, dan
di situlah anomali layar blank paling sering lahir. Ditambah, `NavigationStack` punya bug
nyata di iOS 16.0–16.3.

**Pertimbangan untuk `NavigationStack`:** back stack menjadi data. Itu yang membuat route
bisa dites, deep link bisa dipetakan, dan analytics punya satu titik yang benar.

**Rekomendasi:** yang dikunci bukan mesinnya, melainkan **route sebagai data yang Anda
miliki sendiri**.

```text
Router (tipe milik Anda) → [Route]   ← permanen: ini yang dites, ini sumber analytics
        ↓
   dirender NavigationStack          ← boleh diganti
```

Selama `Router` adalah tipe Anda dan `NavigationStack` tidak bocor ke seluruh feature,
mengganti mesin render nanti adalah pekerjaan satu-dua file. Itu keputusan yang tahan
lama; pilihan mesin hari ini tidak.

Konsekuensi praktis: **sediakan pintu darurat UIKit sejak hari pertama.** Satu wrapper
teruji (`UIKitScreen` di `CoreNavigation`) untuk layar SDK, dibuat sebelum SDK pertama
masuk — bukan saat sudah panik.

---

## 3. Pola: pertahankan MVVM

Saya **tidak** merekomendasikan TCA. Bukan karena jelek, tapi karena tim yang setengah
paham TCA menghasilkan kode yang jauh lebih sulit dirawat daripada MVVM yang dipahami
penuh. Kalau tim Anda sudah memakai MVVM, itu aset, bukan beban.

MVVM + UseCase + Repository sudah cukup. Yang perlu ditambahkan bukan lapisan, melainkan
**penegakan**: batas package (compiler) dan script arsitektur (CI). Itu yang membuat MVVM
Anda di tahun ketiga masih berbentuk MVVM.

---

## 4. Pembagian modul

```text
Core/           kit, network, navigation, presentation, guards
DesignSystem/
Feature<Flow>/  satu package per FLOW
App/            composition root — satu-satunya yang mengenal semuanya
```

Tiga aturan:

- **Satu package per flow, bukan per layar.** Package berisi 100 baris adalah ongkos
  tanpa manfaat.
- **Feature tidak pernah mengimpor feature.** Kalau butuh, naikkan intent ke atas.
- **Jangan pecah interface/implementation sampai build time benar-benar sakit.** Itu
  solusi untuk masalah yang belum Anda punya.

Untuk aplikasi bertab, **satu `NavigationStack` per tab**, dan setiap tab memiliki route
enum-nya sendiri di dalam package-nya. Shell tab bar tidak boleh mengenal layar yang bisa
di-push dari dalam tab.

---

## 5. Keluhan umum dan apa yang benar-benar menyelesaikannya

| Keluhan | Akar | Yang menyelesaikan |
|---|---|---|
| Layar tiba-tiba blank | type erasure, identity berubah, ViewModel lahir ulang | `@StateObject` disiplin + larangan `AnyView` di CI |
| Analytics kunjungan dobel | ditembak dari `onAppear` | tembak dari **perubahan path**, satu titik |
| Object tidak pernah `deinit` | kepemilikan dua arah | router menyimpan nilai saja + test hitung instance di CI |
| Lupa mendaftarkan route | registry runtime | `switch` exhaustive → **error compile** |
| Cold launch lambat | inisialisasi SDK | **bukan masalah arsitektur** |

Baris keempat adalah kemenangan termurah: begitu route menjadi `enum` dan `switch`-nya
exhaustive, "lupa daftar" berubah dari tombol yang diam menjadi build yang gagal.

Baris kelima perlu ditegaskan: **tidak ada arsitektur yang memperbaikinya.** Kalau
sepuluh SDK melakukan init sinkron di `didFinishLaunching`, semua pola akan lambat.
Yang harus dilakukan: pasang signpost per SDK, tetapkan anggaran cold launch, dan
jadikan anggaran itu gate di CI. Tanpa angka, ini akan selamanya jadi tebak-tebakan.

---

## 6. Alat ukur yang saya sarankan ada sejak hari pertama

Ini bagian yang paling sering ditunda dan paling mahal kalau ditunda.

| Alat | Menjawab | Status di repo ini |
|---|---|---|
| Screen view dari perubahan path | "kenapa angka analytics tidak masuk akal" | ✅ `ScreenTracker` |
| Test leak otomatis | "ada berapa layar yang tidak pernah dilepas" | ✅ `CoreTestSupport` |
| Wrapper UIKit teruji | "kenapa layar SDK berkedip" | ✅ `UIKitScreen` |
| Log `PUSH`/`POP` + `INIT`/`DEINIT` | "layar mana yang tertahan" | ✅ |
| Anggaran cold launch di CI | "sejak kapan launch jadi lambat" | ❌ butuh setup CI Anda |
| Frame time pada flow utama | "apakah scroll masih 60 fps" | ❌ manual lewat Instruments |

Perhatikan bahwa empat dari enam adalah **alat ukur, bukan struktur**. Itu bukan
kebetulan. Struktur yang baik mudah ditiru; yang sulit adalah mengetahui kapan struktur
itu mulai bocor.

---

## 7. Risiko terbesar bukan arsitektur

Kalau proyek sebesar ini gagal dalam dua tahun, urutan penyebab yang paling mungkin:

1. **Cold launch karena SDK.** Bertambah pelan-pelan, tidak ada yang mengukur, lalu
   suatu hari sudah lima detik.
2. **Inkonsistensi antar anggota tim.** Setiap orang menyelesaikan masalah yang sama
   dengan cara berbeda; setelah dua tahun tidak ada satu pun pola yang berlaku menyeluruh.
3. **Bug SwiftUI spesifik versi iOS.** Terutama pada OS terendah yang masih didukung.

Arsitektur ada di urutan keempat. Kalau energi Anda terbatas, taruh di tiga hal di atas.
