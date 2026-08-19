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
- `AppCoordinator` tidak memiliki satu pun flow. Ia hanya mengubah `rootState`, lalu `AppRootView` membongkar flow lama dan membangun flow baru.
- Satu flow memiliki satu `NavigationRouter<Route>` melalui `@StateObject`.
- Router hanya memiliki `[Route]`, yaitu nilai. Router tidak pernah memiliki View, ViewModel, atau controller.
- `NamaScreen` memiliki ViewModel melalui `@StateObject`. SwiftUI melepasnya ketika route dipop.
- ViewModel tidak pernah memiliki router; output dikirim melalui closure yang menangkap router dengan `[weak router]`.
- Async task milik ViewModel tidak menangkap ViewModel secara kuat selama menunggu service, dan dibatalkan pada `deinit`.

Karena kepemilikan hanya mengalir satu arah, tidak ada child coordinator yang perlu dilepas secara manual dan tidak ada titik yang bisa membentuk retain cycle.

## Root state versus screen presentation

Root blocker memiliki prioritas berikut:

1. Compromised/rooted device
2. Active call
3. No internet

Root blocker berada di atas flow pada `ZStack` root dan tidak menyentuh `path` milik router, sehingga back stack tetap utuh saat kondisi pulih. Bottom sheet, error blocker, dan snackbar milik halaman berada di `ScreenPresentationStore` masing-masing. Dengan begitu, error sebuah inquiry tidak berubah menjadi global app state.

## MVVM + UseCase rule

- View: render state dan teruskan user intent.
- ViewModel: orchestration state halaman, tanpa UIKit dan tanpa keputusan routing.
- UseCase: validasi dan business rule.
- Repository: abstraksi sumber data.
- Remote Repository: mapping DTO ke domain model.
- Screen: ownership boundary satu layar; merakit UseCase dan memiliki ViewModel lewat `@StateObject`.
- Flow view + Router: mendeklarasikan route, memetakan route ke Screen, dan melakukan push/pop.

DTO tidak boleh bocor ke ViewModel. Alamofire hanya boleh muncul di `CoreNetwork`; feature menggunakan `APIClient` dan Codable.

## Network pipeline

```text
Remote Repository
  -> Endpoint<Response: Decodable>
  -> APIClient
  -> Bearer AuthenticationInterceptor (bila required)
  -> metadata + signature RequestAdapter
  -> per-request mTLS URLCredential untuk allowlisted host
  -> validate + decode
```

Urutan auth sebelum signature disengaja. Retry setelah token refresh menjalankan ulang adaptation sehingga signature tidak pernah memakai access token/timestamp lama. mTLS client identity dan server-trust/pinning adalah concern berbeda; jangan mengganti platform trust dengan evaluator accept-all.
