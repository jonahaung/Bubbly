// © 2026 Aung Ko Min

import Database
import Foundation

public extension AnyMsgData {
    @MainActor
    func deeplinkURL(coordinator: DeepLinkCoordinator) -> URL? {
        coordinator.url(for: .conversation(conID: conID))
    }
}
