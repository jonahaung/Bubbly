//
//  MsgCell.swift
//  Msgr
//
//  Created by Aung Ko Min on 22/10/22.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct MsgCell: View {
	
	@Environment(MsgCellViewModel.self) private var viewModel
	@Environment(\.msgCellActions) private var sendMsgCellInteraction
	@Environment(\.selectedMsg) private var selectedMsg
	@Environment(\.layoutCache) private var layoutCache
	
	private var isSelected: Bool { selectedMsg?.id == viewModel.id }
	private var layout: MsgCellLayout { viewModel.layout }
	
	var body: some View {
		VStack(alignment: viewModel.horizontalAlignment, spacing: 0) {
			if layout.showTimeSeparator {
				TimeSeparater()
			}
			if layout.showTopPadding {
				CellSpacer()
			}
			if isSelected {
				Header()
			}
			HStack(alignment: .bottom, spacing: 0) {
				if !viewModel.isSender {
					IncomingAccessory()
				}
				GestureAware {
					Content()
				}
				OutgoingAccessory()
			}
			if isSelected {
				Footer()
			}
		}
		.equatable(by: viewModel.reloadID)
		.environment(\.viewIsVisible, viewModel.isVisible)
	}
}
