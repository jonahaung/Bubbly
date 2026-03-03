//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Foundation
import MediaPicker
import UIKit
import XUI

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
        in conversation: Conversation
    ) async throws -> Message {
        await Message(
            uid: IDGenerator.shared.make(),
            senderID: currentUserId,
            conID: conversation.uid,
            text: text,
            date: .now,
            incomingStatus: .none,
            outgoingStatus: makeOutgoingStatus(for: conversation),
            attachments: attachments,
            reactions: []
        )
    }
}

private extension MsgCreator {
    func makeOutgoingStatus(for conversation: Conversation) -> [String: MsgOutgoingStatus] {
        var dict = [String: MsgOutgoingStatus]()
        dict.reserveCapacity(conversation.members.count)
        for member in conversation.members where member != currentUserId {
            dict[member] = .sending
        }
        return dict
    }
}
