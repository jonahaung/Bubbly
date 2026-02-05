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

	let viewModel: MsgCellViewModel
	@Environment(\.selectedMsg) private var selectedMsg

	private var isSelected: Bool { selectedMsg?.id == viewModel.id }
	private var layout: MsgCellLayout { viewModel.layout }
	@Environment(\.typography) var typography
	@Environment(\.conversationTheme) private var theme

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
					Content(viewModel: viewModel, theme: theme, selectedMsg: selectedMsg)
				}
				OutgoingAccessory()
			}
			if isSelected {
				Footer()
			}
		}
		.font(typography.body)
		.foregroundStyle(Color.label)
		.equatable(by: viewModel.reloadID)
		.environment(\.viewIsVisible, viewModel.isVisible)
	}
}
