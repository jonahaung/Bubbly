//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Core
import Database
import ImageLoader
import Services
import SwiftUI
import XUI

struct ChatViewState: Equatable {
    var reloadID: Int
    var conversation: Conversation
    var theme: ChatTheme
    var properties: ConversationProperties

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.reloadID == rhs.reloadID
    }
}

@MainActor
@Observable
final class ChatViewManager: ErrorPresenter {

    @ObservationIgnored let messageSource: ChatDatasource
    @ObservationIgnored let scrollController: ChatScrollCoordinator
    @ObservationIgnored var presentation: ChatPresentationState
    @ObservationIgnored var conversationConfig: ConversationInitializer.Configuration
    @ObservationIgnored let attachmentFetcher: AttachmentFetcher
    @ObservationIgnored let layoutManager: MsgsScrollViewLayoutManager

    @ObservationIgnored let models: MsgModels
    var state: ChatViewState
    var conversation: Conversation {
        state.conversation
    }

    init(_ data: ConversationInitializer.PrefetchedData) {

        layoutManager = .init(
            config: .init(
                data.configuration.lineSpacing,
                data.configuration.contentInsets
            )
        )
        conversationConfig = data.configuration
        messageSource = .init(data.configuration)
        scrollController = .init()
        presentation = .init(data.configuration)
        attachmentFetcher = .init()
        models = .init(data.msgs)

        state = .init(
            reloadID: 0,
            conversation: data.conversation, theme: .init(data.properties.theme),
            properties: data.properties
        )
        scrollController.delegate = self
        messageSource.delegate = self
    }

    deinit {
        log("Deinit")
    }
}

extension ChatViewManager {
    func layoutIfNeeded() {
        state.reloadID += 1
    }

    func onViewAppear() async throws {
        try await reloadConversation(refetch: scrollController.updateState(is: .initial))
        updateReceiveMsgs()
    }

    func send(_ intent: ChatScrollCoordinator.Intent) {
        scrollController.send(intent)
    }

    func handleScrollDownButtonTap() {
        if canResetDatasource {
            resetDatasource()
        } else {
            scrollController.send(.scrollTo(.snapToBottom(), enqueue: true))
        }
    }

    func setSelectedMsg(_ uid: String) {
        guard let index = models.index(of: uid) else { return }
        let oldValue = layoutManager.selectedMsg

        let nextMsg = models[safe: index + 1]?.msg
        let previousMsg = models[safe: index - 1]?.msg
        let newValue: SelectedMsg? =
            oldValue?.id == uid
                ? nil
                : SelectedMsg(
                    id: uid,
                    previous: previousMsg?.uid,
                    next: nextMsg?.uid
                )
        if let oldValue {
            models.didChangeSelection(newValue, for: oldValue.id)
            if let id = oldValue.next {
                models.didChangeSelection(newValue, for: id)
            }
            if let id = oldValue.previous {
                models.didChangeSelection(newValue, for: id)
            }
        }
        if let newValue {
            models.didChangeSelection(newValue, for: newValue.id)
            if let id = newValue.next {
                models.didChangeSelection(newValue, for: id)
            }
            if let id = newValue.previous {
                models.didChangeSelection(newValue, for: id)
            }
        }
        layoutManager.updateSelectedMsg(newValue)
        layoutIfNeeded()
    }
}
