import Foundation
import Security

public protocol ClientCredentialProviding: Sendable {
    func credential(for host: String) throws -> URLCredential?
}

public struct DisabledClientCredentialProvider: ClientCredentialProviding {
    public init() {}

    public func credential(for host: String) throws -> URLCredential? {
        _ = host
        return nil
    }
}

public enum MTLSMode: Sendable {
    case disabled
    case optional
    case required
}

public struct MTLSConfiguration: Sendable {
    public let mode: MTLSMode
    public let allowedHosts: Set<String>
    public let credentialProvider: any ClientCredentialProviding

    public init(
        mode: MTLSMode,
        allowedHosts: Set<String>,
        credentialProvider: any ClientCredentialProviding
    ) {
        self.mode = mode
        self.allowedHosts = Set(allowedHosts.map { $0.lowercased() })
        self.credentialProvider = credentialProvider
    }

    public static let disabled = MTLSConfiguration(
        mode: .disabled,
        allowedHosts: [],
        credentialProvider: DisabledClientCredentialProvider()
    )

    func credential(for url: URL) throws -> URLCredential? {
        guard mode != .disabled else { return nil }
        guard let host = url.host?.lowercased(), allowedHosts.contains(host) else {
            if mode == .required {
                throw APIError.clientCertificateHostNotAllowed
            }
            return nil
        }
        guard url.scheme?.lowercased() == "https" else {
            if mode == .required {
                throw APIError.insecureMTLSTransport
            }
            return nil
        }

        do {
            let credential = try credentialProvider.credential(for: host)
            if mode == .required, credential == nil {
                throw APIError.clientCertificateUnavailable
            }
            return credential
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.clientCertificateInvalid(error.localizedDescription)
        }
    }
}

public enum PKCS12CredentialError: Error, LocalizedError, Sendable {
    case fileNotFound
    case importFailed(OSStatus)
    case identityMissing

    public var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File PKCS#12 tidak ditemukan."
        case let .importFailed(status):
            return "Import PKCS#12 gagal (OSStatus: \(status))."
        case .identityMissing:
            return "Identity tidak ditemukan di dalam PKCS#12."
        }
    }
}

/// Loads a password-protected PKCS#12 identity once and keeps only the resulting
/// URLCredential in memory. Supply the password from Keychain/secure config.
public final class PKCS12ClientCredentialProvider: ClientCredentialProviding, @unchecked Sendable {
    public typealias DataLoader = @Sendable () throws -> Data
    public typealias PasswordLoader = @Sendable () throws -> String

    private let dataLoader: DataLoader
    private let passwordLoader: PasswordLoader
    private let lock = NSLock()
    private var cachedCredential: URLCredential?

    public init(
        dataLoader: @escaping DataLoader,
        passwordLoader: @escaping PasswordLoader
    ) {
        self.dataLoader = dataLoader
        self.passwordLoader = passwordLoader
    }

    public convenience init(
        bundle: Bundle = .main,
        resourceName: String,
        fileExtension: String = "p12",
        passwordLoader: @escaping PasswordLoader
    ) {
        let resourceURL = bundle.url(
            forResource: resourceName,
            withExtension: fileExtension
        )
        self.init(
            dataLoader: {
                guard let resourceURL else {
                    throw PKCS12CredentialError.fileNotFound
                }
                return try Data(contentsOf: resourceURL, options: [.mappedIfSafe])
            },
            passwordLoader: passwordLoader
        )
    }

    public func credential(for host: String) throws -> URLCredential? {
        _ = host
        lock.lock()
        defer { lock.unlock() }

        if let cachedCredential {
            return cachedCredential
        }

        let data = try dataLoader()
        let password = try passwordLoader()
        let options = [kSecImportExportPassphrase as String: password]
        var importedItems: CFArray?
        let status = SecPKCS12Import(
            data as CFData,
            options as CFDictionary,
            &importedItems
        )

        guard status == errSecSuccess else {
            throw PKCS12CredentialError.importFailed(status)
        }
        guard let items = importedItems as? [[String: Any]],
              let firstItem = items.first,
              let identityValue = firstItem[kSecImportItemIdentity as String] else {
            throw PKCS12CredentialError.identityMissing
        }

        // `SecIdentity` is a CoreFoundation type, so a conditional cast from `Any` always
        // succeeds and would happily hand back the wrong object. Verify the real CF type
        // id first; only then is the forced cast provably safe.
        let identityRef = identityValue as CFTypeRef
        guard CFGetTypeID(identityRef) == SecIdentityGetTypeID() else {
            throw PKCS12CredentialError.identityMissing
        }
        let identity = identityRef as! SecIdentity

        let chain = firstItem[kSecImportItemCertChain as String] as? [Any]
        let credential = URLCredential(
            identity: identity,
            certificates: chain,
            persistence: .forSession
        )
        cachedCredential = credential
        return credential
    }
}
