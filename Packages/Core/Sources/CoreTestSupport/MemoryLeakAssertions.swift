import XCTest

/// Membuktikan sebuah object benar-benar dilepas setelah pemiliknya hilang.
///
/// Log `INIT`/`DEINIT` berguna saat menjalankan aplikasi, tetapi harus dibaca manusia dan
/// mudah terlewat. Assertion ini menjadikan hal yang sama sebagai test yang gagal di CI.
///
/// ```swift
/// assertDeallocatedAfterUse {
///     TransferViewModel(submitTransfer: StubUseCase())
/// }
/// ```
public func assertDeallocatedAfterUse<Object: AnyObject>(
    _ make: () -> Object,
    use: (Object) -> Void = { _ in },
    file: StaticString = #filePath,
    line: UInt = #line
) {
    weak var weakObject: Object?

    autoreleasepool {
        let object = make()
        weakObject = object
        use(object)
    }

    XCTAssertNil(
        weakObject,
        "\(Object.self) masih hidup setelah pemilik terakhirnya dilepas — periksa closure yang menangkap self secara kuat.",
        file: file,
        line: line
    )
}

/// Versi untuk alur push lalu pop berulang: object dibuat dan dilepas `iterations` kali,
/// lalu dipastikan tidak ada satu pun yang tertinggal.
///
/// Ini padanan otomatis dari prosedur manual "Dashboard -> Transfer -> Back sepuluh kali
/// lalu periksa Memory Graph".
public func assertNoAccumulation<Object: AnyObject>(
    iterations: Int = 10,
    _ make: () -> Object,
    use: (Object) -> Void = { _ in },
    file: StaticString = #filePath,
    line: UInt = #line
) {
    var leaked = 0

    for _ in 0..<iterations {
        weak var weakObject: Object?
        autoreleasepool {
            let object = make()
            weakObject = object
            use(object)
        }
        if weakObject != nil { leaked += 1 }
    }

    XCTAssertEqual(
        leaked,
        0,
        "\(leaked) dari \(iterations) instance \(Object.self) tidak pernah dilepas.",
        file: file,
        line: line
    )
}
