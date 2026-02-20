import SwiftUI
import XUI

extension MsgCell {
	@MainActor
	struct TextContent: View, @MainActor Equatable {
		static let font = UIFont.preferredFont(forTextStyle: .body)
		let text: String

		var body: some View {
			let extraTop = text.containsTallMarksOrEmoji ? max(
				1,
				(Self.font.ascender - Self.font.capHeight) * 0.25
			) : 0
			if text.containsMarkdown {
				Text(LocalizedStringKey(text))
					.lineSpacing(extraTop)
					.fixedSize(horizontal: false, vertical: true)

			} else {
				Text(text)
					.customAttribute(HighlightAttribute())
					.lineSpacing(extraTop)
					.fixedSize(horizontal: false, vertical: true)
			}
		}

		static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.text == rhs.text
		}
	}
}

extension String {
	var containsTallMarksOrEmoji: Bool {
		for ch in self {
			for s in ch.unicodeScalars {
				if s.properties.generalCategory == .nonspacingMark { return true }
				if s.properties.isEmojiPresentation { return true }
			}
		}
		return false
	}
}
