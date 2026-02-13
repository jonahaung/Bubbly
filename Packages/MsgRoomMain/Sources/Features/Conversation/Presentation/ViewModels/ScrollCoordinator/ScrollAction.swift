import SwiftUI

enum ScrollAction {
	case viewLoaded
	case geometryChanged(old: VScrollGeometry, new: VScrollGeometry)
	case phaseChanged(old: ScrollPhase, new: ScrollPhase, context: ScrollPhaseChangeContext)
	case inputAccessoryChanged(old: CGRect, new: CGRect)
}
