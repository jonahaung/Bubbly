import Foundation
import SwiftUI
import XUI

enum ScrollEffect: Hashable {
	case scroll(item: ScrollPositionItem)
	case begingUpdate(_ intent: ScrollUpdateIntent)
	case endUpdate(_ intent: ScrollUpdateIntent, scrollItem: ScrollPositionItem?)
	case finalizeScrollViewUpdates
	case removePendingUpdates
	case noAction
}
enum ScrollUpdateIntent: Hashable {
	case insertItems(edge: VerticalEdge)
	case removeItems(edge: VerticalEdge)
	case reseting
}
