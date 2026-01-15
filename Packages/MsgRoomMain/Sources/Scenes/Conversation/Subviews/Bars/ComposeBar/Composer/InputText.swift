//
//  InputText.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 1/12/25.
//

import SwiftUI
import XUI
import Database

@MainActor
protocol InputTextDelegate: AnyObject {
	func inputText(_ inputText: InputText, didBeganEditing text: String)
	func inputText(_ inputText: InputText, didInsertLinks links: [ExtractedLink])
}
@MainActor
@Observable
final class InputText: Identifiable {

	let id = Date.now.formatted()
	var text: String = String() {
		willSet {
			let oldValue = self.text
			let diff = newValue.count - oldValue.count
			switch true {
			case diff == 1 && oldValue.isEmpty:
				delegate?.inputText(self, didBeganEditing: newValue)
			case diff > 3:
				parseLinks(newValue)
			default:
				break
			}
		}
	}

	var hasText: Bool { !text.isWhitespace }

	@ObservationIgnored private var linkExtractionTask: Task<Void, Never>?

	weak var delegate: InputTextDelegate?

	func clear() {
		linkExtractionTask?.cancel()
		text = .init()
	}

	private func parseLinks(_ string: String) {
		let currentText = string.trimmed

		linkExtractionTask?.cancel()
		guard currentText.isWhitespace == false else {
			return
		}
		linkExtractionTask = Task.detached(name: currentText, priority: .userInitiated) { [weak self] in
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
}
