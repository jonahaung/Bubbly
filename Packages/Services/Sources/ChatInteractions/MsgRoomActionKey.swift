//
//  MsgActionKey.swift
//  Services
//
//  Created by Aung Ko Min on 3/2/25.
//

import SwiftUI
import Database

public struct MsgRoomActionKey: EnvironmentKey {
	public static let defaultValue: (@Sendable (AnyMsgData) -> Void)? = nil
}
public extension EnvironmentValues {
    var invokeMsgRoomAction: (@Sendable (AnyMsgData) -> Void)? {
        get { self[MsgRoomActionKey.self] }
        set { self[MsgRoomActionKey.self] = newValue }
    }
}
