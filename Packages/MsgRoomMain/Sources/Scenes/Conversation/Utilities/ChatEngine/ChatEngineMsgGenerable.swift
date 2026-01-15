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
