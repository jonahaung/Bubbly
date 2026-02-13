import Foundation

enum ScrollEffect {
	case scrollToOffset(CGFloat, animated: Bool, duration: Double?)
	case scrollToBottom(animated: Bool, duration: Double?)
	case loadOlder
	case loadNewer
	case finalizeUpdate
	case none
}
