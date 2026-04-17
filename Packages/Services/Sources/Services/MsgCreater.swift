// © 2026 Aung Ko Min

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
        in conversation: Conversation,
    ) async -> Message {
        await Message(
            uid: IDGenerator.shared.make(),
            senderID: currentUserId,
            conID: conversation.uid,
            text: text,
            date: .now,
            deliveryStatus: .sending,
            attachments: attachments,
            reactions: [],
        )
    }
}
