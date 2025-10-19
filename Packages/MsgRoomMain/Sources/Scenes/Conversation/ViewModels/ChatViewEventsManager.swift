//
//  ChatViewEventsManager.swift
//  MsgRoomMain
//
//  Refactored version
//

import Foundation
import SwiftUI
import Database
import Services
import XUI

@MainActor
@Observable
final class ChatViewEventsManager {

    private(set) var focusedFrame: ChatOverlayView.Item?
    private(set) var toastItem: ChatToastItem = .none
    private(set) var selectedMsg: SelectedMsg?
    private(set) var typingStatusText: String?
    private(set) var floatingDateString: String?
    private(set) var showContactInfo: Bool
	
    init(config: ConversationInitializer.Configuration) {
        showContactInfo = !config.canPaginate
    }

    func updateToast(_ item: ChatToastItem) {
        playHaptic(style: .rigid, intensity: 0.7)
        toastItem = item
    }

    func updateFocusedFrame(_ item: ChatOverlayView.Item?) {
        playHaptic(style: .rigid, intensity: 0.7)
        focusedFrame = item
    }

    func updateShowContactInfo(_ show: Bool) {
        showContactInfo = show
    }

	func updateSelectedMsg(_ item: SelectedMsg?, animated: Bool) {
		if item != nil {
			playHaptic(style: .rigid, intensity: 0.7)
		}
		selectedMsg = item
    }

    func updateTypingStatus(_ status: AnyMsgData.TypingStatusPayload) {
        playHaptic(style: .light, intensity: 0.8)
        if status.isTyping, let contact = ContactStore.shared.contact(for: status.senderID) {
            typingStatusText = "\(contact.name) is typing..."
        } else {
			typingStatusText = nil
        }
    }

    func updateFloatingDate(_ date: Date) {
        floatingDateString = Self.formattedFloatingDate(from: date)
    }

    private func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) {
        Haptics.play(style, intensity)
    }
	
    private static func formattedFloatingDate(from date: Date) -> String {
        switch true {
        case date.isInToday:
            return date.formatted(.dateTime.hour().minute())
        case date.isInYesterday:
            return "Yesterday " + date.formatted(.dateTime.hour().minute())
        case date.isInThisWeek:
            return date.formatted(.dateTime.weekday(.short).hour().minute())
        case date.isInThisMonth:
            return date.formatted(.dateTime.day().hour().minute())
        default:
            return date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
        }
    }
}
