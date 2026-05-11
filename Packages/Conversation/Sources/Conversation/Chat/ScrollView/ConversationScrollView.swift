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
                manager: manager.layoutManager,
                config: .init(
                    spacing: 0,
                    contentInsets: .init(
                        top: ChatLayoutConstants.topBarHeight,
                        leading: Padding.sm,
                        bottom: 0,
                        trailing: Padding.sm
                    ),
                    screenSize: UIApplication.shared.screenSize()
                )
            ) {
                ForEach(manager.models.storage) { model in
                    MsgCell(viewModel: model)
                }
            }
            .scrollTargetLayout()
        }
        .tint(Color.tint)
        .equatable(by: manager.state.reloadID)
        .scrollEdgeEffectHidden(true, for: .all)
        .scrollDismissesKeyboard(.never)
        .safeAreaPadding(
            .bottom,
            ChatLayoutConstants.bottomBarHeight
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
            ids in
            manager.onScrollTargetVisibilityChange(ids)
        }
        .defaultScrollAnchor(.bottom, for: .initialOffset)
        .scrollIndicatorsFlash(trigger: manager.state.reloadID)
        .scrollClipDisabled()
        .scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(
            manager.models.isAbsoluteScrolled(at: .bottom) ? .bottom : nil,
            for: .sizeChanges
        )
        .scrollPosition(
            manager.scrollController.scrollPositionBindable,
            anchor: .bottom
        )
    }
}
