//  InputText.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database

// MARK: - InputTextDelegate

@MainActor
protocol InputTextDelegate: AnyObject {
    func inputText(_ inputText: InputText, didBeganEditing text: String)
    func inputText(_ inputText: InputText, didInsertLinks links: [ExtractedLink])
}

// MARK: - InputText

@MainActor
@Observable
final class InputText {
    var text: String = .init()
    var bindableText: Binding<String> {
        .init(
            get: { self.text },
            set: { newValue in
                let oldValue = self.text
                self.text = newValue
                guard oldValue != newValue else {
                    return
                }

                self.delegate?.inputText(self, didBeganEditing: newValue)
                self.parseLinks(newValue)
            }
        )
    }

    func set(text: String) {
        bindableText.wrappedValue = text
        selectAll()
    }

    var selection: TextSelection?
    var hasText: Bool {
        !text.isWhitespace
    }

    @ObservationIgnored weak var delegate: InputTextDelegate?
    @ObservationIgnored private let linkWorker: LinkExtractorWorker = .init()

    func clear() {
        selection = nil
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
        guard currentText.isWhitespace == false, currentText.contains("://") else {
            return
        }

        Task {
            let thisText = string
            let links = await linkWorker.extractLinks(from: thisText)
            guard links.isEmpty == false else {
                return
            }

            guard thisText.contains(thisText) else {
                return
            }

            delegate?.inputText(self, didInsertLinks: links)
        }
    }
}

// MARK: - LinkExtractorWorker

private actor LinkExtractorWorker {
    func extractLinks(from text: String) -> [ExtractedLink] {
        LinkExtractor.extractLinks(from: text)
    }
}
