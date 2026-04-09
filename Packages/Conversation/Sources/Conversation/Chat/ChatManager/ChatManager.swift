// © 2026 Aung Ko Min

import Combine
import Core
import Database
import ImageLoader
import Services
import SwiftUI
import XUI

// MARK: - ChatManager

@MainActor
@Observable
final class ChatManager: ErrorPresenter {
    // MARK: Lifecycle

    init(
        _ data: ConversationInitializer.PrefetchedData,
        contactsRepository: ContactsRepositoryProtocol,
        currentUserRepository: CurrentUserRepository,
        router: Router,
    ) {
        self.contactsRepository = contactsRepository
        self.currentUserRepository = currentUserRepository
        self.router = router
        conversationConfig = data.configuration
        datasource = .init(pageSize: data.configuration.pageSize)
        models = .init(
            data.msgs,
            data.configuration.canPaginate ? [] : [.init(kind: .conversation(data.conversation))],
        )
        scrollController = .init()
        presentation = .init(data.configuration)
        dataObserver = .init(conID: data.configuration.conID)
        attachmentFetcher = .init()
        state = .init(
            reloadID: 0,
            conversation: data.conversation,
            theme: .init(data.properties.theme),
            properties: data.properties,
        )
        dataObserver.delegate = self
        scrollController.delegate = self
    }

    deinit {
        serialQueue.cancel()
        log("Deinit")
    }

    // MARK: Internal

    struct State: Equatable {
        var reloadID: Int
        var conversation: Conversation
        var theme: ChatTheme
        var properties: ConversationProperties
    }

    @ObservationIgnored let datasource: PaginatedDatasource
    @ObservationIgnored let scrollController: ScrollCoordinator
    @ObservationIgnored var presentation: Presenter
    @ObservationIgnored let conversationConfig: ConversationInitializer.Configuration
    @ObservationIgnored let attachmentFetcher: AttachmentFetcher
    @ObservationIgnored let models: MsgModels
    @ObservationIgnored let layout: ChatViewLayout = .init()
    @ObservationIgnored let dataObserver: ChatDataReceiver
    @ObservationIgnored weak var contactsRepository: ContactsRepositoryProtocol?
    @ObservationIgnored weak var currentUserRepository: CurrentUserRepository?
    @ObservationIgnored weak var router: Router?
    @ObservationIgnored let conversationDataUpdater: ConversationDataUpdater = .init()
    @ObservationIgnored let serialQueue: AsyncQueue = .init([.concurrent])

    var state: State
}

extension ChatManager {
    func layoutIfNeeded() {
        state.reloadID += 1
    }

    func onBottomBarFrameChage(_ oldValue: CGRect, _ newValue: CGRect) {
        layoutIfNeeded()
        if layout.bottomBarFrame == nil, newValue.origin.x >= 0 {
            layout.update(bottomBarFrame: newValue)
        } else {
            scrollController.send(.onBottomBarFrameChage(oldValue, newValue))
        }
    }

    func send(_ intent: ScrollCoordinator.Intent) {
        scrollController.send(intent)
    }

    func handleScrollDownButtonTap() {
        guard scrollController.updatedState(is: .didEndUpdates) else {
            return
        }

        if scrollCoordinator(scrollController, shouldPaginateAt: .bottom) {
            scrollTo(msgID: nil)
        } else {
            serialQueue.addOperation(barrier: true) { [weak self] in
                guard let self else {
                    return
                }

                scrollController.performScroll(to: .edge(
                    .bottom,
                    properties: .animated(.interpolatingSpring(duration: 0.5)),
                ))
            }
        }
    }

    func setSelectedMsg(_ uid: String) {
        guard let index = models.index(of: uid) else {
            return
        }

        let oldValue = layout.selectedMsg
        let nextMsg = models[safe: index + 1]?.msg
        let previousMsg = models[safe: index - 1]?.msg
        let newValue: SelectedMsg? =
            oldValue?.id == uid
                ? nil
                : SelectedMsg(
                    id: uid,
                    previous: previousMsg?.uid,
                    next: nextMsg?.uid,
                )
        withAnimation(.easeOutExponential) {
            if let oldValue {
                models.didChangeSelection(newValue, for: oldValue.id)
            }
            if let newValue {
                models.didChangeSelection(newValue, for: newValue.id)
            }
        } completion: { [self] in
            layout.selectedMsg = newValue
            if let oldValue {
                if let id = oldValue.next {
                    models.didChangeSelection(newValue, for: id)
                }
                if let id = oldValue.previous {
                    models.didChangeSelection(newValue, for: id)
                }
            }
            if let newValue {
                if let id = newValue.next {
                    models.didChangeSelection(newValue, for: id)
                }
                if let id = newValue.previous {
                    models.didChangeSelection(newValue, for: id)
                }
            }
        }
    }

    func onViewAppear() {
        serialQueue.addOperation { [weak self] in
            guard let self else {
                return
            }

            try await reloadConversation(refetch: true)
        }
        serialQueue.addOperation { [weak self] in
            guard let self else {
                return
            }

            try await setIncomingMsgsAsRead()
        }
    }

    func onViewDisappear() {
        serialQueue.cancel()
    }
}
