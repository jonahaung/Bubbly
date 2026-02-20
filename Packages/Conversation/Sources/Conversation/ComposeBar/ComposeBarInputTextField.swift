import Services
import SwiftUI
import XUI

extension ComposeBar {
	struct ComposeBarInputTextField: View {
		@Bindable var composer: ChatComposer
		@Environment(\.sharedFocusState) private var focusState
		@Environment(\.conversationTheme) private var theme
		var body: some View {
			ZStack(alignment: .trailing) {
				textField()
			}
			.background(.windowBackground, in: .containerRelative)
			.containerShape(RoundedRectangle(cornerRadius: theme.bubbleCornerRadius))
		}

		private func textField() -> some View {
			TextField(
				"\(composer.source.rawValue)",
				text: $composer.inputText
					.text, selection: $composer.inputText.selection, axis: .vertical
			)
			.lineLimit(0 ... 10)
			.font(.body)
			.tint(.link)
			.padding(.init(top: 8, leading: 16, bottom: 8, trailing: 8))
			.focused(
				focusState.unsafelyUnwrapped.binding,
				equals: composer.source.rawValue
			)
		}
	}
}
