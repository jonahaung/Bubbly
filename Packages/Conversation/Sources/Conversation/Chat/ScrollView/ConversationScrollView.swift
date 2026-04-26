//  ConversationScrollView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database
import Services

struct ConversationScrollView: View {
    
    let manager: ChatManager
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            MsgsScrollViewLayout(
                manager: manager.layoutManager,
                config: .init(
                    spacing: manager.conversationConfig.lineSpacing,
                    contentInsets: .init(
                        top: ChatLayoutConstants.topBarHeight, leading: Padding.sm, bottom: 0,
                        trailing: Padding.sm
                    ), screenSize: UIApplication.shared.screenSize()
                )
            ) {
                ForEach(manager.models.headerModels) { model in
                    switch model.kind {
                    case let .conversation(conversation):
                        HeaderProfileView(conversation: conversation)
                            .id(conversation.uid)
                            .layoutValue(
                                key: MsgLayoutValueKey.self,
                                value: .init(uid: conversation.uid, recipient: .system, attachmentsCount: 0, headerStatus: 0)
                            )
                    }
                }
                ForEach(manager.models.renderedModels) { model in
                    MsgCell(viewModel: model)
                        .id(model.id)
                        .layoutValue(key: MsgLayoutValueKey.self, value: model.msg.layoutValue(layout: model.state.layout))
                }
            }
            .geometryGroup()
            .scrollTargetLayout()
        }
        .tint(Color.tint)
        .scrollEdgeEffectHidden(true, for: .all)
        .scrollDismissesKeyboard(.never)
        .safeAreaPadding(.bottom, ChatLayoutConstants.bottomBarHeight)
        .onScrollPhaseChange { oldPhase, newPhase, context in
            manager.send(
                .scrollViewIntent(.onScrollPhaseChange(oldPhase, newPhase, context: context))
            )
        }
        .onScrollGeometryChange(for: VScrollGeometry.self, of: { .init($0) }) { oldValue, newValue in
            manager.send(.scrollViewIntent(.onScrollGeometryChange(oldValue, newValue)))
        }
        .onScrollTargetVisibilityChange(idType: String.self, threshold: 0.01) { ids in
            manager.onScrollTargetVisibilityChange(ids)
        }
        .defaultScrollAnchor(.bottom, for: .initialOffset)
        .equatable(by: manager.state.reloadID)
        .defaultScrollAnchor(
            manager.presentation.state.bottomAccessory == .scrollDownButton ? nil : .bottom,
            for: .sizeChanges
        )
        .scrollPosition(manager.scrollController.scrollPositionBindable, anchor: .bottom)
    }
}
