//  Presenter.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Services
import Foundation

// MARK: - Presenter

@MainActor
@Observable
final class Presenter {

    init(_: String) {
        state = .init()
    }

    enum Intent {
        case toast(_ newValue: ChatToastItem?)
        case date(_ newValue: String?)
        case overlayItem(_ newValue: OverlayMenuItem?)
        case bottomAccessory(_ newValue: AccessoryBarItem?)
        case typing(_ newValue: AnyMsgData.TypingStatusPayload?)
    }

    struct State: Equatable, Sendable {
        var toast: ChatToastItem?
        var dateText: String?
        var overlayItem: OverlayMenuItem?
        var bottomAccessory: AccessoryBarItem = .contactAvator
        var typingStatus: AnyMsgData.TypingStatusPayload?
    }

    var state: State
}

extension Presenter {
    func send(_ intent: Intent) {
        var state = state
        switch intent {
        case let .toast(newValue):
            state.toast = newValue
        case let .date(newValue):
            state.dateText = newValue
        case let .overlayItem(newValue):
            state.overlayItem = newValue
        case let .bottomAccessory(newValue):
            if let newValue {
                state.bottomAccessory = newValue
            } else {
                state.bottomAccessory = .contactAvator
            }
        case let .typing(newValue):
            state.typingStatus = newValue
        }
        guard self.state != state else { return }
        self.state = state
    }
}
