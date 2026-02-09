//
//  MsgCell+CellSpacer.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 8/10/25.
//

import Core
import Database
import SwiftUI

extension MsgCell {
	struct CellSpacer: View {
		var body: some View {
			Color.white.hidden()
				.frame(height: ChatLayoutConstants.Cell.sectionSpacing)
		}
	}
}
