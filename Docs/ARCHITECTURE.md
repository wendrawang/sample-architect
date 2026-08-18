# Architecture

## Dependency direction

```text
App composition root
  -> FeatureSplash / FeatureAuth / FeatureMain
  -> CoreNavigation / CoreGuards / CoreNetwork

FeatureMain
  -> Dashboard / Financial / QRIS / Rewards / More / Transfer

Every feature
  -> DesignSystem
  -> Core protocols and utilities

CoreNetwork
  -> Alamofire only
```

Feature package lain tidak boleh mengimpor feature yang tidak menjadi bagian flow-nya. Pengecualian yang disengaja hanya `FeatureMain`, karena package tersebut adalah composition boundary untuk lima tab dan flow Transfer.

## Ownership and lifetime

- `SceneDelegate` memiliki `AppCoordinator` secara kuat.
- Coordinator parent memiliki coordinator child secara kuat.
- Coordinator child memiliki parent secara `weak`.
- Coordinator hanya memiliki `UINavigationController` secara `weak`.
- `UIHostingController` memiliki SwiftUI View dan ViewModel.
- ViewModel tidak pernah memiliki coordinator atau `UIViewController`; output dikirim melalui closure yang menangkap coordinator dengan `[weak self]`.
- Async task milik ViewModel tidak menangkap ViewModel secara kuat selama menunggu service.
- Ketika screen dipop dengan tombol Back atau swipe gesture, `ScreenHostingController` memanggil `finish()` agar parent melepas coordinator child.

## Root state versus screen presentation

Root blocker memiliki prioritas berikut:

1. Compromised/rooted device
2. Active call
3. No internet

Root blocker berada di atas navigation controller dan tidak merusak back stack. Bottom sheet, error blocker, dan snackbar milik halaman berada di `ScreenPresentationStore` masing-masing. Dengan begitu, error sebuah inquiry tidak berubah menjadi global app state.

## MVVM + UseCase rule

- View: render state dan teruskan user intent.
- ViewModel: orchestration state halaman, tanpa UIKit dan tanpa keputusan routing.
- UseCase: validasi dan business rule.
- Repository: abstraksi sumber data.
- Remote Repository: mapping DTO ke domain model.
- Coordinator: membuat dependency, hosting controller, push/pop, dan menangani output lintas halaman.

DTO tidak boleh bocor ke ViewModel. Alamofire hanya boleh muncul di `CoreNetwork`; feature menggunakan `APIClient` dan Codable.

