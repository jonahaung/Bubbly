import SFSafeSymbols
import SwiftUI
import XUI

struct ChatAccessoryBar: View {
	@Environment(ChatViewManager.self) private var manager
	@Namespace private var chatNoticeView

	var body: some View {
		HStack(alignment: .bottom) {
			if let accessory = manager.presentation.bottomAccessory {
				Spacer()
				if accessory == .scrollDownButton {
					AsyncButton {
						manager.resetDatasource()
					} label: {
						Image(systemName: "chevron.down")
							.resizable()
							.scaledToFit()
							.padding(12)
							.frame(square: 40)
							.background(.windowBackground, in: .circle)
					}
					.transition(
						.scale(scale: 0).animation(.bouncy)
					)
				}
			}
		}
		.padding(.horizontal, 16)
		.geometryGroup()
	}
}
