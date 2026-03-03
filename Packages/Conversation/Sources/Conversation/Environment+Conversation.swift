//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI
import XUI

public extension EnvironmentValues {
    @Entry var conversationTheme = ConversationTheme.empty
    @Entry var attachmentFetcher = AttachmentFetcher.shared
    @Entry var conversation = Conversation.empty
    @Entry var viewIsVisible = false
    @Entry var selectedMsg: SelectedMsg?
}
