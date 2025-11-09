//
//  MsgCellSpacer.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 8/10/25.
//

import Core
import SwiftUI

struct MsgCellSpacer: View {
    let id: String
    var body: some View {
        Color.primary.hidden()
            .frame(height: ChatLayoutConstants.Cell.sectionSpacing)
            .id(id + Self.typeName)
            .layoutValue(.init(uid: id + Self.typeName, recipient: .none))
    }
}
