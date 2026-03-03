//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct OnNumberOfLinesChangeViewModifier: ViewModifier {
    let onChange: (Int) -> Void
    func body(content: Content) -> some View {
        content.onPreferenceChange(Text.LayoutKey.self) { textLayout in
            var count = 0

            for layout in textLayout {
                count += layout.layout.count
            }

            if count != numberOfLines {
                onChange(count)
            }

            numberOfLines = count
        }
    }

    @State private var numberOfLines: Int = 0
}

public extension View {
    /// Counts the number of lines it takes to draw a string, including word
    /// wrapping.
    ///
    /// This doesn't count the number of newline characters in a string.
    func onNumberOfLinesChange(_ onChange: @escaping (Int) -> Void) -> some View {
        modifier(OnNumberOfLinesChangeViewModifier(onChange: onChange))
    }
}
