# Menambah Feature Baru

Gunakan `Packages/FeatureTemplate` sebagai kontrak bentuk, lalu lakukan urutan berikut.

1. Salin package dan ubah `FeatureTemplate`/`SampleFeature` menjadi nama flow baru.
2. Definisikan domain model, `RepositoryProtocol`, dan `NamaDependencies` — protokol berisi factory yang menyatakan apa yang feature ini butuhkan dari luar.
3. Buat UseCase untuk satu business intent. Jangan menaruh validasi bisnis di View.
4. Buat ViewModel `@MainActor`, `final`, memiliki `LifecycleProbe`, dan cancel task pada `deinit`.
5. Buat file `NamaHalamanStyle.swift`. Nilai visual halaman boleh khas, tetapi warna dasar, spacing, radius, typography, dan komponen harus berasal dari `DesignSystem`.
6. Bungkus root View dengan `ScreenScaffold`. Ini otomatis memberi capability bottom sheet, blocker, dan snackbar.
7. Buat `NamaScreen` dengan `@StateObject` sebagai ownership boundary ViewModel. Jika flow melakukan push/pop, tambahkan case pada route enum flow dan pasang di `navigationDestination(for:)` milik root stack. Callback dari ViewModel harus menangkap router dengan `[weak router]`.
8. Penuhi `NamaDependencies` dengan satu `extension AppDependencies` di target App, lalu tambahkan package ke composition package yang memang membutuhkan flow tersebut. Jangan membuat import feature-to-feature hanya demi mengambil helper kecil; helper bersama masuk ke Core atau DesignSystem.
9. Tambahkan unit test untuk UseCase dan transformasi state ViewModel.
10. Jalankan `make check`, unit test, Memory Graph, Leaks, dan Core Animation sebelum merge.

## Definition of done per screen

- Tidak memakai `NavigationView`, `NavigationLink(destination:)`, atau `AnyView`.
- `navigationDestination(for:)` hanya dipasang sekali pada root stack, tidak di dalam baris list.
- ViewModel dibuat lewat `@StateObject` di `NamaScreen`, bukan di dalam closure destination.
- Tidak melakukan network request langsung dari View/ViewModel.
- `onAppear` idempotent dan tidak menembakkan inquiry berulang akibat re-render.
- Long-running task bisa dibatalkan.
- Empty, loading, success, dan error state terdefinisi.
- Dynamic Type dan VoiceOver label diperiksa.
- Back button dan interactive-pop menghasilkan `POP` pada log navigation yang diikuti `DEINIT` ViewModel layar tersebut.

