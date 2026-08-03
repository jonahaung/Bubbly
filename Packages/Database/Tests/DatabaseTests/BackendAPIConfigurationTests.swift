@testable import Database
import Foundation
import Testing

@Suite("Backend API Configuration")
struct BackendAPIConfigurationTests {
    @Test("Prefers the persisted app override")
    func prefersPersistedOverride() throws {
        let defaults = try #require(UserDefaults(suiteName: #function))
        defaults.set("http://192.168.80.126:8080", forKey: BackendAPIConfiguration.applicationBaseURLOverrideKey)

        let configuration = try BackendAPIConfiguration.application(
            userDefaults: defaults,
            environment: ["BUBBLY_API_BASE_URL": "http://127.0.0.1:8080"],
            infoDictionaryValue: "http://localhost:8080"
        )

        #expect(configuration.baseURL.absoluteString == "http://192.168.80.126:8080")
        defaults.removePersistentDomain(forName: #function)
    }

    @Test("Falls back to the environment when no override exists")
    func fallsBackToEnvironment() throws {
        let defaults = try #require(UserDefaults(suiteName: #function))

        let configuration = try BackendAPIConfiguration.application(
            userDefaults: defaults,
            environment: ["BUBBLY_API_BASE_URL": "http://192.168.80.126:8080"],
            infoDictionaryValue: "http://localhost:8080"
        )

        #expect(configuration.baseURL.absoluteString == "http://192.168.80.126:8080")
        defaults.removePersistentDomain(forName: #function)
    }

    @Test("Rejects an override containing credentials")
    func rejectsCredentials() throws {
        let defaults = try #require(UserDefaults(suiteName: #function))
        defaults.set("http://user:password@example.com", forKey: BackendAPIConfiguration.applicationBaseURLOverrideKey)

        #expect(throws: BackendAPIError.invalidConfiguration) {
            try BackendAPIConfiguration.application(
                userDefaults: defaults,
                environment: [:],
                infoDictionaryValue: nil
            )
        }
        defaults.removePersistentDomain(forName: #function)
    }
}
