//  ComposeBar.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import PhotosUI
import Services
import _AVKit_SwiftUI

struct ComposeBar: View {
    
    @Environment(ChatManager.self) private var manager
    @Environment(ChatComposer.self) private var composer
    @Environment(\.conversationTheme) private var theme
    
    var body: some View {
        let state = composer.state
        VStack(spacing: 0) {
            sourcePanel(state)
            HStack(alignment: .bottom, spacing: 4) {
                menuButton(state)
                sourceButtons(state)
                DocumentPickerButton()
                ComposeBarInputTextField(inputText: composer.inputText)
                ComposeBarSendButton()
            }
            .soundEffect(.latch4, trigger: state)
            .padding(.init(top: 0, leading: 8, bottom: 0, trailing: 8))
            .background(
                LinearGradient(
                    colors: [
                        .clear,
                        theme.backgroundColor,
                        theme.backgroundColor
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ), ignoresSafeAreaEdges: .bottom
            )
        }
        .geometryGroup()
    }
}

private extension ComposeBar {
    
    @ViewBuilder
    func sourcePanel(_ state: ChatComposer.State) -> some View {
        if let source = state.source, source.usesInlinePanel {
            switch source {
            case .emoji:
                EmojiPanel()
            case .document:
                Text(.init(composer.fileContent))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            case .camera, .liary, .machineImag:
                ComposeBarAttachmentView()
            case .audio:
                EmptyView()
            }
        } else if state.attachments.isEmpty == false {
            ComposeBarAttachmentView()
        }
    }

    func menuButton(_ state: ChatComposer.State) -> some View {
        HamburgerButton(
            isOpen: .init(
                get: { state.menuIsOpened },
                set: { composer.state.menuIsOpened = $0 }
            ),
            size: 38
        ) { newValue in
            if newValue {
                manager.focusState?.defocus()
            } else {
                composer.updateSource(nil)
            }
        }
    }

    @ViewBuilder
    func sourceButtons(_ state: ChatComposer.State) -> some View {
        if state.menuIsOpened, state.source == nil {
            SourceButtonRow(sources: ChatComposer.Source.mediaSources)
            SourceButtonRow(sources: ChatComposer.Source.utilitySources)
        }
    }

    struct SourceButtonRow: View {
        let sources: [ChatComposer.Source]

        var body: some View {
            HStack(alignment: .center, spacing: -8) {
                ForEach(sources) { source in
                    ComposerSourceButton(source: source)
                }
            }
            .frame(height: ChatLayoutConstants.bottomBarHeight)
        }
    }

    struct EmojiPanel: View {

        var body: some View {
            EmojiPicker { emoji in
                composer.inputText.append(emoji.value)
            }
        }

        @Environment(ChatComposer.self) private var composer
    }
}
