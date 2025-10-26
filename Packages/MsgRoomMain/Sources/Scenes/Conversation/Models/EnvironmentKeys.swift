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

private struct ConversationSnapshotKey: EnvironmentKey {
	static let defaultValue: (any ConversationRepresentable)? = nil
}
extension EnvironmentValues {
	var conversation: (any ConversationRepresentable)? {
		get { self[ConversationSnapshotKey.self] }
		set { self[ConversationSnapshotKey.self] = newValue }
	}
}
private struct ChatViewEventsManagerKey: EnvironmentKey {
	static let defaultValue: ChatViewEventsManager? = nil
}
extension EnvironmentValues {
	var eventsManager: ChatViewEventsManager? {
		get { self[ChatViewEventsManager.self] }
		set { self[ChatViewEventsManager.self] = newValue }
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
private struct BubleKey: EnvironmentKey {
	static let defaultValue: Bubble = .init()
}
extension EnvironmentValues {
	var bubble: Bubble {
		get { self[BubleKey.self] }
		set { self[BubleKey.self] = newValue }
	}
}
