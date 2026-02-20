import Foundation
import SwiftUI
import XUI

enum ScrollEffect {
	case scroll(item: ScrollPositionItem)
	case insertItems(edge: VerticalEdge)
	case removeItems(edge: VerticalEdge)
	case finalizeScrollViewUpdates
	case removePendingUpdates
	case noAction
}
