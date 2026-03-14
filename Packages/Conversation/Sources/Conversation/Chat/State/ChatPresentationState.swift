//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Foundation
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class ChatPresentationState {

	enum Intent {
		case toast(_ newValue: ChatToastItem?)
		case date(_ newValue: Date)
		case overlayItem(_ newValue: ChatOverlayView.Item?)
		case bottomAccessory(_ newValue: BottomAccessoryItem?)
		case showContactInfo(_ newValue: Bool)
		case typing(_ newValue: AnyMsgData.TypingStatusPayload?)
	}

	struct State: Equatable {
		var toast: ChatToastItem?
		var dateText: String?
		var overlayItem: ChatOverlayView.Item?
		var bottomAccessory: BottomAccessoryItem?
		var typingStatus: AnyMsgData.TypingStatusPayload?
		var showContactInfo: Bool
	}

	private(set) var state: State
	@ObservationIgnored
	private var ignoredState: State

	@ObservationIgnored
	private let displayLink = DisplayLink(0.5)
	@ObservationIgnored
	private let dateCache = ExpiringCache<Date, String>()

	init(_ config: ConversationInitializer.Configuration) {
		let initialState = State(
			toast: nil,
			dateText: nil,
			overlayItem: nil,
			bottomAccessory: nil,
			typingStatus: nil,
			showContactInfo: !config.canPaginate,
		)
		state = initialState
		ignoredState = initialState

		displayLink.onTargetReached = { [weak self] _ in
			guard let self else { return }
			self.state = ignoredState
		}
	}
}

extension ChatPresentationState {
	func send(_ intent: Intent) {
		switch intent {
		case .toast(let newValue):
			ignoredState.toast = newValue
		case .date(let newValue):
			ignoredState.dateText = formattedFloatingDate(from: newValue)

			func formattedFloatingDate(from date: Date) -> String {

				if let cached = dateCache.value(forKey: date) {
					return cached
				}

				let formatter = Date.FormatStyle.dateTime
				let string: String

				if date.isInToday {
					string = date.formatted(formatter.hour().minute())
				} else if date.isInYesterday {
					string = "Yesterday " + date.formatted(formatter.hour().minute())
				} else if date.isInThisWeek {
					string = date.formatted(formatter.weekday(.short).hour().minute())
				} else if date.isInThisMonth {
					string = date.formatted(formatter.day().hour().minute())
				} else {
					string = date.formatted(formatter.day().month(.abbreviated).hour().minute())
				}
				dateCache.setValue(string, forKey: date)
				return string
			}
		case .overlayItem(let newValue):
			ignoredState.overlayItem = newValue
		case .bottomAccessory(let newValue):
			ignoredState.bottomAccessory = newValue
		case .showContactInfo(let newValue):
			ignoredState.showContactInfo = newValue
		case .typing(let newValue):
			ignoredState.typingStatus = newValue
		}
		displayLink.start()
	}
}
