// © 2026 Aung Ko Min

#if os(iOS)
//
    // Copyright © 2026 Aung Ko Min. All rights reserved.
//

    import Database
    import Services
    import SwiftUI
    import XUI

    public extension EnvironmentValues {
        @Entry var conversation: Conversation = .empty
//    @Entry var seenMembers = [SeenMember]()
        @Entry var isVisible = false
        @Entry var attachmentFetcher: AttachmentFetcher? = nil
        @Entry var conversationTheme: ChatTheme = .empty
    }

#endif
