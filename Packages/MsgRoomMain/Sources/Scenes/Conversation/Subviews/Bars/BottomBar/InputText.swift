//
//  InputText.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 1/12/25.
//

import SwiftUI
import XUI

@MainActor
@Observable
final class InputText: Identifiable {

	var text: String {
		get { editedText }
		set {
			guard editedText != newValue else { return }
			set(newValue)
		}
	}
	var linkPreview: SwiftLinkPreviewResponse?
	var hasText: Bool { text.isWhitespace == false }

	private var editedText: String
	var selection: TextSelection?

	private var linkExtractionTask: Task<Void, Never>?

	init() {
		self.editedText = .init()
	}

	func clear() {
		text = .init()
		linkPreview = nil
	}

	func set(_ string: String) {
		let currentText = string.trimmed
		editedText = currentText

		linkExtractionTask?.cancel()

		linkExtractionTask = Task {
			try? await Task.sleep(seconds: 1)
			guard !Task.isCancelled else { return }

			// If you only want the first URL preview, call preview directly.
			let swiftLinkPreview = SwiftLinkPreview()
			let extracted: SwiftLinkPreviewResponse? = try? await swiftLinkPreview.preview(currentText)

			await MainActor.run {
				// Ensure we’re still on the same text
				if self.text == currentText.trimmed {
					linkPreview = extracted
				}
			}
		}
	}
}

extension AttributedString {
	var string: String {
		String(characters)
	}
}
