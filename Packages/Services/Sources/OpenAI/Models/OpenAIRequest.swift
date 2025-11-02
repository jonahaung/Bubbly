//
//  OpenAIRequest.swift
//  InterviewHacker
//
//  Created by Aung Ko Min on 27/2/25.
//

import Foundation

public struct OpenAIRequest: Encodable {
	public struct Message: Encodable {
		public let role = "user"
		public let content: String
	}

	public let model = "gpt-4o"
	public let messages: [Message]
	public let temperature: CGFloat

	public init(content: String, temperature: CGFloat) {
		self.messages = [.init(content: content)]
		self.temperature = temperature
	}
}
extension OpenAIRequest: Sendable {}
extension OpenAIRequest.Message: Sendable {}
