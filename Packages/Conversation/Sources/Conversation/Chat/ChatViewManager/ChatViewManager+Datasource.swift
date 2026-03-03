//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension ChatViewManager: ChatDatasourceDelegate {
    @concurrent func saveConversationChanges() async {
        do {
            await updateReceiveMsgs()
            try await conversation.saveChanges()
        } catch {
            await showError(error)
        }
    }

    func datasource(didRecieveError error: any Error) async {
        await showError(error)
    }

    func datasource(didReceive typingStatus: AnyMsgData.TypingStatusPayload) async {
        presentation.send(.typing(typingStatus))
    }

    func datasource(didInsert msg: Message) async {
        if let existingModel = models.element(withID: msg.uid) {
            existingModel.update(with: msg)
        } else {
            if scrollController.isNear(.bottom) {
                scrollController.updateStateUpdate(to: .appendingItem(msg.uid))
            } else {
                let toast = Toast(
                    node: Text(msg.displayText).opaqueView(),
                    allowsBackgroundTap: false
                ) {
                    if self.canResetDatasource {
                        self.resetDatasource()
                    } else {
                        self.scrollController
                            .send(
                                .scrollTo(
                                    .id(msg.uid, animation: .interpolatingSpring),
                                    enqueue: true
                                )
                            )
                    }
                }
                ToastPresenter.show(toast)
            }
            models.insert(msg: msg)
            layoutIfNeeded()
        }
    }

    func datasource(didReceiveMsg _: Message) async {
        updateReceiveMsgs()
    }

    func datasource(didUpdate snapshot: Message, animated _: Bool) async {
        models.update(msg: snapshot)
    }

    func datasource(didRemove snapshot: Message, animated _: Bool) async {
        models.remove(msg: snapshot)
        layoutIfNeeded()
    }

    func datasource(didReceive status: AnyMsgData.SeenStatusPayload) async {
        var conversation = self.conversation
        conversation.properties.seenMembers.removeAll(where: { $0.uid == status.seenMember.uid })
        conversation.properties.seenMembers.append(status.seenMember)
        state.conversation = conversation
        await saveConversationChanges()
        layoutIfNeeded()
    }
}

extension ChatViewManager {
    func reloadData(with msgs: [Message], forceReset: Bool) async {
        await models.setInBackground(msgs: msgs, forceReset: forceReset)
        let showContactInfo: Bool = {
            guard let firstMsgID = conversationConfig.firstMsgID else { return true }
            return msgs.contains(where: { $0.id == firstMsgID })
        }()
        presentation.send(.showContactInfo(showContactInfo))
        layoutIfNeeded()
    }

    func reloadConversation() async throws {
        state.conversation = try await conversation.reload(refetch: false)
    }

    func updateReceiveMsgs() {
        guard
            let lastMsg = models.msgs().last(where: { $0.receiptType == .receive }),
            lastMsg.incomingStatus.rawValue < MsgIncomingStatus.read.rawValue,
            let currentUserId
        else {
            return
        }

        Task.detached { [self] in
            do {
                let msgs = try await ConversationRepo.updateReceiveMsgs(
                    for: lastMsg.conID,
                    currentUserID: currentUserId
                )
                try await Socket.send(
                    .seenStatus(
                        status: .init(
                            msgID: lastMsg.uid,
                            userID: currentUserId,
                            conID: lastMsg.conID
                        )
                    ),
                    conversation: conversation
                )
                await MainActor.run {
                    for msg in msgs {
                        if let model = self.models.element(withID: msg.uid) {
                            model.update(with: msg)
                        }
                    }
                }
            } catch {
                await showError(error)
            }
        }
    }
}
