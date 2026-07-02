//  MsgCreator.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import UIKit
import Database
import Services
import Foundation
import MediaPicker

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
        text: String?,
        attachments: [Attachment],
        in conversation: Conversation
    ) async throws -> Message {
        let currentUserId = try CurrentUserID.get()
        return await Message(
            uid: IDGenerator.shared.make(),
            senderID: currentUserId,
            conID: conversation.uid,
            text: text,
            serverTime: .now,
            incomingStatus: .sending,
            outgoingStatus: .empty,
            attachments: attachments,
            reactions: []
        )
    }
}
