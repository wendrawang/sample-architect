import Foundation

/// URL masuk yang sudah diurai menjadi nilai.
///
/// Sengaja tidak tahu apa pun soal View, route, atau flow. Karena ia hanya data, pemetaan
/// URL ke layar bisa diuji tanpa simulator dan tanpa merender apa pun.
///
/// ```swift
/// let link = DeepLink(url: URL(string: "byon://dashboard/transfer?ref=promo")!)
/// XCTAssertEqual(link?.segments, ["dashboard", "transfer"])
/// ```
public struct DeepLink: Hashable, Sendable {
    public let segments: [String]
    public let query: [String: String]

    public init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        // Custom scheme menaruh segmen pertama di `host` (byon://dashboard/transfer),
        // universal link menaruh semuanya di `path` (https://byon.app/dashboard/transfer).
        var parts: [String] = []
        if let host = components.host, !host.isEmpty, url.scheme?.hasPrefix("http") != true {
            parts.append(host)
        }
        parts.append(contentsOf: components.path.split(separator: "/").map(String.init))

        guard !parts.isEmpty else { return nil }

        segments = parts.map { $0.lowercased() }
        query = Dictionary(
            (components.queryItems ?? []).compactMap { item in
                item.value.map { (item.name, $0) }
            },
            uniquingKeysWith: { first, _ in first }
        )
    }

    /// Segmen pertama, biasanya menentukan tab atau flow tujuan.
    public var root: String? { segments.first }

    /// Sisa segmen setelah yang pertama, untuk dipetakan flow tujuan menjadi path.
    public func dropFirstSegment() -> DeepLink {
        DeepLink(segments: Array(segments.dropFirst()), query: query)
    }

    private init(segments: [String], query: [String: String]) {
        self.segments = segments
        self.query = query
    }
}
