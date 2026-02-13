import SwiftUI

public struct DebouncedTextViewConfiguration {
	let placeholder: String
	let debounceDuration: Duration
	let revertOnExit: Bool
	let autoFocus: Bool

	public init(placeholder: String = "text..",
	            debounceDuration: Duration = .seconds(0.3),
	            revertOnExit: Bool = false,
	            autoFocus: Bool = false)
	{
		self.placeholder = placeholder
		self.debounceDuration = debounceDuration
		self.revertOnExit = revertOnExit
		self.autoFocus = autoFocus
	}
}

public struct DebouncedTextField: View {
	@State private var manager: DebouncedTextFieldManager
	@FocusState private var focusState: Bool

	private let config: DebouncedTextViewConfiguration
	@Binding var value: String

	// MARK: - Init

	public init(value: Binding<String>,
	            placeholder: String = "",
	            debounceDuration: Duration = .milliseconds(250),
	            revertOnExit: Bool = false,
	            autoFocus: Bool = false)
	{
		let config = DebouncedTextViewConfiguration(
			placeholder: placeholder,
			debounceDuration: debounceDuration,
			revertOnExit: revertOnExit,
			autoFocus: autoFocus
		)
		_manager = State(
			wrappedValue: DebouncedTextFieldManager(
				value: value.wrappedValue,
				config: config
			)
		)
		_value = value
		self.config = config
	}

	public init(value: Binding<String>, config: DebouncedTextViewConfiguration) {
		_manager = State(
			wrappedValue: DebouncedTextFieldManager(
				value: value.wrappedValue,
				config: config
			)
		)
		_value = value
		self.config = config
	}

	// MARK: - Body

	public var body: some View {
		TextField(config.placeholder, text: $manager.internalValue, axis: .vertical)
			.lineLimit(1 ... 30)
			.focused($focusState)
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
			.layoutPriority(5)
			.onChange(of: manager.internalValue) { oldValue, newValue in
				guard oldValue != newValue else { return }
				manager.internalValueChanged(to: newValue)
			}
			.onChange(of: focusState) { oldValue, newValue in
				guard oldValue != newValue else { return }
				manager.focusChanged(isFocused: newValue)
			}
			.onChange(of: value) { oldValue, newValue in
				guard oldValue != newValue else { return }
				manager.externalValueChanged(to: newValue)
			}
			.onChange(of: manager.value) { oldValue, newValue in
				guard oldValue != newValue else { return }
				if value != newValue {
					value = newValue
				}
			}
	}
}

@MainActor
@Observable
final class DebouncedTextFieldManager {
	private let config: DebouncedTextViewConfiguration

	var value: String
	var internalValue: String
	var initialValue: String
	private var debounceTask: Task<Void, Never>?

	init(value: String, config: DebouncedTextViewConfiguration) {
		self.config = config
		self.value = value
		internalValue = value
		initialValue = value
	}

	// MARK: - Event Handlers

	func externalValueChanged(to newValue: String) {
		debounceTask?.cancel()
		if internalValue != newValue {
			internalValue = newValue
		}
	}

	func internalValueChanged(to newValue: String) {
		debounceTask?.cancel()
		debounceTask = Task { [weak self] in
			guard let self else { return }
			try? await Task.sleep(for: config.debounceDuration)
			guard !Task.isCancelled else { return }
			value = newValue
		}
	}

	func focusChanged(isFocused: Bool) {
		debounceTask?.cancel()
		debounceTask = nil
		if !isFocused {
			if config.revertOnExit, internalValue != initialValue {
				internalValue = initialValue
				value = initialValue
			}
		}
	}

	deinit {
		MainActor.assumeIsolated {
			debounceTask?.cancel()
			debounceTask = nil
		}
		log("deinit")
	}
}
