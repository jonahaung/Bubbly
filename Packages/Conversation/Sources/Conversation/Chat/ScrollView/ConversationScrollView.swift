// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

struct ConversationScrollView: View {

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            MsgsScrollViewLayout(
                manager: manager.layoutManager,
                config: .init(
                    spacing: manager.conversationConfig.lineSpacing,
                    contentInsets: .init(
                        top: ChatLayoutConstants.topBarHeight,
                        leading: Padding.sm,
                        bottom: 0,
                        trailing: Padding.sm
                    ),
                    boundsWidth: UIApplication.shared.screenSize().width
                )
            ) {
                ForEach(manager.models.headerModels) { model in
                    switch model.kind {
                    case .conversation(let conversation):
                        HeaderProfileView(conversation: conversation)
                            .id(conversation.uid)
                            .layoutValue(
                                key: MsgLayoutValueKey.self,
                                value: .init(
                                    uid: conversation.uid,
                                    recipient: .system,
                                    attachmentsCount: 0,
                                    headerStatus: 0
                                )
                            )
                    }
                }

                ForEach(manager.models.renderedModels) { model in
                    MsgCell(viewModel: model)
                        .id(model.id)
                        .layoutValue(
                            key: MsgLayoutValueKey.self,
                            value: model.msg.layoutValue(
                                layout: model.state.layout
                            )
                        )
                }
            }
            .geometryGroup()
            .scrollTargetLayout()
        }
        .tint(Color.tint)
        .foregroundStyle(Color.primaryText)
        .scrollDismissesKeyboard(.never)
        .safeAreaPadding(.bottom, ChatLayoutConstants.bottomBarHeight)
        .onScrollPhaseChange { oldPhase, newPhase, context in
            manager.send(
                .scrollViewIntent(
                    .onScrollPhaseChange(oldPhase, newPhase, context: context)
                )
            )
        }
        .onScrollGeometryChange(
            for: VScrollGeometry.self,
            of: { .init($0) },
        ) { oldValue, newValue in
            manager.send(
                .scrollViewIntent(.onScrollGeometryChange(oldValue, newValue))
            )
        }
        .onScrollTargetVisibilityChange(idType: String.self, threshold: 0.1) {
            ids in
            manager.models.didBecomeVisible(ids: ids)
        }
        .defaultScrollAnchor(.top, for: .initialOffset)
        .equatable(by: manager.state.reloadID)
        .defaultScrollAnchor(
            manager.presentation.state.bottomAccessory == .scrollDownButton
                ? nil : .bottom,
            for: .sizeChanges
        )
        .scrollPosition(
            manager.scrollController.scrollPositionBindable,
            anchor: nil
        )
    }

    @Environment(ChatManager.self) private var manager
}
