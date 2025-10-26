//
//  AI.swift
//  Database
//
//  Created by Aung Ko Min on 25/10/25.
//

import Foundation

public struct AI: ConversationRepresentable {
	public func reload() async throws {
		
	}

	public func updateChanges() async throws {

	}
	public var uid = "AI"
	public var kind: ConversationKind { .system(self) }
	public var name: String = "Virtual Chatbot"
	public var photoURL: String = "https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.grammarly.com%2Fai&psig=AOvVaw3zmGr9LfTkmJwkYxmAihTg&ust=1761412804770000&source=images&cd=vfe&opi=89978449&ved=0CBUQjRxqFwoTCKDlmJ-svZADFQAAAAAdAAAAABAE"
	public var members: [String] = []
	public var theme: ConversationTheme = .init(bubbleColor: .whatsApp, background: .system)
	public var seenMembers: [SeenMember] = []
	public var lastMsgID: String?
	public static let system = AI()
}
