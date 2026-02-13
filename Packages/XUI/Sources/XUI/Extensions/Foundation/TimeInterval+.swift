import Foundation

public extension TimeInterval {
	static let oneSecond: Self = 1
	static let oneMinute: Self = 60
	static let oneHour: Self = 60 * oneMinute
	static let oneDay: Self = 24 * oneHour
	static let oneWeek: Self = 7 * oneDay
	static let oneYear: Self = 365 * oneDay
}
