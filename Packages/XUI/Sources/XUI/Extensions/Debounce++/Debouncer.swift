//
//  Debouncer.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 21/6/24.
//

import Foundation

public final class Debouncer {
	private var timerByID: [String: Timer] = [:]
	public init() {}
	public func delay(for duration: TimeInterval, id: String = "default", operation: @escaping @Sendable () -> Void) {
		self.cancel(id: id)
		self.timerByID[id] = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { @Sendable _ in
			operation()
		}
	}
	public func cancel(id: String) {
		self.timerByID[id]?.invalidate()
		self.timerByID.removeValue(forKey: id)
	}
	public func cancelAll() {
		for timer in self.timerByID.values {
			timer.invalidate()
		}
	}
}
