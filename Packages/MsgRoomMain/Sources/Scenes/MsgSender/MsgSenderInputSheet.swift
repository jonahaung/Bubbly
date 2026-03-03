//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI
import XUI

struct MsgSenderInputSheet: View {
    let conversationName: String
    @State private var inputText = ""
    @State private var executor = ToolExecutor()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused
    @State private var isCopied = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    ToolInputField(
                        label: "Enter message to send",
                        text: $inputText,
                        placeholder: "Text ..."
                    )
                    .focused($isFocused)

                    if let result = executor.result {
                        ResultDisplay(result: result, isSuccess: executor.successMessage != nil)
                    }
                }.padding()
            }
            .navigationTitle(conversationName)
            .safeAreaBar(edge: .bottom) {
                ToolExecuteButton(
                    "Send Message",
                    systemImage: "bubbles.and.sparkles.fill",
                    isRunning: executor.isRunning,
                    action: executeMsgSend
                )
                .padding()
                .disabled(inputText.isEmpty)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: copyToClipboard) {
                        Image(systemSymbol: .docOnDoc)
                    }
                }
            }
            .onAppear(after: 0.5) {
                isFocused = true
            }
        }
    }

    private func executeMsgSend() {
        Task {
            let text = inputText
            clear()
            await executor
                .execute(
                    tool: MsgSenderTool(),
                    prompt: "send message to conversation name: \(conversationName) and text: \(text)",
                    type: MsgSenderToolOutput.self
                ) { model in
                    model.text
                } clearForm: {
                    clear()
                }
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = executor.result
        ToastPresenter.shared
            .show(.init(message: "Copied to clipboard", allowsBackgroundTap: false))
    }

    private func clear() {
        inputText = String()
        isCopied = false
    }
}
