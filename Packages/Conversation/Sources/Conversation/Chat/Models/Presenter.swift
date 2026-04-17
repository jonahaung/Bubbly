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
        case date(_ newValue: Date)
        case overlayItem(_ newValue: OverlayMenuItem?)
        case bottomAccessory(_ newValue: AccessoryBarItem?)
        case typing(_ newValue: AnyMsgData.TypingStatusPayload?)
    }

    struct State: Equatable {
        var toast: ChatToastItem? = nil
        var dateText: String? = nil
        var overlayItem: OverlayMenuItem? = nil
        var bottomAccessory: AccessoryBarItem? = nil
        var typingStatus: AnyMsgData.TypingStatusPayload? = nil
    }

    var state: State

    

    @ObservationIgnored
    private let dateCache: ExpiringCache<Date, String> = .init()
}

extension Presenter {
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
        case let .typing(newValue):
            state.typingStatus = newValue
        }
    }
}
