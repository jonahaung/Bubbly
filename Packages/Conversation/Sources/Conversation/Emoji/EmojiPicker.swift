import SwiftUI

struct EmojiPicker: View {
	var onSelect: (Emoji) -> Void
	@State private var emojis = [Emoji]()
	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			LazyHGrid(rows: rows) {
				ForEach(emojis) { emoji in
					Button {
						onSelect(emoji)
					} label: {
						Text(emoji.value)
							.font(.title3)
					}
				}
			}.padding(.leading, 8)
		}
		.fixedSize(horizontal: false, vertical: true)
		.task {
			emojis = EmojiRepository.shared.emojis
		}
	}

	var rows: [GridItem] {
		Array(repeating: GridItem(.fixed(30)), count: 4)
	}
}
