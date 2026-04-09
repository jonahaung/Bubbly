//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import Database
@testable import Services
import XCTest

final class ServicesTests: XCTestCase {
    func testConsumePendingAnyMsgDataClearsStorage() async throws {
        let suiteName = "test.PushNotificationStore.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let storage = GroupStorage(store: defaults)
        let notificationCenter = NotificationCenter()

        let store = PushNotificationStore(
            dependencies: .init(
                storage: storage,
                notificationCenter: notificationCenter,
                authProvider: { nil },
                updatePushToken: { _, _ in }
            )
        )

        let payload = AnyMsgData.typingStatus(
            status: .init(isTyping: true, conID: "con-1", senderID: "user-1")
        )
        storage.save([payload], for: .device(.anyMsgData))

        let result = await store.consumePendingAnyMsgData()

        XCTAssertEqual(result, [payload])
        XCTAssertNil(storage.codable([AnyMsgData].self, for: .device(.anyMsgData)))
    }
}
