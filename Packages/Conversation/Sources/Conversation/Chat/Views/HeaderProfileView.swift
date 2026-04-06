import SwiftUI
import XUI

struct HeaderProfileView: View {
	@Environment(ChatManager.self) private var manager

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text(manager.state.conversation.name)
				.bold()
			Text(manager.state.properties.preetyPrinted)
				.font(.caption)
			Text(manager.state.conversation.preetyPrinted)
				.font(.caption2)
		}
		.lineHeight(.multiple(factor: 1.2))
		.padding()
		.background(.windowBackground)
		.containerShape(RoundedRectangle(cornerRadius: 12))
		.padding()
		.id(Self.typeName)
	}
}
