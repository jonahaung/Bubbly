import SwiftUI

enum ScrollViewIntent {
	case onVisibilityChange(visibility: Visibility)
	case onScrollGeometryChange(_ oldValue: VScrollGeometry, _ newValue: VScrollGeometry)
	case onScrollPhaseChange(_ oldValue: ScrollPhase, _ newPhase: ScrollPhase, context: ScrollPhaseChangeContext)
	case onScrollTargetVisibilityChange(_ newValue: [String])
	case onBottomBarFrameChage(_ oldValue: CGRect, _ newValue: CGRect)
}
