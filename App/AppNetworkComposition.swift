import CoreNetwork
import Foundation

enum AppSecretConfigurationError: Error, LocalizedError, Sendable {
    case notConfigured(String)

    var errorDescription: String? {
        switch self {
        case let .notConfigured(name):
            return "Secret \(name) belum dikonfigurasi."
        }
    }
}

/// Production must replace this with the existing secure configuration/Keychain
/// adapter. No certificate password, API secret, or OAuth secret is committed.
protocol AppSecretProviding: OAuthClientSecretProviding {
    func mtlsPassword() throws -> String
    func apiKey() -> String?
    func sign(_ input: RequestSigningInput) throws -> String?
}

struct PlaceholderAppSecrets: AppSecretProviding {
    func clientID() throws -> String {
        throw AppSecretConfigurationError.notConfigured("OAuth client ID")
    }

    func clientSecret() throws -> String {
        throw AppSecretConfigurationError.notConfigured("OAuth client secret")
    }

    func mtlsPassword() throws -> String {
        throw AppSecretConfigurationError.notConfigured("mTLS password")
    }

    func apiKey() -> String? {
        nil
    }

    func sign(_ input: RequestSigningInput) throws -> String? {
        nil
    }
}

enum AppNetworkComposition {
    static func makeAPIClient(
        configuration: AppConfiguration,
        sessionStore: AppSessionStore,
        secrets: any AppSecretProviding = PlaceholderAppSecrets(),
        tracer: any NetworkTracing = NoOpNetworkTracer(),
        bundle: Bundle = .main
    ) -> AlamofireAPIClient {
        let mtls = makeMTLSConfiguration(
            configuration: configuration,
            secrets: secrets,
            bundle: bundle
        )
        let tokenURL = configuration.apiBaseURL.appendingPathComponent(
            configuration.oauthTokenPath.trimmingCharacters(
                in: CharacterSet(charactersIn: "/")
            )
        )
        let tokenRefresher = ClientCredentialsTokenRefresher(
            configuration: ClientCredentialsRefreshConfiguration(tokenURL: tokenURL),
            secrets: secrets,
            mtls: mtls,
            onCredentialRefreshed: { [weak sessionStore] credential in
                sessionStore?.updateCredential(credential)
            }
        )
        let appVersion = bundle.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "0"
        let channel = configuration.apiChannel
        let metadataProvider = ClosureRequestMetadataProvider { [weak sessionStore] in
            RequestMetadata(
                appVersion: appVersion,
                language: Locale.preferredLanguages.first ?? "id",
                sessionID: sessionStore?.currentSessionID(),
                channel: channel,
                apiKey: secrets.apiKey()
            )
        }
        let signer = ClosureRequestSigner { input in
            try secrets.sign(input)
        }

        return AlamofireAPIClient(
            baseURL: configuration.apiBaseURL,
            metadataProvider: metadataProvider,
            signer: signer,
            mtls: mtls,
            tokenRefresher: tokenRefresher,
            authenticationFailureIdentifier: StatusCodeAuthenticationFailureIdentifier(
                markerHeader: configuration.authFailureHeader,
                markerValue: configuration.authFailureValue
            ),
            tracer: tracer
        )
    }

    private static func makeMTLSConfiguration(
        configuration: AppConfiguration,
        secrets: any AppSecretProviding,
        bundle: Bundle
    ) -> MTLSConfiguration {
        guard configuration.mtlsEnabled else {
            return .disabled
        }

        let allowedHosts = configuration.apiBaseURL.host.map { [$0] } ?? []
        guard !configuration.mtlsCertificateName.isEmpty else {
            // Enabled mTLS must fail closed rather than silently sending a
            // request without client authentication.
            return MTLSConfiguration(
                mode: .required,
                allowedHosts: Set(allowedHosts),
                credentialProvider: DisabledClientCredentialProvider()
            )
        }

        let provider = PKCS12ClientCredentialProvider(
            bundle: bundle,
            resourceName: configuration.mtlsCertificateName,
            passwordLoader: {
                try secrets.mtlsPassword()
            }
        )
        return MTLSConfiguration(
            mode: .required,
            allowedHosts: Set(allowedHosts),
            credentialProvider: provider
        )
    }
}
