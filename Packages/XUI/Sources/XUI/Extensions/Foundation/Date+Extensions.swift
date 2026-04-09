//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public extension Date {
    func getDifference(from start: Date, unit component: Calendar.Component) -> Int {
        let dateComponents = Calendar.current.dateComponents([component], from: start, to: self)
        return dateComponents.minute ?? 0
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
        return (sevenDaysAgo...now).contains(self)
    }

    var isInThisMonth: Bool {
        let now = Date.now
        guard let month = Calendar.current.date(byAdding: .month, value: -1, to: now) else {
            return false
        }
        return (month...now).contains(self)
    }
}
