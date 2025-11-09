//
//  MsgCellTimeSeparaterView.swift
//  Conversation
//
//  Created by Aung Ko Min on 13/2/22.
//

import Core
import SwiftUI
import XUI

struct MsgCellTimeSeparaterView: View {
    let id: String
    let date: Date

    var body: some View {
        Text(
            date.formatted(.dateTime.day().weekday(.abbreviated).hour().minute())
        )
        .foregroundStyle(.primary)
        .font(.footnote)
        .frame(height: ChatLayoutConstants.Cell.timeSeparaterHeight, alignment: .center)
        .equatable(by: id)
        .id(id + Self.typeName)
        .layoutValue(.init(uid: id + Self.typeName, recipient: .none))
    }
}
