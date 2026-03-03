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
    var theme: ConversationTheme

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
    @ObservationIgnored let conversationConfig: ConversationInitializer.Configuration
    @ObservationIgnored let attachments = AttachmentFetcher.shared
    @ObservationIgnored let layoutManager: MsgsScrollViewLayoutManager
//    @ObservationIgnored let debouncer = Debouncer(interval: .seconds(0.3))

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
        models = .init(data.msgs)
        state = .init(
            reloadID: 0,
            conversation: data.conversation, theme: .init(data.conversation)
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
        state.conversation = try await state.conversation.reload(
            refetch: scrollController.updateState(is: .initial)
        )
        updateReceiveMsgs()
    }

    func send(_ intent: ChatScrollCoordinator.Intent) {
        scrollController.send(intent)
    }

    func handleScrollDownButtonTap() {
        if canLoadNewerMessages {
            resetDatasource()
        } else {
            scrollController.send(.scrollTo(.edge(.bottom, animation: .smooth), enqueue: true))
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
            models.element(withID: oldValue.id)?.layoutIfNeeded()
        }
        if let newValue {
            models.element(withID: newValue.id)?.layoutIfNeeded()
        }
        layoutManager.updateSelectedMsg(newValue)
        layoutIfNeeded()
    }
}
