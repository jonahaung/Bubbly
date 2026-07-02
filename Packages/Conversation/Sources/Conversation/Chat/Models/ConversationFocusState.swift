//
//  ConversationFocusState.swift
//  Conversation
//
//  Created by Aung Ko Min on 28/5/26.
//

import XUI
import SwiftUI

enum ConversationFocusState: Sendable, Hashable {
    case inputTextField, none
}
extension EnvironmentValues {
    @Entry var sharedFocusState: SharedFocusState<ConversationFocusState>?
}
