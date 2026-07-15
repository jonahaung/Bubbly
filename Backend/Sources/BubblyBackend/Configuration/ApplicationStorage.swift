import Vapor

extension Application {
    private struct ConfigurationKey: StorageKey {
        typealias Value = AppConfiguration
    }

    private struct TokenVerifierKey: StorageKey {
        typealias Value = FirebaseTokenVerifier
    }

    var bubblyConfiguration: AppConfiguration {
        get {
            guard let value = storage[ConfigurationKey.self] else {
                preconditionFailure("AppConfiguration has not been registered")
            }
            return value
        }
        set {
            storage[ConfigurationKey.self] = newValue
        }
    }

    var firebaseTokenVerifier: FirebaseTokenVerifier {
        get {
            guard let value = storage[TokenVerifierKey.self] else {
                preconditionFailure("FirebaseTokenVerifier has not been registered")
            }
            return value
        }
        set {
            storage[TokenVerifierKey.self] = newValue
        }
    }
}
