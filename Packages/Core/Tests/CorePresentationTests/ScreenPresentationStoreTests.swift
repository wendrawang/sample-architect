import CorePresentation
import XCTest

@MainActor
final class ScreenPresentationStoreTests: XCTestCase {
    func testBottomSheetCanBePresentedAndDismissed() {
        let sut = ScreenPresentationStore()
        let model = BottomSheetModel(
            title: "Test",
            message: "Message",
            actions: [.init(id: "ok", title: "OK")]
        )

        sut.present(bottomSheet: model)
        XCTAssertEqual(sut.bottomSheet, model)

        sut.dismissBottomSheet()
        XCTAssertNil(sut.bottomSheet)
    }

    func testNewSnackbarReplacesPreviousSnackbar() {
        let sut = ScreenPresentationStore()
        let first = SnackbarModel(message: "First", duration: 30)
        let second = SnackbarModel(message: "Second", duration: 30)

        sut.show(snackbar: first)
        sut.show(snackbar: second)

        XCTAssertEqual(sut.snackbar, second)
    }
}

