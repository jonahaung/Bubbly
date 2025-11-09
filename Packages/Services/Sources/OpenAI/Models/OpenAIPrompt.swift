//
//  OpenAIPrompt.swift
//  InterviewHacker
//
//  Created by Aung Ko Min on 27/2/25.
//

public enum OpenAIPrompt {
    case ask(input: String)
    case correct(input: String)
    case shorten(input: String)
    case emphasize(input: String)
    case interviewQuestion(input: String)

    public var request: OpenAIRequest {
        switch self {
        case let .correct(input):
            OpenAIRequest(
                content: """
                Fix the spelling and grammar mistakes in the following text
                and make this text polite and correct: \(input)
                """,
                temperature: 1
            )
        case let .shorten(input):
            OpenAIRequest(
                content: "Make a shorter version of this text:\n\(input)",
                temperature: 0.5
            )
        case let .emphasize(input):
            OpenAIRequest(
                content: "Make this text catchy and more fun:\n\(input)",
                temperature: 1
            )
        case let .ask(input):
            OpenAIRequest(
                content: "Give short and clear answers by default. Only write longer responses when more detail is needed. Question is:\n\(input)",
                temperature: 0.9
            )
        case let .interviewQuestion(input):
            OpenAIRequest(
                content: """
                Instruction for you:
                • Please answer this question in short, clear bullet points.
                • My spelling or phrasing might not be perfect — focus on understanding my intent.
                • Provide your explanation from a Swift and iOS development perspective.
                • When relevant, include concise code examples or key API references (e.g., Swift standard library, UIKit, SwiftUI, Combine, async/await).
                • Focus on clarity, correctness, and reasoning, not lengthy explanations. Make a short answer.
                Question:
                \(input)
                """,
                temperature: 0.9
            )
        }
    }
}

extension OpenAIPrompt: Sendable {}

// public struct OpenAIResponse: Decodable, Sendable {
//	public struct Choice: Decodable, Sendable {
//		public let message: OpenAIMessage?
//	}
//
//	public let choices: [Choice]
//
//	public var trimmedText: String {
//		guard var text = choices.first?.message?.content else {
//			return ""
//		}
//		while text.first?.isNewline == true || text.first?.isWhitespace == true {
//			text.removeFirst()
//		}
//		return text
//	}
// }
