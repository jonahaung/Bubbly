// © 2026 Aung Ko Min

import Database
import Services
import SwiftUI

extension ChatManager {
    func handleMsgCellInteraction(action: MsgCellAction.ActionType) {
        switch action {
        case .onTapMsg(let string):
            setSelectedMsg(string)
        case .onMarkMsg:
            break
        case .onTapAvatar(let string):
            guard let vieModel = models.element(withID: string) else {
                return
            }
            if let contact = vieModel.state.sender {
                router?.pushToNav(.contactDetails(contact))
            }
        case .onFocusMsgBubble(let frame):
            presentation.send(.overlayItem(frame))
            layoutIfNeeded()
        case .onUploadedAttachments:
            break
        case .onReact(let message, let reactionType):
            let conversation = state.conversation
            serialQueue.addOperation { [weak self] in
                guard let self else {
                    return
                }

                guard let currentUserID = await currentUserRepository?.model.uid
                else {
                    return
                }

                try? await Socket
                    .send(
                        .reaction(
                            reaction: .init(
                                reaction: .init(
                                    rawValue: reactionType.rawValue,
                                    senderID: currentUserID,
                                    date: .now,
                                ),
                                msgID: message.uid,
                                conID: conversation.uid,
                            ),
                        ),
                        conversation: conversation,
                    )
            }
        }
    }
}

extension ChatManager {
    fileprivate func setSelectedMsg(_ uid: String) {
        guard let index = models.index(of: uid) else {
            return
        }

        let oldValue = layoutManager.selectedMsg
        let nextMsg = models[index + 1]?.msg
        let previousMsg = models[index - 1]?.msg
        let newValue: SelectedMsg? =
            oldValue?.id == uid
            ? nil
            : SelectedMsg(
                id: uid,
                previous: previousMsg?.uid,
                next: nextMsg?.uid,
            )
        let transaction = Transaction.withAnimation(.interactiveSpring)
        withTransaction(transaction) {
            
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
        }
    }
}
