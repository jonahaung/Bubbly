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

    @ObservationIgnored
    let datasource: PaginatedDatasource
    @ObservationIgnored
    let scrollController: ScrollCoordinator
    @ObservationIgnored
    var presentation: Presenter
    @ObservationIgnored
    let attachmentFetcher: AttachmentFetcher
    @ObservationIgnored
    let messages: Messages
    @ObservationIgnored
    private let dataObserver: ChatDataReceiver
    @ObservationIgnored
    let conversationDataUpdater: ConversationDataUpdater = .init()
    @ObservationIgnored
    let serialQueue: AsyncQueue = .init(attributes: [])
    @ObservationIgnored
    weak var currentUserRepository: CurrentUserRepository?
    @ObservationIgnored
    weak var router: Router?
    @ObservationIgnored
    var members: Members
    
    var state: State
    var reloadID = true

    init(
        _ data: ConversationInitializer.PrefetchedData,
        currentUserRepository: CurrentUserRepository,
        router: Router
    ) {
        self.currentUserRepository = currentUserRepository
        self.router = router
        datasource = .init(pageSize: data.pagination.pageSize)
        scrollController = .init(data.properties.lastPage)
        let conID = data.pagination.conID
        presentation = .init(conID)
        dataObserver = .init(conID)
        attachmentFetcher = .init()
        state = State(conversation: data.conversation, theme: .init(data.properties.theme), properties: data.properties)
        messages = .init(data.msgs, pagination: data.pagination)
        members = data.members
    }

    deinit {
        serialQueue.cancelAllPendingTasks()
        log("Deinit")
    }

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
        case let .cellAction(newValue):
            handleMsgCellInteraction(action: newValue)
        }
    }

    func layoutIfNeeded() {
        reloadID.toggle()
    }
}

extension ChatManager {

    private func handleScrollDownButtonTap() async throws {
        guard let lastMsg = try await MsgRepo.lastMsg(conID: state.conversation.uid) else { return }
        if messages.shouldPaginate(at: .bottom) {
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
        
        if !hasViewLoaded {
            serialQueue.addOperation { [weak self] in
                guard let self else { return }
                try await setIncomingMsgsAsRead(before: .now)
            }
        }
        serialQueue.addOperation { [weak self] in
            guard let self else { return }
            try await reloadConversation(refetch: !hasViewLoaded)
            if !hasViewLoaded {
                try await Store.shared.conversationPropertiesStore?.updateAndSave(uid: messages.pagination.conID) { model in
                    model.lastPage = nil
                }
            }
        }
    }

    func pop() async throws {
        serialQueue.cancelAllPendingTasks()
        guard scrollController.geometry != .empty, scrollController.geometry.scrolledPosition != .atBottom else {
            router?.pop()
            return
        }
        let lastPage = LastPage(topMsgID: messages.first?.id, bottomMsgID: messages.last?.id, scrollOffsetY: scrollController.geometry.offsetY, isPotrait: UIApplication.shared.screenSize().isPortrait)
        try await Store.shared.conversationPropertiesStore?.updateAndSave(uid: state.properties.uid) { model in
            model.lastPage = lastPage
        }
        router?.pop()
    }
}
