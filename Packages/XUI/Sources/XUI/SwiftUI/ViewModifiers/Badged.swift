//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

private struct XBadgedModifier: ViewModifier {
    let string: String
    func body(content: Content) -> some View {
        HStack(alignment: .bottom, spacing: 4) {
            content
            Text(.init(string))
                .font(.footnote)
                .italic()
                .foregroundStyle(.secondary)
        }
    }
}

public extension View {
    func badged(_ string: String) -> some View {
        ModifiedContent(content: self, modifier: XBadgedModifier(string: string))
    }
}
