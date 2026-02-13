import Foundation

public enum Deeplink: Hashable, Sendable {
	case home
	case profile(id: String)
	case conversation(id: String)
	case settings
}
