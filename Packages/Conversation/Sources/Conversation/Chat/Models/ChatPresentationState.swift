//
// Created by Aung Ko Min
//

import Database
import Foundation
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class ChatPresentationState {

	// MARK: Lifecycle

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
	}

	// MARK: Internal

	enum Intent {
		case toast(_ newValue: ChatToastItem?)
		case date(_ newValue: Date)
		case overlayItem(_ newValue: OverlayMenuItem?)
		case bottomAccessory(_ newValue: AccessoryBarItem?)
		case showContactInfo(_ newValue: Bool)
		case typing(_ newValue: AnyMsgData.TypingStatusPayload?)
	}

	struct State: Equatable {
		var toast: ChatToastItem?
		var dateText: String?
		var overlayItem: OverlayMenuItem?
		var bottomAccessory: AccessoryBarItem?
		var typingStatus: AnyMsgData.TypingStatusPayload?
		var showContactInfo: Bool
	}

	var state: State

	// MARK: Private

	@ObservationIgnored
	private let dateCache: ExpiringCache<Date, String> = .init()

}

extension ChatPresentationState {
	func send(_ intent: Intent) {
		switch intent {
		case let .toast(newValue):
			state.toast = newValue
		case let .date(newValue):
			let dateText = formattedFloatingDate(from: newValue)
			state.dateText = dateText
			func formattedFloatingDate(from date: Date) -> String {

				if let cached = dateCache.value(forKey: date) {
					return cached
				}

				let formatter = Date.FormatStyle.dateTime
				let string: String =
					if date.isInToday {
						date.formatted(formatter.hour().minute())
					} else if date.isInYesterday {
						"Yesterday " + date.formatted(formatter.hour().minute())
					} else if date.isInThisWeek {
						date.formatted(formatter.weekday(.short).hour().minute())
					} else if date.isInThisMonth {
						date.formatted(formatter.day().hour().minute())
					} else {
						date.formatted(formatter.day().month(.abbreviated).hour().minute())
					}
				dateCache.setValue(string, forKey: date)
				return string
			}
		case let .overlayItem(newValue):
			state.overlayItem = newValue
		case let .bottomAccessory(newValue):
			state.bottomAccessory = newValue
		case let .showContactInfo(newValue):
			state.showContactInfo = newValue
		case let .typing(newValue):
			state.typingStatus = newValue
		}
	}
}
