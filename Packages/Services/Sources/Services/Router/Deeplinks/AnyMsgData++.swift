// © 2026 Aung Ko Min

import Database
import Foundation

public extension AnyMsgData {
    @MainActor
    func deeplinkURL() -> URL? {
        DeeplinkCodec.standard.url(for: .conversation(conID: conID))
    }
}
