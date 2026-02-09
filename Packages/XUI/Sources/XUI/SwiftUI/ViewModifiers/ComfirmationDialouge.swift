//
//  ComfirmationDialouge.swift
//  RoomRentalDemo
//
//  Created by Aung Ko Min on 19/1/23.
//

import SwiftUI

private struct XDialogModifier<DialogContent: View>: ViewModifier {
	let title: String
	let message: String
	@ViewBuilder var dialogContent: () -> DialogContent
	@State private var isShown = false

	func body(content: Content) -> some View {
		Button {
			isShown = true
		} label: {
			content
		}
		.confirmationDialog(
			.init(title),
			isPresented: $isShown,
			titleVisibility: .visible,
			actions: { dialogContent() },
			message: { Text(.init(message)) }
		)
	}
}

public extension View {
	/// Lint-compliant and corrected spelling
	func confirmationDialogue(_ title: String = "Attention",
	                          message: String = "",
	                          @ViewBuilder actions: @escaping () -> some View) -> some View
	{
		ModifiedContent(
			content: self,
			modifier: XDialogModifier(title: title, message: message, dialogContent: actions)
		)
	}

	/// Deprecated shim to preserve old callers
	@available(*, deprecated, renamed: "confirmationDialogue(_:message:actions:)")
	func _comfirmationDialouge(_ title: String = "Attention",
	                           message: String = "",
	                           @ViewBuilder _ content: @escaping () -> some View) -> some View
	{
		confirmationDialogue(title, message: message, actions: content)
	}
}
