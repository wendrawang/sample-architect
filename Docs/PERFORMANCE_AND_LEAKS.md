# Performance and Leak Guardrails

Template ini menghilangkan penyebab umum navigation lag: tidak ada hidden `NavigationLink`, destination tidak diprerender, dan setiap push membuat satu `UIHostingController` secara lazy.

## Debug controls

- Tambahkan launch argument `-showFPS` untuk badge FPS dan hitch counter.
- Tambahkan `-assertLeaks` agar object yang belum terlepas setelah 5 detik memicu assertion di DEBUG.
- Logger kategori `lifecycle` mencetak `INIT`/`DEINIT` setiap ViewModel, coordinator, dan hosting controller.
- `PerformanceTracer` menghasilkan signpost yang dapat dibaca lewat Instruments Points of Interest.

## Verifikasi sebelum release

1. Jalankan di device fisik, bukan hanya Simulator.
2. Rekam Time Profiler dan Core Animation saat cold launch, switch tab, Dashboard → Transfer, lalu back.
3. Target frame budget 16,67 ms untuk 60 Hz. Periksa hitch, bukan hanya angka FPS rata-rata.
4. Buka Memory Graph setelah melakukan flow yang sama 10 kali. Instance ViewModel dan child coordinator harus kembali ke baseline.
5. Jalankan Instruments Leaks dan Allocations dengan `Malloc Stack Logging` hanya saat diagnosis karena overhead-nya tinggi.
6. Uji response besar. Mapping/formatting berat harus dipindahkan dari main actor sebelum state final diterapkan.

Tidak ada arsitektur yang dapat menjamin 60 FPS untuk semua feature. Template ini menyediakan ownership yang deterministik dan alat ukur; hasil akhir tetap bergantung pada kompleksitas View, ukuran data, image decoding, SDK pihak ketiga, dan pekerjaan di main thread.

