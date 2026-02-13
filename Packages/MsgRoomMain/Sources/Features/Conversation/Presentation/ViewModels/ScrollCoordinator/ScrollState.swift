import SwiftUI
import XUI

struct ScrollState: Equatable {
	var updateState: ScrollViewUpdatingState
	var scrollGeometry: VScrollGeometry
	var scrollDirection: VerticalEdge
	var scrolledPosition: ScrolledPosition
	var phase: ScrollPhase
}
