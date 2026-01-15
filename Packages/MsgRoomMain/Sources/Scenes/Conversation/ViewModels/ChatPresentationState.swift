//
//  ChatPresentationState.swift
//  MsgRoomMain
//
//  Refactored version
//

import Database
import Foundation
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class ChatPresentationState {

	var overlayItem: ChatOverlayView.Item?
	private(set) var toastItem: ChatToastItem = .none
	private(set) var selectedMsg: SelectedMsg?
	private(set) var typingStatusText: String?
	var bottomAccessory = BottomAccessoryItem.contactAvator
	private(set) var floatingDateString: String?
	private(set) var summary: String?
	var showContactInfo: Bool
	@ObservationIgnored private let dateCache = ExpiringCache<String>()

	init(_ config: ConversationInitializer.Configuration) {
		showContactInfo = !config.canPaginate
	}

	func updateToast(_ item: ChatToastItem) {
		toastItem = item
	}

	func updateFocusedFrame(_ item: ChatOverlayView.Item?) {
		withTransaction(.withoutAnimation) {
			overlayItem = item
		}
	}

	func updateShowContactInfo(_ show: Bool) {
		showContactInfo = show
	}

	func updateFloatingDate(_ value: String?) {
		floatingDateString = value
	}

	func updateSelectedMsg(_ item: SelectedMsg?) {
		selectedMsg = item
	}

	func updateTypingStatus(_ status: AnyMsgData.TypingStatusPayload) {
		if status.isTyping, let contact = ContactStore.shared.contact(for: status.senderID) {
			typingStatusText = "\(contact.name) is typing..."
		} else {
			typingStatusText = nil
		}
	}

	func updateFloatingDate(_ date: Date) {
		floatingDateString = formattedFloatingDate(from: date)
	}

	private func formattedFloatingDate(from date: Date) -> String {
		if let cached = dateCache.value(forKey: date) {
			return cached
		}
		let string: String =
		switch true {
		case date.isInToday:
			date.formatted(.dateTime.hour().minute())
		case date.isInYesterday:
			"Yesterday " + date.formatted(.dateTime.hour().minute())
		case date.isInThisWeek:
			date.formatted(.dateTime.weekday(.short).hour().minute())
		case date.isInThisMonth:
			date.formatted(.dateTime.day().hour().minute())
		default:
			date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
		}
		dateCache.setValue(string, forKey: date)
		return string
	}
}
