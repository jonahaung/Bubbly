//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import Crypto
import Database
import Firebase
import os
import Services
import UserNotifications
import XUI

final class NotificationService: UNNotificationServiceExtension {
    private final class RequestSession {
        let id: String
        let contentHandler: (UNNotificationContent) -> Void
        let originalContent: UNNotificationContent
        var bestAttemptContent: UNMutableNotificationContent?
        var processingTask: Task<Void, Never>?
        var isFinished = false

        init(
            id: String,
            contentHandler: @escaping (UNNotificationContent) -> Void,
            originalContent: UNNotificationContent,
            bestAttemptContent: UNMutableNotificationContent?
        ) {
            self.id = id
            self.contentHandler = contentHandler
            self.originalContent = originalContent
            self.bestAttemptContent = bestAttemptContent
        }
    }

    private enum NotificationServiceError: Error {
        case currentUserIDUnavailable
    }

    private let logger = Logger(
        subsystem: "com.bubbly.app",
        category: "NotificationServiceExtension"
    )
    private let sessionsLock = NSLock()
    private var sessions = [String: RequestSession]()

    override init() {
        super.init()
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        let requestID = request.identifier.isEmpty ? UUID().uuidString : request.identifier
        let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent
        let session = RequestSession(
            id: requestID,
            contentHandler: contentHandler,
            originalContent: request.content,
            bestAttemptContent: bestAttemptContent
        )
        setSession(session)

        guard let bestAttemptContent else {
            logger.warning(
                "Failed to create mutable notification content; falling back to original content."
            )
            finishSession(id: requestID, with: request.content)
            return
        }

        let data: AnyMsgData
        do {
            data = try AnyMsgData.parse(from: bestAttemptContent.userInfo)
        } catch {
            logger.error("Failed to parse notification payload: \(error.localizedDescription, privacy: .public)")
            finishSession(id: requestID, with: bestAttemptContent)
            return
        }

        bestAttemptContent.subtitle = data.pushNotificationSubtitle
        bestAttemptContent.body = data.pushNotificationBody
        logger.info("Last known app state: \(AppStateStore.read().rawValue, privacy: .public)")

        let task = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                try Task.checkCancellation()
                try await prepareStoreIfNeeded(for: data)
                try Task.checkCancellation()
                try await Socket.shared.handleReceive(data)
                finishSession(id: requestID, with: currentContent(for: requestID))
            } catch is CancellationError {
                logger.info("Notification processing cancelled before completion.")
            } catch {
                logger.error("Notification processing failed: \(error.localizedDescription, privacy: .public)")
                finishSession(id: requestID, with: currentContent(for: requestID))
            }
        }
        setProcessingTask(task, for: requestID)
    }

    override func serviceExtensionTimeWillExpire() {
        sessionsToExpire().forEach { session in
            session.processingTask?.cancel()
            finishSession(id: session.id, with: currentContent(for: session.id))
        }
    }

    private func prepareStoreIfNeeded(for data: AnyMsgData) async throws {
        guard let id = resolvedCurrentUserID(for: data) else {
            logger.error("Unable to resolve current user ID for notification reconciliation.")
            throw NotificationServiceError.currentUserIDUnavailable
        }

        if GroupStorage.shared.string(for: .auth(.currentUserID)) != id {
            GroupStorage.shared.save(id, for: .auth(.currentUserID))
        }

        if await !Store.shared.hasSetUp(for: id) {
            await Store.shared.start(with: id)
        }
    }

    private func resolvedCurrentUserID(for data: AnyMsgData) -> String? {
        if let currentUserID = try? CurrentUserID.get() {
            return currentUserID
        }

        let actorID: String? = switch data {
        case let .newMsg(rMsg), let .updatedMsg(rMsg), let .deleteMsg(rMsg):
            rMsg.senderID
        case let .typingStatus(status):
            status.senderID
        case let .seenStatus(status):
            status.userID
        case .reaction:
            nil
        }

        guard
            let actorID,
            data.conID.contains("|")
        else {
            return nil
        }

        let participants = data.conID
            .split(separator: "|")
            .map(String.init)
            .filter { !$0.isEmpty }

        if participants.count == 2 {
            return participants.first(where: { $0 != actorID })
        }

        return nil
    }

    private func currentContent(for requestID: String) -> UNNotificationContent {
        guard let session = session(for: requestID) else {
            return UNMutableNotificationContent()
        }

        if let bestAttemptContent = session.bestAttemptContent {
            return bestAttemptContent
        }

        return session.originalContent
    }

    private func finishSession(id: String, with content: UNNotificationContent) {
        guard let session = removeSession(for: id) else {
            return
        }

        if session.isFinished {
            return
        }

        session.isFinished = true
        session.processingTask?.cancel()
        session.contentHandler(content)
    }

    private func setSession(_ session: RequestSession) {
        sessionsLock.lock()
        defer { sessionsLock.unlock() }
        sessions[session.id] = session
    }

    private func setProcessingTask(_ task: Task<Void, Never>, for requestID: String) {
        sessionsLock.lock()
        defer { sessionsLock.unlock() }
        sessions[requestID]?.processingTask = task
    }

    private func session(for requestID: String) -> RequestSession? {
        sessionsLock.lock()
        defer { sessionsLock.unlock() }
        return sessions[requestID]
    }

    private func removeSession(for requestID: String) -> RequestSession? {
        sessionsLock.lock()
        defer { sessionsLock.unlock() }
        return sessions.removeValue(forKey: requestID)
    }

    private func sessionsToExpire() -> [RequestSession] {
        sessionsLock.lock()
        defer { sessionsLock.unlock() }
        return Array(sessions.values)
    }
}
