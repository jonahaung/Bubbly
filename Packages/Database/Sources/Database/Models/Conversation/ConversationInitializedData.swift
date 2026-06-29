import Foundation

public struct ConversationInitializedData: Hashable, Sendable {
        public let conversation: Conversation
        public let properties: ConversationProperties
        public let msgs: [Message]
        public let pagination: PaginationState
        public let members: Members

        public init(
            conversation: Conversation,
            properties: ConversationProperties,
            msgs: [Message],
            pagination: PaginationState,
            members: Members
        ) {
            self.conversation = conversation
            self.properties = properties
            self.msgs = msgs
            self.pagination = pagination
            self.members = members
        }
    }
