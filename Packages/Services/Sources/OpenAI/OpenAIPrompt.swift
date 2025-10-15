//
//  Prompt.swift
//  InterviewHacker
//
//  Created by Aung Ko Min on 27/2/25.
//

// MARK: - Message
public struct OpenAIMessage: Decodable, Sendable {
	public let role: String
	public let content: String
}

// MARK: - Prompt
public enum OpenAIPrompt {

	case ask(input: String)
	case correct(input: String)
	case shorten(input: String)
	case emphasize(input: String)
	case intervieQuestion(input: String)

	public var request: OpenAIRequest {
		switch self {
		case let .correct(input):
			return ChatRequest(
				content: """
				Fix the spelling and grammar mistakes in the following text
				and make this text polite and correct: \(input)
				""",
				temperature: 1
			)
		case let .shorten(input):
			return ChatRequest(
				content: "Make a shorter version of this text:\n \(input)",
				temperature: 0.5
			)
		case let .emphasize(input):
			return ChatRequest(
				content: "Make this text catchy, more fun:\n \(input)",
				temperature: 1
			)
		case .ask(input: let input):
			return ChatRequest(
				content: input,
				temperature: 0.2
			)
		case .intervieQuestion(input: let input):
			return ChatRequest(
                content: """
                Interview Question: Please answer this question in short points.
                My spelling might be wrong, and please read it from a Swift
                Programming language perspective:\n \(input)
                """,
                temperature: 1
            )
		}
	}
}
extension OpenAIPrompt: Sendable {}

// MARK: - Response
public struct OpenAIResponse: Decodable {
	public struct Choice: Decodable {
		public let message: OpenAIMessage?
	}

	public let choices: [Choice]

	public var trimmedText: String {
		guard var text = choices.first?.message?.content else {
			return ""
		}
		while text.first?.isNewline == true || text.first?.isWhitespace == true {
			text.removeFirst()
		}
		return text
	}
}
extension OpenAIResponse: Sendable {}
extension OpenAIResponse.Choice: Sendable {}
