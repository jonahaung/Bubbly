//
//  MsgCellInteraction.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 12/7/25.
//

import Database
import SwiftUI

struct MsgCellInteraction: Sendable {
    enum Action: Equatable, Hashable, Sendable {
        case onTapMsg(String?)
        case onMarkMsg(Message)
        case onTapAvatar(String)
        case onFocusMsgBubble(_ item: ChatOverlayView.Item)
    }

    let action: @Sendable (Action) -> Void
    func callAsFunction(_ data: Action) {
        action(data)
    }
}

struct MsgCellInteractionKey: EnvironmentKey {
    static let defaultValue: MsgCellInteraction? = nil
}

extension EnvironmentValues {
    var sendMsgCellInteraction: MsgCellInteraction? {
        get { self[MsgCellInteractionKey.self] }
        set { self[MsgCellInteractionKey.self] = newValue }
    }
}

extension View {
    @MainActor
    func receiveMsgCellInteraction(
        _ action:
        @Sendable @escaping (
            MsgCellInteraction.Action
        ) -> Void
    ) -> some View {
        environment(\.sendMsgCellInteraction, MsgCellInteraction(action: action))
    }
}
