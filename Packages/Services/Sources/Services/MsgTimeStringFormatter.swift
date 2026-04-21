//
//  MsgTimeStringFormatter.swift
//  Conversation
//
//  Created by Aung Ko Min on 18/4/26.
//

import Foundation

public enum MsgTimeStringFormatter {

    public static func string(
        for date: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {

        if calendar.isDateInToday(date) {
            if isWithinPastOneHour(date, now: now) {
                return format(date, style: .relative)
            }
            return format(date, style: .time)
        }
        
        if calendar.isDateInYesterday(date) {
            return join("Yesterday", format(date, style: .time))
        }

        if calendar.isDateInWeekend(date) {
            return join(
                format(date, style: .weekday),
                format(date, style: .time)
            )
        }

        if calendar.isDate(date, equalTo: now, toGranularity: .month) {
            return join(
                format(date, style: .time),
                format(date, style: .dayMonth)
            )
        }

        return join(
            format(date, style: .time),
            format(date, style: .fullDate)
        )
    }
    
    private static func isWithinPastOneHour(_ date: Date, now: Date) -> Bool {
        date <= now && now.timeIntervalSince(date) <= 3600
    }
}

private extension MsgTimeStringFormatter {

    enum Style {
        case relative
        case time
        case weekday
        case dayMonth
        case fullDate
    }

    static func format(_ date: Date, style: Style) -> String {
        switch style {
        case .time:
            return date.formatted(.dateTime.hour().minute())

        case .weekday:
            return date.formatted(.dateTime.weekday(.abbreviated))

        case .dayMonth:
            return date.formatted(.dateTime.day().month(.abbreviated))

        case .fullDate:
            return date.formatted(.dateTime.day().month(.abbreviated).year(.twoDigits))
        case .relative:
            return RelativeDateTimeFormatter.shared.localizedString(for: date, relativeTo: .now)
        }
    }

    static func join( _ first: String, _ second: String) -> String {
        "\(first), \(second)"
    }
}

private extension RelativeDateTimeFormatter {
    nonisolated(unsafe) static let shared: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}
