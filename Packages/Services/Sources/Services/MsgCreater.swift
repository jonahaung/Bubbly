// © 2026 Aung Ko Min

import Database
import Foundation
import MediaPicker
import UIKit
import XUI
import Core

public actor MsgCreator {
    public enum Error: Swift.Error {
        case noCurrentUserId
        case imageProcessingFailed(Swift.Error? = nil)
        case dataConversionFailed
    }

    private let mediaManager: MediaManager
    private let currentUserId: String

    public init(currentUserId: String, mediaManager: MediaManager = .shared) {
        self.mediaManager = mediaManager
        self.currentUserId = currentUserId
    }

    public func message(
        text: String,
        attachments: [Attachment],
        in conversation: Conversation,
    ) async throws -> Message {
        let msgID = await IDGenerator.shared.make()
        let currentUserID = try CurrentUserID.get()
        let outgoingStatus = MsgDeliveryState(
            msgID: msgID,
            senderID: currentUserID,
            aggregateStatus: .sending,
            recipientIDs: conversation.members.filter { $0 != currentUserId },
            updatedAt: .now
        )
        return await Message(
            uid: msgID,
            senderID: currentUserId,
            conID: conversation.uid,
            text: text,
            serverTime: .now,
            incomingStatus: .sending,
            outgoingStatus: outgoingStatus,
            attachments: attachments,
            reactions: [],
        )
    }
}
