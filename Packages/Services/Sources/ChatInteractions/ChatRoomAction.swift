//
//  ChatRoomAction.swift
//  Services
//
//  Created by Aung Ko Min on 3/2/25.
//

import Database
import SwiftUI

public extension EnvironmentValues {
	@Entry var sendChatRoomAction: (@Sendable (AnyMsgData) -> Void)?
}
