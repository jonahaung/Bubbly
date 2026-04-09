//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Database
import Foundation

public extension AnyMsgData {
    @MainActor
	func deeplinkURL(coordinator: DeepLinkCoordinator) -> URL? {
		coordinator.url(for: .conversation(id: conID))
    }
}
