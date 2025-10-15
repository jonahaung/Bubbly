//
//  EnvironmentKeys.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 12/9/25.
//

import SwiftUI
import Database

private struct ConversationSnapshotKey: EnvironmentKey {
	static let defaultValue: ConversationSnapshot = .init(uid: "", name: "", type: .group, createdDate: .now, photoURL: nil, members: .init())
}
extension EnvironmentValues {
	var conversation: ConversationSnapshot {
		get { self[ConversationSnapshotKey.self] }
		set { self[ConversationSnapshotKey.self] = newValue }
	}
}
private struct ChatViewManagerKey: EnvironmentKey {
	static let defaultValue: ChatViewEventsManager? = nil
}
extension EnvironmentValues {
	var eventsManager: ChatViewEventsManager? {
		get { self[ChatViewEventsManager.self] }
		set { self[ChatViewEventsManager.self] = newValue }
	}
}
