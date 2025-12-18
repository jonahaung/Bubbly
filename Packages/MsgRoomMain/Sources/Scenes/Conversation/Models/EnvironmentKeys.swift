//
//  EnvironmentKeys.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 12/9/25.
//

import Database
import Services
import SwiftUI
import XUI

private struct ConversationThemeKey: EnvironmentKey {
	static let defaultValue: ConversationTheme = .empty
}

extension EnvironmentValues {
	var conversationTheme: ConversationTheme {
		get { self[ConversationThemeKey.self] }
		set { self[ConversationThemeKey.self] = newValue }
	}
}

private struct AttachmentFetcherKey: EnvironmentKey {
	static let defaultValue: AsyncFetcher<AttachmentData>? = nil
}

extension EnvironmentValues {
	var asyncFetcher: AsyncFetcher<AttachmentData>? {
		get { self[AttachmentFetcherKey.self] }
		set { self[AttachmentFetcherKey.self] = newValue }
	}
}
private struct ConversationKey: EnvironmentKey {
	static let defaultValue: Conversation = .empty
}

extension EnvironmentValues {
	var conversation: Conversation {
		get { self[ConversationKey.self] }
		set { self[ConversationKey.self] = newValue }
	}
}
