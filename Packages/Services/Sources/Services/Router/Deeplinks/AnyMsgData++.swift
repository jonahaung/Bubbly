import Database
import Foundation

public extension AnyMsgData {
	@MainActor
	var deeplinkURL: URL? {
		DeepLinkCoordinator.shared.url(for: .conversation(id: conID))
	}
}
