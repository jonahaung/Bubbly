// © 2026 Aung Ko Min

import Core
import Database
import Foundation
import Services
import UIKit
import XUI

public actor MockMessageCreator {
    public enum Direction: Sendable, Hashable {
        case incoming
        case outgoing
        case mixed
    }

    public struct Batch: Sendable, Hashable {
        public var textCount: Int
        public var attachmentCount: Int
        public var photoCount: Int
        public var interval: TimeInterval
        public var newestDate: Date
        public var direction: Direction

        public init(
            textCount: Int = 24,
            attachmentCount: Int = 8,
            photoCount: Int = 8,
            interval: TimeInterval = 60 * 12,
            newestDate: Date = .now,
            direction: Direction = .mixed,
        ) {
            self.textCount = textCount
            self.attachmentCount = attachmentCount
            self.photoCount = photoCount
            self.interval = interval
            self.newestDate = newestDate
            self.direction = direction
        }
    }

    public enum Error: Swift.Error {
        case missingMessageStore
    }

    private let mediaManager: MediaManager

    public init(mediaManager: MediaManager = .shared) {
        self.mediaManager = mediaManager
    }

    @discardableResult
    public func createMessages(
        in conversation: Conversation,
        batch: Batch = .init(),
    ) async throws -> [Message] {
        let currentUserID = try CurrentUserID.get()
        guard let store = await Store.shared.msgStore else {
            throw Error.missingMessageStore
        }

        _ = try await ConversationPropertiesRepo.getOrCreate(
            for: conversation.uid,
            refetch: false,
        )

        let kinds = messageKinds(for: batch)
        guard kinds.isEmpty == false else {
            return []
        }

        let oldestDate = batch.newestDate.addingTimeInterval(
            -Double(max(0, kinds.count - 1)) * batch.interval,
        )

        var messages: [Message] = []
        messages.reserveCapacity(kinds.count)

        for (index, kind) in kinds.enumerated() {
            let senderID = senderID(
                for: conversation,
                currentUserID: currentUserID,
                direction: batch.direction,
                index: index,
            )
            let date = oldestDate.addingTimeInterval(Double(index) * batch.interval)
            let message = try await makeMessage(
                kind: kind,
                senderID: senderID,
                conversationID: conversation.uid,
                date: date,
                index: index,
                currentUserID: currentUserID,
            )
            try await store.insert(message)
            await Socket.shared.notifyMessage(.newMsg(rMsg: .init(message)))
            messages.append(message)
        }

        return messages
    }

    @discardableResult
    public func createTextMessages(
        count: Int,
        in conversation: Conversation,
        newestDate: Date = .now,
        interval: TimeInterval = 60 * 5,
        direction: Direction = .mixed,
    ) async throws -> [Message] {
        try await createMessages(
            in: conversation,
            batch: .init(
                textCount: count,
                attachmentCount: 0,
                photoCount: 0,
                interval: interval,
                newestDate: newestDate,
                direction: direction,
            ),
        )
    }

    @discardableResult
    public func createAttachmentMessages(
        count: Int,
        in conversation: Conversation,
        newestDate: Date = .now,
        interval: TimeInterval = 60 * 5,
        direction: Direction = .mixed,
    ) async throws -> [Message] {
        try await createMessages(
            in: conversation,
            batch: .init(
                textCount: 0,
                attachmentCount: count,
                photoCount: 0,
                interval: interval,
                newestDate: newestDate,
                direction: direction,
            ),
        )
    }

    @discardableResult
    public func createPhotoMessages(
        count: Int,
        in conversation: Conversation,
        newestDate: Date = .now,
        interval: TimeInterval = 60 * 5,
        direction: Direction = .mixed,
    ) async throws -> [Message] {
        try await createMessages(
            in: conversation,
            batch: .init(
                textCount: 0,
                attachmentCount: 0,
                photoCount: count,
                interval: interval,
                newestDate: newestDate,
                direction: direction,
            ),
        )
    }
}

private extension MockMessageCreator {
    enum MessageKind: Sendable {
        case text
        case attachment
        case photo
    }

    func messageKinds(for batch: Batch) -> [MessageKind] {
        let total = max(0, batch.textCount) + max(0, batch.attachmentCount) + max(0, batch.photoCount)
        guard total > 0 else {
            return []
        }

        var remainingText = max(0, batch.textCount)
        var remainingAttachments = max(0, batch.attachmentCount)
        var remainingPhotos = max(0, batch.photoCount)
        var result: [MessageKind] = []
        result.reserveCapacity(total)

        while result.count < total {
            if remainingText > 0 {
                result.append(.text)
                remainingText -= 1
            }
            if remainingAttachments > 0 {
                result.append(.attachment)
                remainingAttachments -= 1
            }
            if remainingPhotos > 0 {
                result.append(.photo)
                remainingPhotos -= 1
            }
        }

        return result
    }

    func senderID(
        for conversation: Conversation,
        currentUserID: String,
        direction: Direction,
        index: Int,
    ) -> String {
        let incomingSenders = conversation.members.filter { $0 != currentUserID }

        switch direction {
        case .incoming:
            guard incomingSenders.isEmpty == false else {
                return currentUserID
            }
            return incomingSenders[index % incomingSenders.count]
        case .outgoing:
            return currentUserID
        case .mixed:
            guard incomingSenders.isEmpty == false else {
                return currentUserID
            }
            if index.isMultiple(of: 3) {
                return currentUserID
            }
            return incomingSenders[index % incomingSenders.count]
        }
    }

    func makeMessage(
        kind: MessageKind,
        senderID: String,
        conversationID: String,
        date: Date,
        index: Int,
        currentUserID: String,
    ) async throws -> Message {
        let attachments: [Attachment]
        let text: String?

        switch kind {
        case .text:
            attachments = []
            text = await Lorem.random()
        case .attachment:
            attachments = [try makeAttachment(index: index)]
            text = index.isMultiple(of: 2) ? nil : attachmentCaptions[index % attachmentCaptions.count]
        case .photo:
            attachments = [try await makePhotoAttachment(index: index)]
            text = index.isMultiple(of: 2) ? nil : photoCaptions[index % photoCaptions.count]
        }

        return Message(
            uid: await IDGenerator.shared.make(),
            senderID: senderID,
            conID: conversationID,
            text: text,
            date: date,
            deliveryStatus: senderID == currentUserID ? .delivered : .read,
            attachments: attachments,
            reactions: [],
        )
    }

    func makeAttachment(index: Int) throws -> Attachment {
        var attachment = Attachment(
            uid: UUID().uuidString,
            url: attachmentURLs.random(),
            attachMentTypeRaw: AttachMentType.link.rawValue,
            aspectRatio: 1.6,
            title: attachmentTitles.randomElement() ?? attachmentTitles[index % attachmentTitles.count],
            subTitle: attachmentSubtitles.randomElement() ?? attachmentSubtitles[index % attachmentSubtitles.count],
        )
        let data = try mediaManager.createData(from: previewImage(index: index, kind: .attachment))
        try attachment.file()?.write(data)
        return attachment
    }

    func makePhotoAttachment(index: Int) async throws -> Attachment {
        let url = DemoImages.demoPhotosURLs.randomElement() ?? DemoImages.demoPhotosURLs[index % DemoImages.demoPhotosURLs.count]
        return Attachment(
            uid: await IDGenerator.shared.make(),
            url: url.absoluteString,
            thumbnailUrl: url.absoluteString,
            attachMentTypeRaw: AttachMentType.image.rawValue,
            aspectRatio: 4.0 / 3.0,
        )
    }

    func previewImage(index: Int, kind: MessageKind) -> UIImage {
        let size = CGSize(width: 1200, height: 900)
        let renderer = UIGraphicsImageRenderer(size: size)
        let palette = palettes[index % palettes.count]
        let symbolName: String
        switch kind {
        case .text:
            symbolName = "text.bubble.fill"
        case .attachment:
            symbolName = "paperclip.circle.fill"
        case .photo:
            symbolName = "photo.fill"
        }

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [palette.0.cgColor, palette.1.cgColor] as CFArray,
                locations: [0.0, 1.0],
            )
            if let gradient {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: [],
                )
            } else {
                palette.0.setFill()
                context.cgContext.fill(rect)
            }

            UIColor.white.withAlphaComponent(0.16).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 80, y: 70, width: 260, height: 260))
            context.cgContext.fillEllipse(in: CGRect(x: 780, y: 510, width: 280, height: 280))

            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 260, weight: .regular)
            let symbol = UIImage(systemName: symbolName, withConfiguration: symbolConfig)?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            let symbolRect = CGRect(x: 470, y: 300, width: 260, height: 260)
            symbol?.draw(in: symbolRect)
        }
    }

    var attachmentURLs: [String] {
        [

            // Apple / iOS (strong preview support)

            "https://developer.apple.com/videos/play/wwdc2023/10148/",

            "https://developer.apple.com/documentation/swiftui/text",

            

            // GitHub (very common in dev chats)

            "https://github.com/apple/swift",

            "https://github.com/pointfreeco/swift-composable-architecture",

            

            // Articles / blogs (rich previews)

            "https://medium.com/swift-programming/advanced-swiftui-performance-techniques",

            "https://www.avanderlee.com/swiftui/swiftui-performance-tips/",

            

            // StackOverflow (very realistic)

            "https://stackoverflow.com/questions/56517610/swiftui-how-to-update-view",

            

            // YouTube (video preview)

            "https://www.youtube.com/watch?v=comQ1-x2a1Q",

            

            // Product / landing (nice OG images)

            "https://www.notion.so/",

            "https://linear.app/",

            

            // News / tech (good metadata)

            "https://techcrunch.com/2024/01/01/apple-ios-update/",

            

            // Image-based preview

            "https://unsplash.com/photos/a-computer-screen-with-code-on-it",

        ]
    }

    var attachmentTitles: [String] {
        [
            "Release Notes",
            "Design Spec",
            "API Contract",
            "Launch Checklist",
        ]
    }

    var attachmentSubtitles: [String] {
        [
            "Updated reference attached for review.",
            "Latest handoff bundle for the conversation.",
            "Shared context for the next iteration.",
            "Attached details for the current thread.",
        ]
    }

    var attachmentCaptions: [String] {
        [
            "Sharing the latest attachment here.",
            "This is the file we referenced earlier.",
            "Attaching the updated material.",
            "Dropping the supporting doc.",
        ]
    }

    var photoCaptions: [String] {
        [
            "Here is the latest photo.",
            "Captured this just now.",
            "Sharing the visual update.",
            "This should match the current state.",
        ]
    }

    var palettes: [(UIColor, UIColor)] {
        [
            (.systemBlue, .systemTeal),
            (.systemPink, .systemOrange),
            (.systemIndigo, .systemPurple),
            (.systemGreen, .systemMint),
            (.systemRed, .systemBrown),
        ]
    }
}
