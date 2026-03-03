//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import FoundationModels

/// Custom error types for Foundation Models operations
public nonisolated enum FoundationModelsError: LocalizedError, Sendable {
    case sessionCreationFailed
    case responseGenerationFailed(String)
    case toolCallFailed(String)
    case streamingFailed(String)
    case modelUnavailable(String)

    public var errorDescription: String? {
        switch self {
        case .sessionCreationFailed:
            "Failed to create language model session"
        case let .responseGenerationFailed(message):
            "Response generation failed: \(message)"
        case let .toolCallFailed(message):
            "Tool call failed: \(message)"
        case let .streamingFailed(message):
            "Streaming failed: \(message)"
        case let .modelUnavailable(message):
            "Model unavailable: \(message)"
        }
    }
}

/// Helper for handling LanguageModelSession errors
public struct FoundationModelsErrorHandler: Sendable {
    public static func handleGenerationError(_ error: LanguageModelSession
        .GenerationError) -> String {
        switch error {
        case let .exceededContextWindowSize(context):
            return "Context window exceeded: \(context.debugDescription)"
        case let .assetsUnavailable(context):
            return "Model assets unavailable: \(context.debugDescription)"
        case let .guardrailViolation(context):
            return "Content policy violation: \(context.debugDescription)"
        case let .decodingFailure(context):
            return "Failed to decode response: \(context.debugDescription)"
        case let .unsupportedGuide(context):
            return "Unsupported generation guide: \(context.debugDescription)"
        case let .unsupportedLanguageOrLocale(context):
            return "Unsupported language/locale: \(context.debugDescription)"
        case let .rateLimited(context):
            return "Rate limited: \(context.debugDescription)"
        case let .concurrentRequests(context):
            return "Too many concurrent requests: \(context.debugDescription)"
        // Refusal is async throws
        case let .refusal(_, context):
            return "Model refused to respond: \(context.debugDescription)"
        @unknown default:
            return "Unknown generation error"
        }
    }

    public static func handleToolCallError(_ error: LanguageModelSession.ToolCallError) -> String {
        "Tool '\(error.tool.name)' failed: \(error.underlyingError.localizedDescription)"
    }

    /// Consolidates error handling for LanguageModelSession operations
    public static func handleError(_ error: Error) -> String {
        if let generationError = error as? LanguageModelSession.GenerationError {
            handleGenerationError(generationError)
        } else if let toolCallError = error as? LanguageModelSession.ToolCallError {
            handleToolCallError(toolCallError)
        } else if let customError = error as? FoundationModelsError {
            customError.localizedDescription
        } else {
            String(localized: "Unexpected error: \(error.localizedDescription)")
        }
    }
}
