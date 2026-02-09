//
//  DebouncedOnChange.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 2/6/24.
//
import SwiftUI

private struct DebouncedOnChangeViewModifier<Value: Equatable>: ViewModifier {
	let value: Value
	let action: @Sendable ((Value, Value)) async -> Void
	let sleep: @Sendable () async throws -> Void

	@State private var debouncedTask: Task<Void, Never>?

	func body(content: Content) -> some View {
		content.onChange(of: value) { oldValue, newValue in
			debouncedTask?.cancel()
			debouncedTask = Task {
				do { try await sleep() } catch { return }
				await action((oldValue, newValue))
			}
		}
	}
}

public extension View {
	func onChange<Value: Equatable>(of value: Value,
	                                debounceTime: Duration,
	                                perform action: @Sendable @escaping ((Value, Value)) async
	                                	-> Void) -> some View
	{
		modifier(DebouncedOnChangeViewModifier(value: value, action: action) {
			try await Task.sleep(for: debounceTime)
		})
	}
}
