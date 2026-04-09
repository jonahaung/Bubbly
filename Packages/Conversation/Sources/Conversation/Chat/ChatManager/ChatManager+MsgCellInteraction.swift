// © 2026 Aung Ko Min

import Database
import Services

extension ChatManager {
    func handleMsgCellInteraction(action: MsgCellAction.ActionType) {
        switch action {
        case let .onTapMsg(string):
            setSelectedMsg(string)
        case .onMarkMsg:
            break
        case let .onTapAvatar(string):
            guard let vieModel = models.element(withID: string) else {
                return
            }

            let msg = vieModel.msg
            let senderID = msg.senderID
            if let contact = contactsRepository?.contact(for: senderID) {
                router?.pushToNav(.contactDetails(contact))
            }
        case let .onFocusMsgBubble(frame):
            presentation.send(.overlayItem(frame))
            layoutIfNeeded()
        case .onUploadedAttachments:
            break
        case let .onReact(message, reactionType):
            let conversation = state.conversation
            serialQueue.addOperation { [weak self] in
                guard let self else {
                    return
                }

                guard let currentUserID = await currentUserRepository?.model.uid else {
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
