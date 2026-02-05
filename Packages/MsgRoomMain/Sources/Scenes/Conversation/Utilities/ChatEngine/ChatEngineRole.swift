//
//  ChatEngineRole.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/1/26.
//

import FoundationModels
import SwiftData
import Database

@Generable
public enum ChatEngineRole: String, Codable, Hashable, CaseIterable {
	case user = "User"
	case assistant = "Assistant"
	case sender = "Sender"
}
extension MsgRecipient {
	var role: ChatEngineRole {
		switch self {
		case .send:
			return .sender
		case .receive:
			return .user
		case .assistant:
			return .assistant
		}
	}
}
