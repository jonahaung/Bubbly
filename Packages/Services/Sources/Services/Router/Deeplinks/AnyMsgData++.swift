// © 2026 Aung Ko Min

import Database
import Foundation

public extension AnyMsgData {
    @MainActor
    func deeplinkURL(coordinator: DeepLinkCoordinator) -> URL? {
        DeeplinkCodec.standard.url(for: .conversation(conID: conID))
    }
}
