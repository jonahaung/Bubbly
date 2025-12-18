//
//  ChatTopBarView.swift
//  Msgr
//
//  Created by Aung Ko Min on 22/10/22.
//

import Core
import Services
import SwiftUI
import XUI

struct ChatTopBarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ChatViewManager.self) private var manager
	@Environment(\.conversationTheme) private var theme

    var body: some View {
        HStack {
            AsyncButton {
				await manager.saveConversationChanges()
                dismiss()
            } label: {
                SystemImage(.chevronLeft)
                    .bold()
                    .imageScale(.large)
                    .padding(.init([.top, .bottom, .leading]))
            }
            Spacer()
            VStack(spacing: 0) {
                Text(manager.conversation.name)
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold,
                            design: .rounded
                        )
                    ).badgeView(
                        Text(
                            manager.config.totalMsgsCount,
                            format: .number
                        ).font(
                            .footnote.italic()
                        )
                    )
            }
            .onTapGesture {
                Router.shared
                    .push(
                        NavPath
                            .conversationDetails(manager.conversation)
                    )
            }
            Spacer()
            AsyncButton {} label: {
                SystemImage(.quoteClosing, 18)
                    .padding(.init([.top, .bottom, .trailing]))
            }
        }
		.background(theme.backgroundColor, ignoresSafeAreaEdges: [.leading, .trailing, .top])
    }
}
