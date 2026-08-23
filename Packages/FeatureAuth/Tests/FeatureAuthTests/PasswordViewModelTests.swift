import CoreTestSupport
import XCTest
@testable import FeatureAuth

private struct StubError: Error, LocalizedError, Sendable {
    var errorDescription: String? { "Service sedang tidak tersedia." }
}

private enum StubOutcome: Sendable {
    case success(AuthSession)
    case failure(StubError)
}

private struct StubAuthRepository: AuthRepositoryProtocol {
    let outcome: StubOutcome

    func login(username: String, password: String) async throws -> AuthSession {
        switch outcome {
        case .success(let session): return session
        case .failure(let error): throw error
        }
    }
}

/// Composition root palsu. Bentuknya sama persis dengan `AppDependencies` di target App,
/// hanya isinya stub — itulah gunanya feature mendeklarasikan protokol kebutuhannya sendiri.
private struct StubAuthDependencies: AuthDependencies {
    let outcome: StubOutcome

    func makeAuthRepository() -> any AuthRepositoryProtocol {
        StubAuthRepository(outcome: outcome)
    }
}

/// Membuktikan dependency injection-nya benar-benar terpakai: seluruh rantai dari
/// repository sampai ViewModel dirakit dari stub, tanpa jaringan dan tanpa merender UI.
@MainActor
final class PasswordViewModelTests: XCTestCase {
    private static let session = AuthSession(
        accessToken: "token",
        userDisplayName: "Wendra"
    )

    private func makeSUT(
        outcome: StubOutcome,
        onAuthenticated: @escaping (AuthSession) -> Void = { _ in }
    ) -> PasswordViewModel {
        let dependencies = StubAuthDependencies(outcome: outcome)
        return PasswordViewModel(
            username: "wendra",
            loginUseCase: LoginUseCase(repository: dependencies.makeAuthRepository()),
            onAuthenticated: onAuthenticated
        )
    }

    func testSuccessfulLoginReportsSessionUpward() async {
        var received: AuthSession?
        let sut = makeSUT(outcome: .success(Self.session)) { received = $0 }

        sut.password = "secret123"
        sut.didTapLogin()
        await sut.loginTask?.value

        XCTAssertEqual(received?.accessToken, "token")
        XCTAssertFalse(sut.isLoading)
    }

    func testFailedLoginShowsBlockerAndStopsLoading() async {
        let sut = makeSUT(outcome: .failure(StubError()))

        sut.password = "secret123"
        sut.didTapLogin()
        await sut.loginTask?.value

        XCTAssertNotNil(sut.presentation.blocker)
        XCTAssertFalse(sut.isLoading)
    }

    /// Password terlalu pendek ditolak UseCase sebelum menyentuh repository.
    func testShortPasswordNeverReachesTheRepository() async {
        let sut = makeSUT(outcome: .success(Self.session))

        sut.password = "123"
        sut.didTapLogin()
        await sut.loginTask?.value

        XCTAssertNotNil(sut.presentation.blocker)
    }

    func testViewModelIsReleasedAfterUse() {
        assertDeallocatedAfterUse {
            makeSUT(outcome: .success(Self.session))
        }
    }
}
