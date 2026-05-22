//  ComposeBarAttachmentView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI

extension ComposeBar {
    struct ComposeBarAttachmentView: View {
        @Environment(ChatComposer.self) private var composer: ChatComposer

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    ForEach(composer.state.attachments) { attachment in
                        AttachmentPreview(attachment: attachment) {
                            log($0)
                        }
                        .cornerRadius(8)
                        .frame(maxWidth: 200, maxHeight: 100)
                        .badgeView(
                            Button {
                                composer.removeAttachment(id: attachment.uid)
                            } label: {
                                SystemImage(.minus, 10)
                                    .foregroundStyle(Color.white)
                                    .padding(5)
                                    .background(Color.red, in: .circle)
                            }
                            .buttonStyle(.borderless)
                        )
                        .transition(.move(edge: .leading).animation(.bouncy))
                        .id(attachment.uid)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .scrollTargetLayout()
            }
            .scrollPosition(id: .constant(composer.state.attachments.last?.uid))
            .scrollBounceBehavior(.basedOnSize)
            .scrollClipDisabled()
            .contentMargins(.leading, 16, for: .scrollContent)
            .contentMargins(.top, 16, for: .scrollContent)
        }
    }
}
