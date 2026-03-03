//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Foundation

public extension AnyMsgData {
    @MainActor
    var deeplinkURL: URL? {
        DeepLinkCoordinator.shared.url(for: .conversation(id: conID))
    }
}
