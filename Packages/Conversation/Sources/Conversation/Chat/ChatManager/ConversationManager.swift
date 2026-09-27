//
//  ConversationManager.swift
//  Conversation
//
//  Created by Aung Ko Min on 26/9/26.
//

import FoundationModels
import os
import Synchronization
import Database
import Foundation
import Shared
final class ConversationManager: Sendable {

    struct MessageSnapshot: Sendable {
        let authorName: String
        let body: String
    }

    struct RecipientSnapshot: Sendable {
        let id: Contact.ID
        let name: String
        let personality: String
        let interests: String
    }

    struct GeneratedResponse: Sendable {
        let recipientID: Contact.ID
        let text: String
    }

    private enum Error: LocalizedError {
        case modelUnavailable

        var errorDescription: String? {
            switch self {
            case .modelUnavailable:
                return "The Foundation Models framework is not available on this device"
            }
        }
    }

    private let model = SystemLanguageModel.default

    private let sessions = Mutex<[Contact.ID: LanguageModelSession]>([:])

    var isAvailable: Bool {
        switch model.availability {
        case .available: true
        case .unavailable: false
        }
    }

    init() {}

    func responses(
        for messageBody: String,
        recipients: [RecipientSnapshot],
        history: [MessageSnapshot]
    ) -> AsyncStream<GeneratedResponse> {
        let (stream, continuation) = AsyncStream.makeStream(of: GeneratedResponse.self)

        guard isAvailable else {
            continuation.finish()
            return stream
        }

        let task = Task(name: "Generate automatic responses") {
            defer { continuation.finish() }

            await withDiscardingTaskGroup { group in
                for recipient in recipients {
                    group.addTask(name: "Response from \(recipient.name)") {
                        let text: String
                        do {
                            text = try await self.generateResponse(
                                for: messageBody,
                                recipient: recipient,
                                history: history
                            )
                        } catch is CancellationError {
                            return
                        } catch {
                            text = error.localizedDescription
                        }
                        continuation.yield(GeneratedResponse(recipientID: recipient.id, text: text))
                    }
                }
            }
        }

        continuation.onTermination = { _ in task.cancel() }

        return stream
    }

    private func generateResponse(
        for messageBody: String,
        recipient: RecipientSnapshot,
        history: [MessageSnapshot]
    ) async throws -> String {
        let session = self.session(for: recipient)
        let prompt = buildPrompt(
            messageText: messageBody,
            contactName: recipient.name,
            conversationHistory: history
        )

        if #available(iOS 27.0, *) {
            do {
                let response = try await session.respond(to: prompt)
                return response.content
            } catch LanguageModelError.contextSizeExceeded {
                sessions.withLock { _ = $0.removeValue(forKey: recipient.id) }
                try Task.checkCancellation()
                return try await generateResponse(
                    for: messageBody,
                    recipient: recipient,
                    history: history
                )
            }
        } else {
            do {
                let response = try await session.respond(to: prompt)
                return response.content
            } catch {
                sessions.withLock { _ = $0.removeValue(forKey: recipient.id) }
                try Task.checkCancellation()
                return try await generateResponse(
                    for: messageBody,
                    recipient: recipient,
                    history: history
                )
            }
        }
    }

    private func session(for recipient: RecipientSnapshot) -> LanguageModelSession {
        sessions.withLock { sessions in
            if let existing = sessions[recipient.id] {
                return existing
            }
            let session = LanguageModelSession(instructions: instructions(for: recipient))
            sessions[recipient.id] = session
            return session
        }
    }

    private func instructions(for recipient: RecipientSnapshot) -> String {
        """
        You are \(recipient.name), a friendly and helpful chatbot having a conversation via text message.
        Your personality: \(recipient.personality)
        Your interests: \(recipient.interests)

        Guidelines:
        - Respond naturally and conversationally, as \(recipient.name) would
        - Keep responses concise and appropriate for text messaging (1-3 sentences usually)
        - Let your personality and interests influence how you respond
        - Be friendly and supportive
        - Stay in character as \(recipient.name)
        - Use casual, conversational language appropriate for texting
        - Don't sign-offs unless contextually appropriate
        - If asked about something you (as \(recipient.name)) wouldn't know, respond honestly that you don't know
        - Use markdown style text  if necessary
        """
    }

    private func buildPrompt(
        messageText: String,
        contactName: String,
        conversationHistory: [MessageSnapshot]
    ) -> String {
        var prompt = ""

        if !conversationHistory.isEmpty {
            prompt += "Recent conversation:\n"
            let recentMessages = conversationHistory.suffix(5)
            for message in recentMessages {
                prompt += "\(message.authorName): \(message.body)\n"
            }
            prompt += "\n"
        }

        prompt += "Respond to this message: \"\(messageText)\""

        return prompt
    }
}
