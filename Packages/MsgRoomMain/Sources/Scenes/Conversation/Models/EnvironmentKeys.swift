//
//  EnvironmentKeys.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 12/9/25.
//

import SwiftUI
import Database
import Services
import XUI

//private struct ConversationSnapshotKey: EnvironmentKey {
//	static let defaultValue: (any ConversationRepresentable)? = nil
//}
//extension EnvironmentValues {
//	var conversation: (any ConversationRepresentable)? {
//		get { self[ConversationSnapshotKey.self] }
//		set { self[ConversationSnapshotKey.self] = newValue }
//	}
//}
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
	var attachmentFetcher: AsyncFetcher<AttachmentData>? {
		get { self[AttachmentFetcherKey.self] }
		set { self[AttachmentFetcherKey.self] = newValue }
	}
}
