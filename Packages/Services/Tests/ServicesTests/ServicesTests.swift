// © 2026 Aung Ko Min

import Core
import Database
import Foundation
@testable import Services
import Testing

final class ServicesTests {
    @Test func consumePendingAnyMsgDataClearsStorage() async throws {
        let suiteName = "test.PushNotificationStore.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let storage = GroupStorage(store: defaults)
        let notificationCenter = NotificationCenter()

        let store = PushNotificationStore(
            dependencies: .init(
                storage: storage,
                notificationCenter: notificationCenter,
                authProvider: { nil },
                updatePushToken: { _, _ in },
            ),
        )

        let payload = AnyMsgData.typingStatus(
            status: .init(isTyping: true, conID: "con-1", senderID: "user-1"),
        )
        storage.save([payload], for: .device(.anyMsgData))

        let result = await store.consumePendingAnyMsgData()

        #expect(result == [payload])
        #expect(storage.codable([AnyMsgData].self, for: .device(.anyMsgData)) == nil)
    }
}
