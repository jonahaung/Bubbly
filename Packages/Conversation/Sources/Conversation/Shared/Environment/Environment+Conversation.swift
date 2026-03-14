//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI
import XUI

public extension EnvironmentValues {
    @Entry var conversation = Conversation.empty
    @Entry var seenMembers = [SeenMember]()
    @Entry var isVisible = false
    @Entry var attachmentFetcher: AttachmentFetcher? = nil
	@Entry var conversationTheme: ChatTheme = .empty
}
