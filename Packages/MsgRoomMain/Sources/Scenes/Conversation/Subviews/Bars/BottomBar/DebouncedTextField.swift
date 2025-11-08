//
//  DebouncedTextField.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 8/11/25.
//

import SwiftUI

@MainActor
public struct ChatTextField: View {

	@Binding private var text: String
	private let placeholder: String
	private let debounceTime: TimeInterval
	private let onDebouncedChange: (String) -> Void
	@State private var internalText: String
	@State private var debounceTask: Task<Void, Never>?

	public init(
		_ placeholder: String = "Text ..",
		text: Binding<String>,
		debounceTime: TimeInterval = 0.5,
		onDebouncedChange: @escaping (String) -> Void = { _ in }
	) {
		self._text = text
		self.placeholder = placeholder
		self.debounceTime = debounceTime
		self.onDebouncedChange = onDebouncedChange
		self._internalText = State(initialValue: text.wrappedValue)
	}

	public var body: some View {
		TextField(placeholder, text: $internalText, axis: .vertical)
			.lineLimit(1...20)
			.textInputAutocapitalization(.sentences)
			.textFieldStyle(.plain)
			.submitLabel(.done)
			.onChange(of: internalText, debounce: debounceTime) { newValue in
				if text != newValue {
					text = newValue
					onDebouncedChange(newValue)
				}
			}
			.onChange(of: text) { oldValue, newValue in
				if newValue != internalText && oldValue == internalText {
					internalText = newValue
				}
			}
			.onDisappear {
				debounceTask?.cancel()
			}
			.accessibilityLabel(Text(placeholder))
	}
}

private extension View {
	func onChange<T: Equatable>(
		of value: T,
		debounce delay: TimeInterval,
		perform action: @escaping (T) -> Void
	) -> some View {
		modifier(DebounceModifier(value: value, delay: delay, action: action))
	}
}

private struct DebounceModifier<T: Equatable>: ViewModifier {
	let value: T
	let delay: TimeInterval
	let action: (T) -> Void

	@State private var task: Task<Void, Never>?

	func body(content: Content) -> some View {
		content
			.onChange(of: value) { newValue in
				task?.cancel()
				task = Task {
					try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
					guard !Task.isCancelled else { return }
					await MainActor.run { action(newValue) }
				}
			}
			.onDisappear {
				task?.cancel()
			}
	}
}
