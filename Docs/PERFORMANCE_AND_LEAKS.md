# Performance and Leak Guardrails

Template ini menghilangkan penyebab umum navigation lag: tidak ada `NavigationLink(destination:)` yang membangun destination lebih awal, `navigationDestination(for:)` didaftarkan sekali per stack dan bukan per baris list, route memakai enum bertipe sehingga tidak ada boxing `AnyHashable`, dan ViewModel dibangun sekali lewat `@StateObject` sehingga re-render tidak merakit ulang UseCase.

## Debug controls

- Tambahkan launch argument `-showFPS` untuk badge FPS dan hitch counter.
- Tambahkan `-assertLeaks` agar object yang dilaporkan ke `LeakWatchdog` dan belum terlepas setelah 5 detik memicu assertion di DEBUG. `LeakWatchdog` dipanggil manual; pemeriksaan per layar yang otomatis memakai pasangan log `POP`/`DEINIT` di bawah.
- Logger kategori `lifecycle` mencetak `INIT`/`DEINIT` setiap ViewModel dan router.
- Logger kategori `navigation` mencetak `PUSH`/`POP` setiap perubahan path, termasuk pop dari tombol Back dan swipe. Satu `POP` harus diikuti `DEINIT` milik ViewModel layar tersebut; `POP` tanpa `DEINIT` berarti layar masih tertahan.
- `PerformanceTracer` menghasilkan signpost yang dapat dibaca lewat Instruments Points of Interest.
- `AlamofireAPIClient` hanya memakai nama signpost statis; request path dicatat terpisah oleh privacy-aware logger agar signpost murah dan valid.

## Verifikasi sebelum release

1. Jalankan di device fisik, bukan hanya Simulator.
2. Rekam Time Profiler dan Core Animation saat cold launch, switch tab, Dashboard → Transfer, lalu back.
3. Target frame budget 16,67 ms untuk 60 Hz. Periksa hitch, bukan hanya angka FPS rata-rata.
4. Buka Memory Graph setelah melakukan flow yang sama 10 kali. Instance ViewModel dan router harus kembali ke baseline.
5. Jalankan Instruments Leaks dan Allocations dengan `Malloc Stack Logging` hanya saat diagnosis karena overhead-nya tinggi.
6. Uji response besar. Mapping/formatting berat harus dipindahkan dari main actor sebelum state final diterapkan.

Tidak ada arsitektur yang dapat menjamin 60 FPS untuk semua feature. Template ini menyediakan ownership yang deterministik dan alat ukur; hasil akhir tetap bergantung pada kompleksitas View, ukuran data, image decoding, SDK pihak ketiga, dan pekerjaan di main thread.
