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
                config: layoutConfiguration
            ) {
                if manager.messages.shouldShowHeader {
                    HeaderProfileView(conversation: manager.state.conversation)
                }
                ForEach(manager.messages.wrappedValue) { model in
                    MsgCell(viewModel: model)
                }
            }
            .equatable(by: manager.reloadID)
            .scrollTargetLayout()
        }
        .tint(Color.tint)
        .scrollEdgeEffectHidden(true, for: .all)
        .scrollDismissesKeyboard(.never)
        .contentMargins(
            .bottom,
            ChatLayoutConstants.bottomBarHeight,
            for: .scrollContent
        )
        .onScrollPhaseChange { oldPhase, newPhase, context in
            manager.send(
                .scrollViewIntent(
                    .onScrollPhaseChange(oldPhase, newPhase, context: context)
                )
            )
        }
        .onScrollGeometryChange(for: VScrollGeometry.self, of: { .init($0) }) {
            oldValue,
            newValue in
            manager.send(
                .scrollViewIntent(.onScrollGeometryChange(oldValue, newValue))
            )
        }
        .onScrollTargetVisibilityChange(idType: String.self, threshold: 0.1) {
            manager.onScrollTargetVisibilityChange($0)
        }
        .defaultScrollAnchor(.bottom, for: .initialOffset)
        .scrollClipDisabled()
        .defaultScrollAnchor(defaultScrollAnchor, for: .sizeChanges)
        .scrollPosition(
            manager.scrollController.scrollPositionBindable,
            anchor: .bottom
        )
    }

    private var layoutConfiguration: MsgsScrollViewLayoutConfiguration {
        MsgsScrollViewLayoutConfiguration(
            spacing: 0,
            contentInsets: .init(
                top: ChatLayoutConstants.topBarHeight,
                leading: Padding.sm,
                bottom: 0,
                trailing: Padding.sm
            ),
            screenBounds: UIApplication.shared.screenBounds()
        )
    }

    private var defaultScrollAnchor: UnitPoint? {
        manager.presentation.state.bottomAccessory == .scrollDownButton
            ? .none : .bottom
    }
}
