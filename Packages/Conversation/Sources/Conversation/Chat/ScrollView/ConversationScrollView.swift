// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

struct ConversationScrollView: View {
    // MARK: Internal

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            ForEach(manager.models.headerModels) { model in
                switch model.kind {
                case let .conversation(conversation):
                    HeaderProfileView(conversation: conversation)
                        .id(conversation.uid)
                }
            }
            if lazyScrollView {
                LazyVStack(spacing: manager.conversationConfig.lineSpacing) {
                    ForEach(manager.models.renderedModels, id: \.id) { identified in
                        let model = identified.value
                        MsgCell(viewModel: model)
                            .onScrollVisibilityChange { isVisible in
                                model.setVisibility(isVisible)
                                if isVisible, model.state.layout.showTopPadding {
                                    manager.presentation.send(.date(model.msg.date))
                                }
                            }
                            .id(identified.id)
                    }
                }
                .equatable(by: manager.state.reloadID)
                .geometryGroup()
            } else {
                VStack(spacing: manager.conversationConfig.lineSpacing) {
                    ForEach(manager.models.renderedModels) { identified in
                        let model = identified.value
                        MsgCell(viewModel: model)
                            .onScrollVisibilityChange { isVisible in
                                model.setVisibility(isVisible)
                                if isVisible, model.state.layout.showTimeSeparator {
                                    manager.presentation.send(.date(model.msg.date))
                                }
                            }
                            .id(identified.id)
                    }
                }
                .equatable(by: manager.state.reloadID)
                .geometryGroup()
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .vertical)
        .tint(Color.tintColor)
        .foregroundStyle(Color.primaryText)
        .contentMargins(.top, ChatLayoutConstants.topBarHeight, for: .scrollContent)
        .contentMargins(.bottom, manager.layout.bottomBarFrame?.height, for: .scrollContent)
        .scrollDismissesKeyboard(.never)
        .scrollBounceBehavior(.always, axes: .vertical)
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
        .onScrollPhaseChange { oldPhase, newPhase, context in
            manager.send(.onScrollPhaseChange(oldPhase, newPhase, context: context))
        }
        .onScrollGeometryChange(
            for: VScrollGeometry.self,
            of: { .init($0) },
        ) { oldValue, newValue in
            manager.send(.onScrollGeometryChange(oldValue, newValue))
        }
        .equatable(by: manager.state.reloadID)
        .scrollPosition(manager.scrollController.scrollPositionBindable, anchor: .none)
    }

    // MARK: Private

    @Environment(ChatManager.self) private var manager
    @AppStorage("Lazy Scroll View") private var lazyScrollView: Bool = true
}
