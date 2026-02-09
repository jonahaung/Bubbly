//
//  ChatEngineRole.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/1/26.
//

import Database
import FoundationModels
import SwiftData

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
			.sender
		case .receive:
			.user
		case .assistant:
			.assistant
		}
	}
}
