import Foundation
import Security

public enum FirebaseKeychainSanitizer {
    public static func sanitize() {
        let account = "firebase_auth_1_app_credentials"
        sanitize(account: account)
    }

    private static func sanitize(account: String) {
        let items = fetchItems(account: account)
        let candidates = items.filter { item in
            guard let service = item.service else { return false }
            return service.hasPrefix("firebase_auth_1:")
        }
        guard candidates.count > 1 else { return }
        let sorted = candidates.sorted { $0.modificationDate > $1.modificationDate }
        for item in sorted.dropFirst() {
            deleteItem(account: account, service: item.service, accessGroup: item.accessGroup)
        }
    }

    private static func fetchItems(account: String) -> [KeychainItem] {
		let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return [] }
        let array = result as? [[String: Any]] ?? []
        return array.map(KeychainItem.init)
    }

    private static func deleteItem(account: String, service: String?, accessGroup: String?) {
        guard let service else { return }
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        SecItemDelete(query as CFDictionary)
    }

}

private struct KeychainItem {
    let service: String?
    let accessGroup: String?
    let modificationDate: Date

    init(_ dict: [String: Any]) {
        service = dict[kSecAttrService as String] as? String
        accessGroup = dict[kSecAttrAccessGroup as String] as? String
        modificationDate = (dict[kSecAttrModificationDate as String] as? Date) ?? .distantPast
    }
}
