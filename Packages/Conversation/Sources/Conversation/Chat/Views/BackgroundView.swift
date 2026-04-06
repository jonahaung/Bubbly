import SwiftUI
import Services
import Database
import XUI

struct BackgroundView: View {
	@Environment(ChatManager.self) private var manager
	var body: some View {
		Image("adaptive")
			.resizable(resizingMode: .tile)
			.foregroundStyle(.placeholder)
			.background(manager.state.properties.theme.background.color)
			.backgroundExtensionEffect()
			.equatable(by: manager.state.properties.theme.background)
	}
}
