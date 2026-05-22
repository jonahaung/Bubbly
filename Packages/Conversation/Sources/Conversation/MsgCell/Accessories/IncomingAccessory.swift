//  IncomingAccessory.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database
import Services

struct IncomingAccessory: View, @MainActor Equatable {

    let state: MsgCellViewModel.State
    let status: DeliveryStatus
    @Environment(\.msgCellActions) private var msgCellActions
    @Environment(\.members) private var members

    var body: some View {
        ZStack(alignment: .bottom) {
            switch status {
            case .delivered:
                Circle()
                    .foregroundStyle(.blue)
                    .frame(width: 8, height: 8)
            case .sent:
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 8, height: 8)
            case .sending:
                Image(systemName: "circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 8, height: 8)
            case .partiallyFailed:
                Circle()
                    .foregroundStyle(.orange)
                    .frame(width: 8, height: 8)
            case .read:
                ZeroSizeView()
            case .initial:
                Circle().fill(Color.orange)
            }
            if state.layout.showAvatar, let sender = members.contact(for: state.msg.senderID) {
                ProfilePhoto(
                    sender, size: .custom(Spacing.md),
                    tapAction: .custom { msgCellActions?(.onTapAvatar(state.id)) }
                )
            }
        }
        .frame(width: Spacing.md + 4)
        .geometryGroup()
    }

    static func == (lhs: IncomingAccessory, rhs: IncomingAccessory) -> Bool {
        lhs.state.layout.showAvatar == rhs.state.layout.showAvatar && lhs.status == rhs.status
    }
}
