//
//  EnvironmentValues+Extensions.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 12/9/25.
//

import Database
import Services
import SwiftUI
import XUI

public extension EnvironmentValues {
	@Entry var conversationTheme = ConversationTheme.empty
	@Entry var attachmentFetcher = AttachmentFetcher.shared
	@Entry var conversation = Conversation.empty
	@Entry var viewIsVisible = false
}
