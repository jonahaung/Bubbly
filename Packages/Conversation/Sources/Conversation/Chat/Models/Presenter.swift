// © 2026 Aung Ko Min

import Database
import Foundation
import Services
import SwiftUI
import XUI

// MARK: - Presenter

@MainActor
@Observable
final class Presenter {

    init(_ conID: String) {
        state = .init()
    }

    enum Intent {
        case toast(_ newValue: ChatToastItem?)
        case date(_ newValue: String)
        case overlayItem(_ newValue: OverlayMenuItem?)
        case bottomAccessory(_ newValue: AccessoryBarItem?)
        case typing(_ newValue: AnyMsgData.TypingStatusPayload?)
    }

    struct State: Equatable, Sendable {
        var toast: ChatToastItem? = nil
        var dateText: String? = nil
        var overlayItem: OverlayMenuItem? = nil
        var bottomAccessory: AccessoryBarItem? = nil
        var typingStatus: AnyMsgData.TypingStatusPayload? = nil
    }

    var state: State
}

extension Presenter {
    func send(_ intent: Intent) {
        switch intent {
        case .toast(let newValue):
            state.toast = newValue
        case .date(let newValue):
            state.dateText = newValue
        case .overlayItem(let newValue):
            state.overlayItem = newValue
        case .bottomAccessory(let newValue):
            state.bottomAccessory = newValue
        case .typing(let newValue):
            state.typingStatus = newValue
        }
    }
}
