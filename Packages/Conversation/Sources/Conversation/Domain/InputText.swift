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

	var text: String = .init()
	var bindableText: Binding<String> {
		.init(
			get: { self.text },
			set: { newValue in

				let oldValue = self.text
				guard oldValue != newValue else {
					return
				}
				self.text = newValue
				if newValue.isEmpty || oldValue.isEmpty, oldValue != newValue {
					self.delegate?.inputText(self, didBeganEditing: newValue)
				}
				self.parseLinks(newValue)

			}
		)
	}

	private let throttler = Debouncer(interval: .seconds(1))
	var selection: TextSelection?
	var hasText: Bool {
		!text.isWhitespace
	}

	@ObservationIgnored weak var delegate: InputTextDelegate?
	@ObservationIgnored private let linkWorker = LinkExtractorWorker()

	func clear() {
		selection = nil
		text = .init()
	}

	func selectAll() {
		let string = text
		let start = string.startIndex
		let end = string.endIndex
		selection = TextSelection(range: start..<end)
	}

	private func parseLinks(_ string: String) {
		let currentText = string.trimmed
		guard currentText.isWhitespace == false, currentText.contains("://") else {
			return
		}
		Task {
			await throttler.run { [weak self] in
				guard let self else { return }
				let thisText = string
				let links = await linkWorker.extractLinks(from: thisText)
				guard links.isEmpty == false else { return }
				guard thisText.contains(thisText) else { return }
				await MainActor.run { [links] in
					delegate?.inputText(self, didInsertLinks: links)
				}
			}
		}
	}

	nonisolated static func == (lhs: InputText, rhs: InputText) -> Bool {
		lhs.id == rhs.id
	}
}

private actor LinkExtractorWorker {
	func extractLinks(from text: String) -> [ExtractedLink] {
		LinkExtractor.extractLinks(from: text)
	}
}
