import CoreNavigation
import XCTest

/// Pemetaan URL ke layar adalah logika biasa, jadi diuji seperti logika biasa —
/// tanpa simulator, tanpa merender apa pun.
final class DeepLinkTests: XCTestCase {
    func testCustomSchemeTreatsHostAsFirstSegment() {
        let sut = DeepLink(url: URL(string: "byon://dashboard/transfer")!)

        XCTAssertEqual(sut?.segments, ["dashboard", "transfer"])
        XCTAssertEqual(sut?.root, "dashboard")
    }

    func testUniversalLinkUsesPathOnly() {
        let sut = DeepLink(url: URL(string: "https://byon.example.com/dashboard/transfer")!)

        XCTAssertEqual(sut?.segments, ["dashboard", "transfer"])
    }

    func testQueryItemsAreCaptured() {
        let sut = DeepLink(url: URL(string: "byon://dashboard/transfer?ref=promo&amount=50000")!)

        XCTAssertEqual(sut?.query["ref"], "promo")
        XCTAssertEqual(sut?.query["amount"], "50000")
    }

    func testSegmentsAreCaseInsensitive() {
        let sut = DeepLink(url: URL(string: "byon://Dashboard/Transfer")!)

        XCTAssertEqual(sut?.segments, ["dashboard", "transfer"])
    }

    func testDroppingFirstSegmentKeepsQuery() {
        let sut = DeepLink(url: URL(string: "byon://dashboard/transfer?ref=promo")!)

        let rest = sut?.dropFirstSegment()

        XCTAssertEqual(rest?.segments, ["transfer"])
        XCTAssertEqual(rest?.query["ref"], "promo")
    }

    func testURLWithoutAnySegmentIsRejected() {
        XCTAssertNil(DeepLink(url: URL(string: "byon://")!))
    }
}
