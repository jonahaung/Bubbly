//
//  ChatEngineMsgGenerable.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/1/26.
//

import FoundationModels

@Generable
struct ChatEngineMsgGenerable {
	@Guide(description: "The role of the user who sent the message")
	let role: ChatEngineRole
	@Guide(description: "The content of the message")
	let content: String
}
@Generable
struct TopicGenerable {
	@Guide(description: "The topic of the messages")
	let topic: String
	@Guide(description: "The description of the topic")
	let description: String
}
