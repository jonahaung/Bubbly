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
        isSender: Bool,
        now: Date = .init(),
        calendar: Calendar = .current
    ) -> String {

        if calendar.isDateInToday(date) {
            return format(date, style: .time)
        }

        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return join(
                isSender,
                format(date, style: .weekday),
                format(date, style: .time)
            )
        }

        if calendar.isDate(date, equalTo: now, toGranularity: .month) {
            return join(
                isSender,
                format(date, style: .time),
                format(date, style: .dayMonth)
            )
        }

        return join(
            isSender,
            format(date, style: .time),
            format(date, style: .fullDate)
        )
    }
}

private extension MsgTimeStringFormatter {

    enum Style {
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
        }
    }

    static func join(_ isSender: Bool, _ first: String, _ second: String) -> String {
        isSender ? "\(first), \(second)" : "\(second), \(first)"
    }
}
