//  Environment+Conversation.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Services

public extension EnvironmentValues {
    @Entry var conversation: Conversation = .empty
    @Entry var isVisible = false
    @Entry var attachmentFetcher: AttachmentFetcher? = nil
    @Entry var conversationTheme: ChatTheme = .empty
}
