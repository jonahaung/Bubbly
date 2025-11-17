//
//  ChatRoomAction.swift
//  Services
//
//  Created by Aung Ko Min on 3/2/25.
//

import Database
import SwiftUI

public struct ChatRoomAction: EnvironmentKey {
    public static let defaultValue: (@Sendable (AnyMsgData) -> Void)? = nil
}

public extension EnvironmentValues {
    var sendChatRoomAction: (@Sendable (AnyMsgData) -> Void)? {
        get { self[ChatRoomAction.self] }
        set { self[ChatRoomAction.self] = newValue }
    }
}
