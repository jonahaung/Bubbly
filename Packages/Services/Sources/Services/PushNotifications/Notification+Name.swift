//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Combine
import Database
import Foundation

public extension Notification.Name {
    static func msgNoti(for conID: String) -> Notification.Name {
        Notification.Name("conversation=\(conID)")
    }

    static let receiveDeviceToken = Notification.Name("receiveDeviceToken")
    static let inboxChanges = Notification.Name("inboxChanges")
}

public extension NotificationCenter.Publisher.Output {
    var anyMsgData: AnyMsgData? {
        object as? AnyMsgData
    }
}
