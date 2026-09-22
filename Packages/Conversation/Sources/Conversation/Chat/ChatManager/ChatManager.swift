//  ChatManager.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Combine
import Core
import Database
import ImageLoader
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class ChatManager: ErrorPresenter {

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
    weak var currentUserRepository: CurrentUserRepository?

    @ObservationIgnored
    weak var router: Router?

    @ObservationIgnored
    var members: Members

    @ObservationIgnored
    var focusState: SharedFocusState<ConversationFocusState>?

    var state: State

    var reloadID = true

    init(_ data: ConversationInitializedData, currentUserRepository: CurrentUserRepository, router: Router) {
        self.currentUserRepository = currentUserRepository
        self.router = router

        datasource = PaginatedDatasource(pageSize: data.pagination.pageSize)
        scrollController = ScrollCoordinator(lastPage: data.properties.lastPage)

        let conversationID = data.pagination.conID
        presentation = Presenter(conversationID)
        dataObserver = ChatDataReceiver(conversationID)
        attachmentFetcher = AttachmentFetcher()

        state = State(
            conversation: data.conversation,
            theme: .init(data.properties.theme),
            properties: data.properties
        )
        messages = Messages(data.msgs, pagination: data.pagination)
        members = data.members
    }

    deinit {
        log("Deinit")
    }
}

// MARK: - Intent Handling

extension ChatManager {

    func send(_ intent: Intent) {
        guard scrollController.delegate != nil else { return }

        switch intent {
        case .scrollViewIntent(let newValue):
            scrollController.send(newValue)

        case .scrollDownButtonTapped:
            Task {
                try? await handleScrollDownButtonTap()
            }

        case .cellAction(let newValue):
            handleMsgCellInteraction(action: newValue)
        }
    }

    func layoutIfNeeded() {
        reloadID.toggle()
    }
}

// MARK: - Lifecycle

extension ChatManager {

    func onViewAppear() async {
        let hasViewLoaded = dataObserver.delegate !== nil && scrollController.delegate !== nil

        if !hasViewLoaded {
            layoutIfNeeded()
            dataObserver.delegate = self
            scrollController.delegate = self
            try? await setIncomingMsgsAsRead(before: .now)
        }

        try? await reloadConversation(refetch: !hasViewLoaded)

        if !hasViewLoaded {
            try? await Store.shared.conversationPropertiesStore?.updateAndSave(uid: messages.pagination.conID) {
                model in
                model.lastPage = nil
            }
        }
    }

    func prepareToExit() async throws {
        guard shouldSaveLastPage else {
            router?.pop()
            return
        }

        let lastPage = makeLastPage()
        try await Store.shared.conversationPropertiesStore?.updateAndSave(uid: state.properties.uid) { model in
            model.lastPage = lastPage
        }
        router?.pop()
    }

    private var shouldSaveLastPage: Bool {
        guard scrollController.geometry != .empty else { return false }
        return scrollController.geometry.scrolledPosition != .atBottom
    }

    private func makeLastPage() -> LastPage? {
        LastPage(
            topMsgID: messages.first?.id,
            bottomMsgID: messages.last?.id,
            scrollOffsetY: scrollController.geometry.offsetY,
            isPotrait: UIApplication.shared.screenSize().isPortrait
        )
    }
}

// MARK: - Scroll Down Button

extension ChatManager {

    private func handleScrollDownButtonTap() async throws {
        guard let lastMessage = try await MsgRepo.lastMsg(conID: state.conversation.uid) else { return }

        if messages.shouldPaginate(at: .bottom) {
            scrollController.send(.begin(.focus(msg: lastMessage)))
        } else {
            scrollController.performScroll(to: .edge(.bottom, .animated()))
        }
    }
}
