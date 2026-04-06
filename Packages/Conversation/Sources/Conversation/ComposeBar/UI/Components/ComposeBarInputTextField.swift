#if os(iOS)
//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Services
import SwiftUI
import XUI
import Core

extension ComposeBar {
    struct ComposeBarInputTextField: View {
        @Bindable var composer: ChatComposer
        @Environment(\.sharedFocusState) private var focusState

        var body: some View {
			if let focusState {
				TextField(text: composer.inputText
					.bindableText, axis: .vertical) {
						if let source = composer.state.source {
							Text("\(Image(systemName: source.systemImageName)) \(source.localizedName)")
								.symbolRenderingMode(.multicolor)
						} else {
							Text("Text ...")
						}
					}
					.lineLimit(1...10)
					.tint(.link)
					.padding(.init(top: 10, leading: 16, bottom: 10, trailing: 8))
					.focused(
						focusState.binding,
						equals: "textField"
					)
					.background(.windowBackground, in: RoundedRectangle(cornerRadius: 18))
//					.frame(minHeight: ChatLayoutConstants.bottomBarHeight, alignment: .bottom)
			}
        }
    }
}

#endif
