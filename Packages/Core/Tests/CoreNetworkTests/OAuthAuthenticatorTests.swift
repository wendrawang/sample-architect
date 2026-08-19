import Alamofire
import Foundation
@testable import CoreNetwork
import XCTest

final class OAuthAuthenticatorTests: XCTestCase {
    func testApplyAddsBearerToken() throws {
        let authenticator = OAuthAuthenticator(
            tokenRefresher: UnavailableTokenRefresher(),
            failureIdentifier: StatusCodeAuthenticationFailureIdentifier()
        )
        var request = URLRequest(url: try XCTUnwrap(URL(string: "https://example.com")))

        authenticator.apply(OAuthCredential(accessToken: "token"), to: &request)

        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Authorization"),
            "Bearer token"
        )
    }

    func testOnlyConfiguredAuthenticationFailureTriggersRefresh() throws {
        let authenticator = OAuthAuthenticator(
            tokenRefresher: UnavailableTokenRefresher(),
            failureIdentifier: StatusCodeAuthenticationFailureIdentifier(
                markerHeader: "X-Auth-Failure",
                markerValue: "expired"
            )
        )
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let request = URLRequest(url: url)
        let accepted = try XCTUnwrap(
            HTTPURLResponse(
                url: url,
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["X-Auth-Failure": "expired"]
            )
        )
        let rejected = try XCTUnwrap(
            HTTPURLResponse(
                url: url,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )
        )

        XCTAssertTrue(
            authenticator.didRequest(
                request,
                with: accepted,
                failDueToAuthenticationError: APIError.unauthorized
            )
        )
        XCTAssertFalse(
            authenticator.didRequest(
                request,
                with: rejected,
                failDueToAuthenticationError: APIError.unauthorized
            )
        )
    }

    func testRequiredMTLSFailsBeforeSendingWhenCredentialIsMissing() throws {
        let configuration = MTLSConfiguration(
            mode: .required,
            allowedHosts: ["api.example.com"],
            credentialProvider: DisabledClientCredentialProvider()
        )
        let url = try XCTUnwrap(URL(string: "https://api.example.com/v1/bootstrap"))

        XCTAssertThrowsError(try configuration.credential(for: url)) { error in
            XCTAssertEqual(error as? APIError, .clientCertificateUnavailable)
        }
    }

    func testRequiredMTLSRejectsInsecureTransport() throws {
        let configuration = MTLSConfiguration(
            mode: .required,
            allowedHosts: ["api.example.com"],
            credentialProvider: DisabledClientCredentialProvider()
        )
        let url = try XCTUnwrap(URL(string: "http://api.example.com/v1/bootstrap"))

        XCTAssertThrowsError(try configuration.credential(for: url)) { error in
            XCTAssertEqual(error as? APIError, .insecureMTLSTransport)
        }
    }

    func testRequiredMTLSRejectsHostOutsideAllowlist() throws {
        let configuration = MTLSConfiguration(
            mode: .required,
            allowedHosts: ["api.example.com"],
            credentialProvider: DisabledClientCredentialProvider()
        )
        let url = try XCTUnwrap(URL(string: "https://other.example.com/v1/bootstrap"))

        XCTAssertThrowsError(try configuration.credential(for: url)) { error in
            XCTAssertEqual(error as? APIError, .clientCertificateHostNotAllowed)
        }
    }
}
