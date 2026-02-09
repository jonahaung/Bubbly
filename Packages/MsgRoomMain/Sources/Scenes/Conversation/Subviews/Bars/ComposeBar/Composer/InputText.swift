//
//  InputText.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 1/12/25.
//

import Database
import SwiftUI
import XUI

@MainActor
protocol InputTextDelegate: AnyObject {
	func inputText(_ inputText: InputText, didBeganEditing text: String)
	func inputText(_ inputText: InputText, didInsertLinks links: [ExtractedLink])
}

@MainActor
@Observable
final class InputText: Equatable {
	let id = 0
	var text: String = .init() {
		willSet {
			let oldValue = text
			switch true {
			case (newValue.isEmpty || oldValue.isEmpty) && oldValue != newValue:
				delegate?.inputText(self, didBeganEditing: newValue)
			case newValue.count - oldValue.count > 10:
				parseLinks(newValue)
			default:
				break
			}
		}
	}

	var selection: TextSelection?
	var hasText: Bool {
		!text.isWhitespace
	}

	@ObservationIgnored private var linkExtractionTask: Task<Void, Never>?
	@ObservationIgnored weak var delegate: InputTextDelegate?

	func clear() {
		selection = nil
		linkExtractionTask?.cancel()
		text = .init()
	}

	func selectAll() {
		let string = text
		let start = string.startIndex
		let end = string.endIndex
		selection = TextSelection(range: start ..< end)
	}

	private func parseLinks(_ string: String) {
		let currentText = string.trimmed

		linkExtractionTask?.cancel()
		guard currentText.isWhitespace == false else {
			return
		}
		linkExtractionTask = Task
			.detached(name: currentText, priority: .userInitiated) { [weak self] in
				guard let self else { return }
				let thisText = string
				try? await Task.sleep(seconds: 0.4)
				guard !Task.isCancelled else { return }
				let links = LinkExtractor.extractLinks(from: thisText)
				guard !Task.isCancelled else { return }
				if !links.isEmpty {
					Task { @MainActor in
						guard self.text.contains(thisText) else { return }
						self.delegate?.inputText(self, didInsertLinks: links)
					}
				}
			}
	}

	nonisolated static func == (lhs: InputText, rhs: InputText) -> Bool {
		lhs.id == rhs.id
	}
}
