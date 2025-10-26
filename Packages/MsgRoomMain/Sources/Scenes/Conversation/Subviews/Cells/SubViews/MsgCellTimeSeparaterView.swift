//
//  MsgCellTimeSeparaterView.swift
//  Conversation
//
//  Created by Aung Ko Min on 13/2/22.
//

import SwiftUI
import XUI

struct MsgCellTimeSeparaterView: View {

	let id: String
	let date: Date

	var body: some View {
		VStack {
			Text(
				date.formatted(.dateTime.day().weekday(.abbreviated).hour().minute())
			)
		}
		.foregroundStyle(.gray)
		.font(.subheadline.uppercaseSmallCaps())
		.frame(height: 50, alignment: .center)
		.equatable(by: id)
		.id(id+Self.typeName)
		.layoutValue(.init(uid: id+Self.typeName, recipient: .none))
	}
}
