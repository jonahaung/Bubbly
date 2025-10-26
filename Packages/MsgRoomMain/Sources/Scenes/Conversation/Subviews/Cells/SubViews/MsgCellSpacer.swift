//
//  MsgCellSpacer.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 8/10/25.
//

import SwiftUI
import Core

struct MsgCellSpacer: View {

	let id: String

	var body: some View {
		Color.primary.hidden()
			.frame(height: ChatLayoutConstants.Cell.sectionSpacing)
			.id(id+Self.typeName)
			.layoutValue(.init(uid: id+Self.typeName, recipient: .none))
	}
}
