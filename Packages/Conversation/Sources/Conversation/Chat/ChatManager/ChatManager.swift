//  ChatManager.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import Combine
import SwiftUI
import Database
import Services
import ImageLoader

@MainActor @Observable final class ChatManager: ErrorPresenter {
    init(
        _ data: ConversationInitializer.PrefetchedData,
        contactsRepository: ContactsRepositoryProtocol,
        currentUserRepository: CurrentUserRepository,
        router: Router
    ) {
        let conID = data.pagination.conID
        self.contactsRepository = contactsRepository
        self.currentUserRepository = currentUserRepository
        self.router = router
        datasource = .init(pageSize: data.pagination.pageSize)
        scrollController = .init()
        presentation = .init(conID)
        dataObserver = .init(conID)
        attachmentFetcher = .init()
        state = State(conversation: data.conversation, theme: .init(data.properties.theme), properties: data.properties)
        models = .init(data.msgs, pagination: data.pagination)
    }

    deinit {
        serialQueue.cancelAllPendingTasks()
        log("Deinit")
    }

    @ObservationIgnored let datasource: PaginatedDatasource
    @ObservationIgnored let scrollController: ScrollCoordinator
    @ObservationIgnored var presentation: Presenter
    @ObservationIgnored let attachmentFetcher: AttachmentFetcher
    @ObservationIgnored let models: Messages
    @ObservationIgnored private let dataObserver: ChatDataReceiver
    @ObservationIgnored weak var contactsRepository: ContactsRepositoryProtocol?
    @ObservationIgnored weak var currentUserRepository: CurrentUserRepository?
    @ObservationIgnored weak var router: Router?
    @ObservationIgnored let conversationDataUpdater: ConversationDataUpdater = .init()
    @ObservationIgnored let serialQueue: AsyncQueue = .init(attributes: [])
    @ObservationIgnored let layoutManager: MsgsScrollViewLayoutManager = .init(cache: .init())
    var state: State
}

extension ChatManager {
    func send(_ intent: Intent) {
        guard scrollController.delegate != nil else { return }
        switch intent {
        case let .scrollViewIntent(newValue): scrollController.send(newValue)
        case .scrollDownButtonTapped:
            serialQueue.addOperation { [weak self] in
                guard let self else { return }
                try await handleScrollDownButtonTap()
            }
        case let .cellAction(newValue): handleMsgCellInteraction(action: newValue)
        }
    }

    func layoutIfNeeded() { state.reloadID += 1 }
}

extension ChatManager {
    private func handleScrollDownButtonTap() async throws {
        guard let lastMsg = try await MsgRepo.lastMsg(conID: state.conversation.uid) else { return }
        if models.shouldPaginate(at: .bottom) {
            scrollController.send(.begin(.focus(msg: lastMsg)))
        } else {
            scrollController.performScroll(to: .edge(.bottom, .animated()))
        }
    }

    func onViewAppear() {
        let hasViewLoaded = dataObserver.delegate !== nil && scrollController.delegate !== nil
        if !hasViewLoaded {
            layoutIfNeeded()
            dataObserver.delegate = self
            scrollController.delegate = self
        }
        serialQueue.addOperation { [weak self] in
            guard let self else { return }
            try await reloadConversation(refetch: !hasViewLoaded)
        }
        if !hasViewLoaded {
            serialQueue.addOperation { [weak self] in
                guard let self else { return }
                try await setIncomingMsgsAsRead(before: .now)
            }
        }
    }

    func onViewDisappear() {}
}
