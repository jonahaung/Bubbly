//
//  MsgActionKey.swift
//  Services
//
//  Created by Aung Ko Min on 3/2/25.
//

import SwiftUI
import Database

public struct ChatRoomAction: EnvironmentKey {
	public static let defaultValue: (@Sendable (AnyMsgData) -> Void)? = nil
}
public extension EnvironmentValues {
    var sendChatRoomAction: (@Sendable (AnyMsgData) -> Void)? {
        get { self[ChatRoomAction.self] }
        set { self[ChatRoomAction.self] = newValue }
    }
}
