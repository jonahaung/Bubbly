import SwiftUI

public extension TextField where Label == Text {
	init(_ title: LocalizedStringKey,
	     text: Binding<String>,
	     isEditing: Binding<Bool>,
	     onCommit: @escaping () -> Void = {})
	{
		self.init(
			title,
			text: text,
			onEditingChanged: { isEditing.wrappedValue = $0 },
			onCommit: onCommit
		)
	}

	init(_ title: LocalizedStringKey,
	     text: Binding<String?>,
	     onEditingChanged: @escaping (Bool) -> Void = { _ in },
	     onCommit: @escaping () -> Void = {})
	{
		let nonOptional = Binding<String>(
			get: { text.wrappedValue ?? "" },
			set: { newValue in
				// Write back to the optional binding. Map empty string to nil.
				text.wrappedValue = newValue.isEmpty ? nil : newValue
			}
		)
		self.init(
			title,
			text: nonOptional,
			onEditingChanged: onEditingChanged,
			onCommit: onCommit
		)
	}

	init(_ title: LocalizedStringKey,
	     text: Binding<String?>,
	     isEditing: Binding<Bool>,
	     onCommit: @escaping () -> Void = {})
	{
		let nonOptional = Binding<String>(
			get: { text.wrappedValue ?? "" },
			set: { newValue in
				text.wrappedValue = newValue.isEmpty ? nil : newValue
			}
		)
		self.init(
			title,
			text: nonOptional,
			onEditingChanged: { isEditing.wrappedValue = $0 },
			onCommit: onCommit
		)
	}
}
