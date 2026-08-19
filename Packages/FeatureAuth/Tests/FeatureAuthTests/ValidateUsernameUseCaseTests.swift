import FeatureAuth
import XCTest

final class ValidateUsernameUseCaseTests: XCTestCase {
    func testExecuteTrimsValidUsername() throws {
        let sut = ValidateUsernameUseCase()
        XCTAssertEqual(try sut.execute("  wendra  "), "wendra")
    }

    func testExecuteRejectsShortUsername() {
        let sut = ValidateUsernameUseCase()
        XCTAssertThrowsError(try sut.execute("ab")) { error in
            XCTAssertEqual(error as? AuthValidationError, .usernameTooShort)
        }
    }
}

