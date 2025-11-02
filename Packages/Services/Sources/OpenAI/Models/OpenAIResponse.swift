//
//  OpenAIResponse.swift
//  Services
//
//  Created by Aung Ko Min on 31/10/25.
//

import Foundation

public struct OpenAIResponse: Codable, Sendable {
	public let id: String
	public let object: String
	public let model: String
	public let created: Int
	public let choices: [ChatChoice]
	public let usage: ChatUsage
}
public extension OpenAIResponse {
	struct ChatUsage: Codable, Sendable {
		public let promptTokens: Int
		public let completionTokens: Int
		public let totalTokens: Int

		enum CodingKeys: String, CodingKey {
			case promptTokens = "prompt_tokens"
			case completionTokens = "completion_tokens"
			case totalTokens = "total_tokens"
		}
	}
	struct ChatChoice: Codable, Sendable {
		public let index: Int
		public let finishReason: String
		public let message: ChatMessage

		enum CodingKeys: String, CodingKey {
			case index
			case finishReason = "finish_reason"
			case message
		}
	}
	struct ChatMessage: Codable, Sendable {
		public let role: String
		public let content: String
	}
}
