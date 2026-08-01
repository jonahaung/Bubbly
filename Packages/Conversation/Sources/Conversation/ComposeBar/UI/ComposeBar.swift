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
            if composer.selection.isEmpty == false {
                HStack {
                    ForEach(composer.selection, id: \.absoluteString) { url in
                        Text(url.lastPathComponent)
                            .lineLimit(1)
                            .padding(.horizontal, 4)
                            .background(url.absoluteString.color)
                            .font(Typography.system.caption2)
                    }
                }
            }
            HStack(alignment: .bottom, spacing: 4) {
                menuButton(state)
                sourceButtons(state)
                
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
        .quickLookPreview(.init(get: { composer.lookUp }, set: { composer.lookUp = $0 }), in: composer.selection)
        .geometryGroup()
    }
}

private extension ComposeBar {

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
                composer.selection.removeAll()
            }
        }
    }

    @ViewBuilder
    func sourceButtons(_ state: ChatComposer.State) -> some View {
        if state.menuIsOpened, state.source == nil {
            if !composer.selection.isEmpty {
                CustomButton {
                    composer.lookUp = composer.selection.first
                } label: {
                    Image(systemName: "\(composer.selection.count).circle.fill")
                        .resizable()
                        .scaledToFit()
                        .changeEffect(.pulse(shape: .circle), value: composer.selection.count)
                        .frame(square: 32)
                        .background(Color.appPrimary, in: .circle)
                        .foregroundStyle(.blue)
                }
            }
            HStack(alignment: .center, spacing: -8) {
                CameraPickerButton()
                LibraryPickerButton()
                AudioRecorderButton()
                DocumentPickerButton()
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
