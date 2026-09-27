//  ConversationScrollView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct ConversationScrollView: View {

    let manager: ChatManager

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            MsgsScrollViewLayout(
                manager: manager.messages.layout,
                config: layoutConfiguration()
            ) {
                HeaderProfileView(
                    conversation: manager.state.conversation, showHeader: manager.messages.shouldShowHeader)
                ForEach(manager.messages.wrappedValue) { model in
                    MsgCell(viewModel: model)
                }
            }
            .equatable(by: manager.reloadID)
            .scrollTargetLayout()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .scrollDismissesKeyboard(.never)
        .safeAreaPadding(.vertical, ChatLayoutConstants.bottomBarHeight)
        .onScrollPhaseChange { oldPhase, newPhase, context in
            manager.send(
                .scrollViewIntent(
                    .onScrollPhaseChange(oldPhase, newPhase, context: context)
                )
            )
        }
        .onScrollGeometryChange(for: VScrollGeometry.self, of: { .init($0) }) { oldValue, newValue in
            manager.send(
                .scrollViewIntent(.onScrollGeometryChange(oldValue, newValue))
            )
        }
        .onScrollTargetVisibilityChange(idType: String.self, threshold: 0.1) {
            manager.onScrollTargetVisibilityChange($0)
        }
        .defaultScrollAnchor(.bottom, for: .initialOffset)

        .defaultScrollAnchor(defaultScrollAnchor, for: .sizeChanges)
        .scrollPosition(
            .constant(manager.scrollController.scrollPosition),
            anchor: .bottom
        )
    }

    private func layoutConfiguration() -> MsgsScrollViewLayoutConfiguration {
        MsgsScrollViewLayoutConfiguration(
            spacing: 0,
            contentInsets: .init(
                top: 0,
                leading: Padding.md,
                bottom: 0,
                trailing: Padding.md
            ),
            screenSize: UIApplication.shared.screenBounds().size
        )
    }

    private var defaultScrollAnchor: UnitPoint? {
        manager.presentation.state.bottomAccessory == .scrollDownButton
            ? .zero : .bottom
    }
}
