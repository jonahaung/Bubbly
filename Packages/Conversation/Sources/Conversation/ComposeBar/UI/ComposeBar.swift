// © 2026 Aung Ko Min

#if os(iOS)
//
    // Copyright © 2026 Aung Ko Min. All rights reserved.
//

    import _AVKit_SwiftUI
    import Core
    import PhotosUI
    import Services
    import SwiftUI
    import XUI

    struct ComposeBar: View {
        @Environment(ChatComposer.self) private var composer
        @Environment(\.conversationTheme) private var theme

        var body: some View {
            VStack(spacing: 0) {
                if let source = composer.state.source {
                    switch source {
                    case .emoji:
                        ModalOverlay(.bottom, from: .bottom, allowsBackgroundTap: true) {
                            EmojiPanel()
                        } onClose: {
                            composer.updateSource(nil)
                        }
                    case .camera:
                        ComposeBarAttachmentView()
                    case .document:
                        Text(.init(composer.fileContent))
                    default:
                        ComposeBarAttachmentView()
                    }
                }
                HStack(alignment: .bottom, spacing: 4) {
                    HamburgerButton(
                        isOpen: .init(
                            get: { composer.state.menuIsOpened },
                            set: { composer.state.menuIsOpened = $0 },
                        ),
                        size: 38,
                    ) { newValue in
                        if !newValue {
                            composer.updateSource(nil)
                        }
                    }
                    if composer.state.menuIsOpened {
                        if composer.state.source == nil {
                            HStack(alignment: .center, spacing: -8) {
                                ComposerSourceButton(source: .camera)
                                ComposerSourceButton(source: .liary)
                                ComposerSourceButton(source: .audio)
                            }
                            .frame(height: ChatLayoutConstants.bottomBarHeight)

                            HStack(alignment: .center, spacing: -8) {
                                ComposerSourceButton(source: .document)
                                ComposerSourceButton(source: .machineImag)
                                ComposerSourceButton(source: .emoji)
                            }
                            .frame(height: ChatLayoutConstants.bottomBarHeight)
                        }
                    }
                    ComposeBarInputTextField(composer: composer)
                    ComposeBarSendButton()
                }
                .animation(.easeIn(duration: 0.20), value: composer.state.menuIsOpened)
                .animation(.easeIn(duration: 0.20), value: composer.state.source == nil)
                .padding(.init(top: 0, leading: 8, bottom: 0, trailing: 8))
                .background(
                    LinearGradient(
                        colors: [
                            .clear,
                            theme.backgroundColor,
                        ],
                        startPoint: .top,
                        endPoint: .bottom,
                    ), ignoresSafeAreaEdges: .all,
                )
                .geometryGroup()
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
    }

    fileprivate extension ComposeBar {
        struct EmojiPanel: View {
            @Environment(ChatComposer.self) private var composer

            var body: some View {
                EmojiPicker { emoji in
                    composer.inputText.text.append(emoji.value)
                }
                .background(.regularMaterial, in: .rect)
            }
        }
    }

#endif
