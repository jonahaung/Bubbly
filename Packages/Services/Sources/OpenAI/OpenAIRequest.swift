//
//  OpenAIRequest.swift
//  InterviewHacker
//
//  Created by Aung Ko Min on 27/2/25.
//
import Foundation

// MARK: - OpenAIRequest Protocol
public protocol OpenAIRequest: Encodable {
    var model: String { get }
}

// MARK: - ChatRequest
public struct ChatRequest: OpenAIRequest {
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
extension ChatRequest: Sendable {}
extension ChatRequest.Message: Sendable {}

// MARK: - Vision Types
public struct VisionImageUrl: Encodable, Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }
}

public struct VisionMessageContent: Encodable, Sendable {
    public let type: String
    public let text: String?
    public let imageUrl: VisionImageUrl?

    public init(type: String, text: String? = nil, imageUrl: VisionImageUrl? = nil) {
        self.type = type
        self.text = text
        self.imageUrl = imageUrl
    }
}

// MARK: - VisionRequest
public struct VisionRequest: OpenAIRequest {
    public struct Message: Encodable {
        public let role = "user"
        public let content: [VisionMessageContent]

        public init(content: [VisionMessageContent]) {
            self.content = content
        }
    }

    public let model = "gpt-4o"
    public let messages: [Message]
    public let maxTokens = 50

    public init(messages: [Message]) {
        self.messages = messages
    }
}
extension VisionRequest: Sendable {}
extension VisionRequest.Message: Sendable {}
