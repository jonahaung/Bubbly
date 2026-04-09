// © 2026 Aung Ko Min

import Core
import Services
import SwiftUI
import XUI

extension ComposeBar {
    struct ComposeBarInputTextField: View {
        @Bindable var composer: ChatComposer
        @Environment(\.sharedFocusState) private var focusState

        var body: some View {
            if let focusState {
                TextField(
                    text: composer.inputText
                        .bindableText,
                    axis: .vertical,
                ) {
                    if let source = composer.state.source {
                        Text("\(Image(systemName: source.systemImageName)) \(source.localizedName)")
                            .symbolRenderingMode(.multicolor)
                    } else {
                        Text("Text ...")
                    }
                }
                .lineLimit(1 ... 10)
                .tint(.link)
                .padding(.init(top: 10, leading: 16, bottom: 10, trailing: 8))
                .focused(
                    focusState.binding,
                    equals: "textField",
                )
                .background(
                    Color.appPrimary,
                    in: RoundedRectangle(cornerRadius: UIFont.buttonFontSize),
                )
                .font(.system(size: UIFont.buttonFontSize))
            }
        }
    }
}
