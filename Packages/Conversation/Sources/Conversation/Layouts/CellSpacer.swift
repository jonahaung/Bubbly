import Core
import Database
import SwiftUI

extension MsgCell {
	struct CellSpacer: View {
		var body: some View {
			Color.white.hidden()
				.frame(height: ChatLayoutConstants.Cell.sectionSpacing)
		}
	}
}
