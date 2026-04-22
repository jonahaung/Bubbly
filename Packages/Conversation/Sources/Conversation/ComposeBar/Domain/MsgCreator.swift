// © 2026 Aung Ko Min

import Database
import Foundation
import MediaPicker
import Services
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

    public init(mediaManager: MediaManager = .shared) {
        self.mediaManager = mediaManager
       
    }

    public func message(
        text: String,
        attachments: [Attachment],
        in conversation: Conversation,
    ) async throws -> Message {
        let currentUserId = try CurrentUserID.get()
        return await Message(
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
