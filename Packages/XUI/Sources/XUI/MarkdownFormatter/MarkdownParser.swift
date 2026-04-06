//
//  Markdown.swift
//  XUI
//
//  Created by Aung Ko Min on 7/3/26.
//

import Foundation

/// A parser for markdown which generates a styled attributed string.
public struct Markdown {

	// MARK: - Initialization

	public init() {}

	// MARK: - Public Methods

	/// Creates an attributed string from a Markdown-formatted string using the provided style attributes.
	///
	/// Apple's markdown initialiser parses markdown and adds ``NSPresentationIntent`` and ``NSInlinePresentationIntent``
	/// attributes without any styling or newline handling. All styling attributes (font, foregroundColor, etc.)
	/// and newline handling must be implemented separately.
	///
	/// UIKit and SwiftUI support different ``AttributedString`` attributes (see ``AttributeScopes.SwiftUIAttributes``,
	/// ``AttributeScopes.UIKitAttributes``, and ``AttributeScopes.FoundationAttributes``). The latter is shared by both.
	/// Therefore, we need additional parsing for presentation intent attributes and add respective style related attributes.
	///
	/// - Note: Here's an example of a nested list showing why this handling is necessary:
	/// ```
	/// List item 1 {
	///     NSPresentationIntent = [paragraph (id 3), listItem 1 (id 2), unorderedList (id 1)]
	/// }
	/// Nested item which is very very long and keeps going until it is wrapped {
	///    NSPresentationIntent = [paragraph (id 6), listItem 1 (id 5), unorderedList (id 4), listItem 1 (id 2), unorderedList (id 1)]
	/// }
	/// ```
	///
	/// - Parameters:
	///   - markdown: The string that contains the Markdown formatting.
	///   - options: Options that affect how the Markdown string is parsed and styled.
	///   - attributes: The attributes to use for the whole string.
	///   - inlinePresentationIntentAttributes: Closure for customising attributes for inline presentation intents.
	///   - presentationIntentAttributes: Closure for customising attributes for presentation intents (quote, code, list item, headers).
	/// - Returns: A styled attributed string.
	/// - Throws: An error if the markdown parsing fails.
	public func style(
		markdown: String,
		options: ParsingOptions,
		attributes: AttributeContainer,
		inlinePresentationIntentAttributes: (InlinePresentationIntent) -> AttributeContainer?,
		presentationIntentAttributes: (PresentationIntent.Kind, PresentationIntent) -> AttributeContainer?
	) throws -> AttributedString {
		var attributedString = try parseMarkdown(markdown)

		// Handle plain text without markdown
		guard attributedString.containsMarkdown() else {
			return AttributedString(markdown, attributes: attributes)
		}

		// Apply initial processing
		attributedString.trimNewlines()
		attributedString.mergeAttributes(attributes)

		// Process inline presentation intents
		processInlineIntents(&attributedString, using: inlinePresentationIntentAttributes, baseAttributes: attributes)

		// Process presentation intents
		processPresentationIntents(&attributedString, using: presentationIntentAttributes, options: options, baseAttributes: attributes)

		// Fix links without schemes
		attributedString = fixLinkSchemes(attributedString)

		return attributedString
	}

	// MARK: - Private Methods

	private func parseMarkdown(_ markdown: String) throws -> AttributedString {
		return try AttributedString(
			markdown: markdown,
			options: AttributedString.MarkdownParsingOptions(
				allowsExtendedAttributes: true,
				interpretedSyntax: .full,
				failurePolicy: .returnPartiallyParsedIfPossible,
				languageCode: nil
			)
		)
	}

	private func processInlineIntents(
		_ attributedString: inout AttributedString,
		using attributesProvider: (InlinePresentationIntent) -> AttributeContainer?,
		baseAttributes: AttributeContainer
	) {
		for (inlinePresentationIntent, range) in attributedString.runs[\.inlinePresentationIntent].reversed() {
			guard let inlinePresentationIntent else { continue }

			// Apply custom attributes
			if let attributes = attributesProvider(inlinePresentationIntent) {
				attributedString[range].mergeAttributes(attributes)
			}

			// Handle specific inline intents
			switch inlinePresentationIntent {
			case .lineBreak:
				replaceWithNewline(&attributedString, at: range, attributes: baseAttributes)
			case .inlineHTML:
				handleInlineHTML(&attributedString, at: range, attributes: baseAttributes)
			default:
				break
			}
		}
	}

	private func processPresentationIntents(
		_ attributedString: inout AttributedString,
		using attributesProvider: (PresentationIntent.Kind, PresentationIntent) -> AttributeContainer?,
		options: ParsingOptions,
		baseAttributes: AttributeContainer
	) {
		var previousStyling: PresentationIntentStyling?

		for (presentationIntent, range) in attributedString.runs[\.presentationIntent].reversed() {
			guard let presentationIntent else { continue }

			var styling = PresentationIntentStyling(
				range: range,
				components: presentationIntent.components
			)

			// Process each intent component
			processIntentComponents(presentationIntent, &styling, using: attributesProvider)

			// Remove the presentation intent attribute
			attributedString[range].replaceAttributes(
				AttributeContainer().presentationIntent(presentationIntent),
				with: AttributeContainer()
			)

			// Apply spacing rules
			applySpacingRules(&styling, previousStyling: previousStyling)

			// Apply styling modifications
			applyStylingModifications(&attributedString, styling: styling, previousStyling: previousStyling, options: options, baseAttributes: baseAttributes)

			previousStyling = styling
		}
	}

	private func processIntentComponents(
		_ presentationIntent: PresentationIntent,
		_ styling: inout PresentationIntentStyling,
		using attributesProvider: (PresentationIntent.Kind, PresentationIntent) -> AttributeContainer?
	) {
		for intentType in styling.components {
			switch intentType.kind {
			case .blockQuote:
				styling.quoteBlockId = intentType.identity
				styling.mergedAttributes = attributesProvider(intentType.kind, presentationIntent)
				styling.prependedString = "\u{2503}"

			case .codeBlock:
				styling.mergedAttributes = attributesProvider(intentType.kind, presentationIntent)
				styling.precedingNewlineCount += 1

			case .header:
				styling.mergedAttributes = attributesProvider(intentType.kind, presentationIntent)
				styling.precedingNewlineCount += 1
				styling.succeedingNewlineCount += 1

			case .paragraph:
				styling.paragraphId = intentType.identity

			case .listItem(ordinal: let ordinal):
				if styling.listItemOrdinal == nil {
					styling.listItemOrdinal = ordinal
					styling.mergedAttributes = attributesProvider(intentType.kind, presentationIntent)
				}

			case .orderedList:
				styling.listId = intentType.identity
				if styling.isOrdered == nil {
					styling.isOrdered = true
				} else {
					styling.prependedString.insert("\t", at: styling.prependedString.startIndex)
				}

			case .unorderedList:
				styling.listId = intentType.identity
				if styling.isOrdered == nil {
					styling.isOrdered = false
				} else {
					styling.prependedString.insert("\t", at: styling.prependedString.startIndex)
				}

			default:
				break
			}
		}
	}

	private func applySpacingRules(_ styling: inout PresentationIntentStyling, previousStyling: PresentationIntentStyling?) {
		// Paragraph spacing
		if styling.paragraphId != previousStyling?.paragraphId {
			styling.succeedingNewlineCount += 1
			if styling.isOnlyParagraph && previousStyling?.isOnlyParagraph == true {
				styling.succeedingNewlineCount += 1
			}
		}

		// Quote spacing
		switch (styling.quoteBlockId, previousStyling?.quoteBlockId) {
		case (.some(let current), .some(let previous)):
			styling.succeedingNewlineCount += current != previous ? 1 : 0
		case (.some, .none), (.none, .some):
			styling.succeedingNewlineCount += 1
		default:
			break
		}

		// List item preparation
		if let listItemOrdinal = styling.listItemOrdinal {
			if styling.isOrdered == true {
				styling.prependedString.append("\(listItemOrdinal).  ")
			} else {
				styling.prependedString.append("\u{2022}  ")
			}

			if previousStyling?.listId != styling.listId {
				styling.succeedingNewlineCount += 1
			}
		} else if previousStyling?.listId != nil {
			styling.succeedingNewlineCount += 1
		}
	}

	private func applyStylingModifications(
		_ attributedString: inout AttributedString,
		styling: PresentationIntentStyling,
		previousStyling: PresentationIntentStyling?,
		options: ParsingOptions,
		baseAttributes: AttributeContainer
	) {
		// Insert succeeding newlines
		if styling.succeedingNewlineCount > 0, let previousStyling {
			let newlineString = String(repeating: "\n", count: styling.succeedingNewlineCount)
			let insertedString = AttributedString(newlineString, attributes: baseAttributes)
			attributedString.insertSafely(insertedString, at: previousStyling.range.lowerBound)
		}

		// Apply merged attributes
		if let attributes = styling.mergedAttributes {
			attributedString[styling.range].mergeAttributes(attributes)
		}

		// Insert prepended characters (bullets, numbers, etc.)
		if !styling.prependedString.isEmpty {
			let attributes = baseAttributes.merging(styling.mergedAttributes ?? AttributeContainer())
			let insertedString = AttributedString(
				options.layoutDirectionLeftToRight ? styling.prependedString : String(styling.prependedString.reversed()),
				attributes: attributes
			)
			attributedString.insertSafely(insertedString, at: styling.range.lowerBound)
		}

		// Insert preceding newlines
		if styling.precedingNewlineCount > 0, attributedString.startIndex != styling.range.lowerBound {
			let newlineString = String(repeating: "\n", count: styling.precedingNewlineCount)
			let insertedString = AttributedString(newlineString, attributes: baseAttributes)
			attributedString.insertSafely(insertedString, at: styling.range.lowerBound)
		}
	}

	private func replaceWithNewline(_ attributedString: inout AttributedString, at range: Range<AttributedString.Index>, attributes: AttributeContainer) {
		let newlineString = AttributedString("\n", attributes: attributes)
		attributedString.replaceSubrange(range, with: newlineString)
	}

	private func handleInlineHTML(_ attributedString: inout AttributedString, at range: Range<AttributedString.Index>, attributes: AttributeContainer) {
		if String(attributedString[range].characters) == "<br/>" {
			let newlineString = AttributedString("\n", attributes: attributes)
			attributedString.replaceSubrange(range, with: newlineString)
		}
	}

	private func fixLinkSchemes(_ attributedString: AttributedString) -> AttributedString {
		return attributedString.transformingAttributes(\.link) { attribute in
			guard let url = attribute.value,
				  url.scheme == nil,
				  url.host == nil else { return }

			let urlString = "https://" + url.absoluteString
			guard let urlWithScheme = URL(string: urlString) else { return }
			attribute.value = urlWithScheme
		}
	}
}

// MARK: - Supporting Types

extension Markdown {
	/// Options that affect how the Markdown string is parsed and styled.
	public struct ParsingOptions {
		public init(layoutDirectionLeftToRight: Bool = true) {
			self.layoutDirectionLeftToRight = layoutDirectionLeftToRight
		}

		/// Affects insertion index for additional characters like bullets and numbers for lists.
		public var layoutDirectionLeftToRight = true
	}
}

// MARK: - Private Extensions

private extension AttributedString {
	/// Returns true if the attributed string contains markdown formatting.
	///
	/// - Note: Use only after creating the attributed string with the markdown initializer.
	func containsMarkdown() -> Bool {
		let containsInlineIntents = runs[\.inlinePresentationIntent].contains(where: { inlineIntent, _ in
			switch inlineIntent {
			case .none, .some(.softBreak):
				return false
			default:
				return true
			}
		})
		if containsInlineIntents {
			return true
		}
		let containsPresentationIntents = runs[\.presentationIntent].contains(where: { intent, _ in
			switch intent {
			case .none:
				return false
			case .some(let intent):
				// Regular text gets paragraphs
				return !intent.components.allSatisfy { $0.kind == .paragraph }
			}
		})
		if containsPresentationIntents {
			return true
		}
		// Markdown links get the same link attribute
		return runs[\.link].contains(where: { link, _ in link != nil })
	}

	mutating func insertSafely(_ string: some AttributedStringProtocol, at index: AttributedString.Index) {
		guard index >= startIndex && index <= endIndex else { return }
		insert(string, at: index)
	}

	mutating func trimNewlines() {
		// Trim leading newlines
		let firstValidIndex = characters.firstIndex { !$0.isNewline }
		if let firstValidIndex, firstValidIndex != startIndex {
			self = AttributedString(self[firstValidIndex...])
		}

		// Trim trailing newlines
		let lastValidIndex = characters.lastIndex { !$0.isNewline }
		if let lastValidIndex, lastValidIndex < index(beforeCharacter: endIndex) {
			self = AttributedString(self[...lastValidIndex])
		}
	}
}

// MARK: - Private Helper Structures

private struct PresentationIntentStyling {
	// MARK: - Properties

	let range: Range<AttributedString.Index>
	let components: [PresentationIntent.IntentType]

	var paragraphId: Int?
	var quoteBlockId: Int?
	var precedingNewlineCount = 0
	var succeedingNewlineCount = 0
	var mergedAttributes: AttributeContainer?
	var prependedString = ""
	var listItemOrdinal: Int?
	var listId: Int?
	var isOrdered: Bool?

	// MARK: - Computed Properties

	var isOnlyParagraph: Bool {
		components.count == 1 && components.allSatisfy { $0.kind == .paragraph }
	}
}
