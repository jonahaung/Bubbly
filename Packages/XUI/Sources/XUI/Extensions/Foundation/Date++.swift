//
//  Date++.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 6/4/24.
//

import Foundation

public extension Date {
    func getDifference(from start: Date, unit component: Calendar.Component) -> Int {
        let dateComponents = Calendar.current.dateComponents([component], from: start, to: self)
		return dateComponents.minute ?? 0
    }
}
public extension Date {
	func daysAgoString() -> String {
		let calendar = Calendar.current
		let now = Date()

		let components = calendar.dateComponents([.day, .month], from: self, to: now)

		guard let days = components.day else {
			return "Unknown"
		}

		switch days {
			case 0:
				return "Today"
			case 1...7:
				return "\(days) day\(days > 1 ? "s" : "") ago"
			case 8...30:
				return "This Month"
			default:
				return "Earlier"
		}
	}
}
public extension Date {
	var isInToday: Bool {
		Calendar.current.isDateInToday(self)
	}
	var isInYesterday: Bool {
		Calendar.current.isDateInYesterday(self)
	}
	var isInThisWeek: Bool {
		let now = Date.now
		guard let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) else {
			return false
		}
		return (sevenDaysAgo ... now).contains(self)
	}
	var isInThisMonth: Bool {
		let now = Date.now
		guard let month = Calendar.current.date(byAdding: .month, value: -1, to: now) else {
			return false
		}
		return (month ... now).contains(self)
	}
}
