import CoreNavigation
import XCTest

private enum TestRoute: Hashable {
    case detail(id: String)
    case confirmation
}

@MainActor
final class NavigationRouterTests: XCTestCase {
    func testStartsAtRoot() {
        let sut = NavigationRouter<TestRoute>()

        XCTAssertTrue(sut.isAtRoot)
        XCTAssertNil(sut.current)
        XCTAssertTrue(sut.path.isEmpty)
    }

    func testPushAppendsRouteAndTracksCurrent() {
        let sut = NavigationRouter<TestRoute>()

        sut.push(.detail(id: "42"))
        sut.push(.confirmation)

        XCTAssertEqual(sut.path, [.detail(id: "42"), .confirmation])
        XCTAssertEqual(sut.current, .confirmation)
        XCTAssertFalse(sut.isAtRoot)
    }

    func testPopRemovesOnlyTheTopRoute() {
        let sut = NavigationRouter<TestRoute>()
        sut.push(.detail(id: "42"))
        sut.push(.confirmation)

        sut.pop()

        XCTAssertEqual(sut.path, [.detail(id: "42")])
        XCTAssertEqual(sut.current, .detail(id: "42"))
    }

    func testPopAtRootIsIgnored() {
        let sut = NavigationRouter<TestRoute>()

        sut.pop()

        XCTAssertTrue(sut.isAtRoot)
    }

    func testPopToRootClearsEveryRoute() {
        let sut = NavigationRouter<TestRoute>()
        sut.push(.detail(id: "1"))
        sut.push(.detail(id: "2"))
        sut.push(.confirmation)

        sut.popToRoot()

        XCTAssertTrue(sut.isAtRoot)
        XCTAssertNil(sut.current)
    }

    /// SwiftUI writes straight into the bound path on a Back tap or interactive-pop
    /// swipe, so the router has to stay correct when it is not the one calling `pop()`.
    func testSystemDrivenPopIsReflected() {
        let sut = NavigationRouter<TestRoute>()
        sut.push(.detail(id: "1"))
        sut.push(.confirmation)

        sut.path.removeLast()

        XCTAssertEqual(sut.current, .detail(id: "1"))
        XCTAssertFalse(sut.isAtRoot)

        sut.path = []

        XCTAssertTrue(sut.isAtRoot)
    }
}
