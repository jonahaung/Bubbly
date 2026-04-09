// © 2026 Aung Ko Min

#if os(iOS)
//
    // Copyright © 2026 Aung Ko Min. All rights reserved.
//

    import SwiftUI
    import XUI

    struct EmojiPicker: View {
        var onSelect: (Emoji) -> Void
        private let emojis = EmojiRepository.shared.emojis
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
                        .id(emoji.id)
                    }
                }.padding(.leading, 8)
            }
            .fixedSize(horizontal: false, vertical: true)
            .equatable(by: 1)
        }

        var rows: [GridItem] {
            Array(repeating: GridItem(.fixed(30)), count: 4)
        }
    }

#endif
