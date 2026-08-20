import CoreNavigation
import XCTest

private enum TestRoute: Hashable {
    case detail(id: String)
    case confirmation
}

@MainActor
final class NavigationRouterTests: XCTestCase {
    func testStartsAtRoot() {
        let sut = NavigationRouter<TestRoute>(rootScreen: "test.root")

        XCTAssertTrue(sut.isAtRoot)
        XCTAssertNil(sut.current)
        XCTAssertTrue(sut.path.isEmpty)
    }

    func testPushAppendsRouteAndTracksCurrent() {
        let sut = NavigationRouter<TestRoute>(rootScreen: "test.root")

        sut.push(.detail(id: "42"))
        sut.push(.confirmation)

        XCTAssertEqual(sut.path, [.detail(id: "42"), .confirmation])
        XCTAssertEqual(sut.current, .confirmation)
        XCTAssertFalse(sut.isAtRoot)
    }

    func testPopRemovesOnlyTheTopRoute() {
        let sut = NavigationRouter<TestRoute>(rootScreen: "test.root")
        sut.push(.detail(id: "42"))
        sut.push(.confirmation)

        sut.pop()

        XCTAssertEqual(sut.path, [.detail(id: "42")])
        XCTAssertEqual(sut.current, .detail(id: "42"))
    }

    func testPopAtRootIsIgnored() {
        let sut = NavigationRouter<TestRoute>(rootScreen: "test.root")

        sut.pop()

        XCTAssertTrue(sut.isAtRoot)
    }

    func testPopToRootClearsEveryRoute() {
        let sut = NavigationRouter<TestRoute>(rootScreen: "test.root")
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
        let sut = NavigationRouter<TestRoute>(rootScreen: "test.root")
        sut.push(.detail(id: "1"))
        sut.push(.confirmation)

        sut.path.removeLast()

        XCTAssertEqual(sut.current, .detail(id: "1"))
        XCTAssertFalse(sut.isAtRoot)

        sut.path = []

        XCTAssertTrue(sut.isAtRoot)
    }
}

@MainActor
private final class ScreenTrackerSpy: ScreenTracking {
    private(set) var screens: [String] = []

    nonisolated func screenViewed(_ screen: String) {
        MainActor.assumeIsolated { screens.append(screen) }
    }
}

@MainActor
final class ScreenTrackingTests: XCTestCase {
    override func tearDown() {
        ScreenTracker.use(nil)
        super.tearDown()
    }

    /// Analytics ditembakkan dari perubahan path, bukan dari `onAppear`, supaya satu
    /// perpindahan layar menghasilkan tepat satu catatan.
    func testEachNavigationRecordsExactlyOneScreenView() {
        let spy = ScreenTrackerSpy()
        ScreenTracker.use(spy)

        let sut = NavigationRouter<TestRoute>(rootScreen: "test.root")
        sut.push(.detail(id: "1"))
        sut.push(.confirmation)
        sut.pop()

        XCTAssertEqual(
            spy.screens,
            ["detail(id: \"1\")", "confirmation", "detail(id: \"1\")"]
        )
    }

    /// Kembali ke root tetap tercatat, memakai nama yang diberikan saat router dibuat.
    func testReturningToRootRecordsRootScreen() {
        let spy = ScreenTrackerSpy()
        ScreenTracker.use(spy)

        let sut = NavigationRouter<TestRoute>(rootScreen: "test.root")
        sut.push(.confirmation)
        sut.popToRoot()

        XCTAssertEqual(spy.screens.last, "test.root")
    }
}
