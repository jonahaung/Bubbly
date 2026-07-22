//  ComposeBarInputTextField.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Services
import SwiftUI
import XUI

extension ComposeBar {
    struct ComposeBarInputTextField: View {
        let inputText: InputText
        @Environment(\.sharedFocusState) private var focusState

        var body: some View {
            if let focusState {
                DispatchingChanges(to: inputText.text, id: Self.typeName) { text in
                    TextField(
                        "Text ...",
                        text: .init(get: { text }, set: { inputText.set(text: $0) }),
                        axis: .vertical
                    )
                    .lineLimit(1...10)
                    .font(.system(size: UIFont.labelFontSize))
                    .lineHeight(.multiple(factor: 1.3))
                    .focused(focusState.binding, equals: .inputTextField)
                    .padding(.init(top: 8, leading: 12, bottom: 8, trailing: 8))
                    .tint(.link)
                    .background(
                        Color.appPrimary,
                        in: RoundedRectangle(
                            cornerRadius: UIFont.labelFontSize,
                            style: .continuous
                        )
                    )
                    .accessibilityElement(children: .contain)
                }
            }
        }
    }
}
