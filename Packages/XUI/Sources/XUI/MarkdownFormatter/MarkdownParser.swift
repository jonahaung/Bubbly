//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public struct Markdown {

	// MARK: Lifecycle

	public init() {}

	// MARK: Public

	public func style(
		markdown: String,
		options: ParsingOptions = .init(),
		attributes base: AttributeContainer,
		inline inlineProvider: (InlinePresentationIntent) -> AttributeContainer?,
		block blockProvider: (PresentationIntent.Kind, PresentationIntent) -> AttributeContainer?,
	) throws -> AttributedString {

		var attributedString = try AttributedString(
			markdown: markdown,
			options: .init(
				allowsExtendedAttributes: true,
				interpretedSyntax: .full,
				failurePolicy: .returnPartiallyParsedIfPossible,
				appliesSourcePositionAttributes: true
			),
		)

		guard attributedString.containsMarkdown() else {
			return attributedString
		}
		attributedString.trimNewlines()
		processInline(&attributedString, base: base, provider: inlineProvider)
		processBlocks(&attributedString, base: base, options: options, provider: blockProvider)
		return fixLinks(attributedString)
	}
}

// MARK: - Inline

private extension Markdown {

	func processInline(
		_ a: inout AttributedString,
		base: AttributeContainer,
		provider: (InlinePresentationIntent) -> AttributeContainer?,
	) {
		for (intent, r) in a.runs[\.inlinePresentationIntent].reversed() {
			guard let intent else {
				continue
			}

			if let attrs = provider(intent) {
				a[r].mergeAttributes(attrs)
			}

			switch intent {
			case .lineBreak: replace(&a, r, "\n", base)
			case .inlineHTML where String(a[r].characters) == "<br/>":
				replace(&a, r, "\n", base)
			default: break
			}
		}
	}

	func replace(
		_ a: inout AttributedString,
		_ r: Range<AttributedString.Index>,
		_ s: String,
		_ base: AttributeContainer,
	) {
		a.replaceSubrange(r, with: AttributedString(s, attributes: base))
	}
}

// MARK: - Blocks

private extension Markdown {

	func processBlocks(
		_ a: inout AttributedString,
		base: AttributeContainer,
		options: ParsingOptions,
		provider: (PresentationIntent.Kind, PresentationIntent) -> AttributeContainer?,
	) {
		var prev: Style?
		var inserts = [(AttributedString.Index, AttributedString)]()

		for (intent, r) in a.runs[\.presentationIntent].reversed() {
			guard let intent else {
				continue
			}

			var s = Style(range: r, components: intent.components)
			configure(intent, &s, provider)

			a[r].replaceAttributes(.init().presentationIntent(intent), with: .init())

			space(&s, prev)

			if let attrs = s.attrs {
				a[s.range].mergeAttributes(attrs)
			}

			if let prev, s.trailing > 0 {
				inserts.append((prev.range.lowerBound, nl(s.trailing, base)))
			}

			if !s.prefix.isEmpty {
				let text = options.layoutDirectionLeftToRight ? s
					.prefix : String(s.prefix.reversed())
				inserts.append((
					s.range.lowerBound,
					AttributedString(text, attributes: base.merging(s.attrs ?? .init())),
				))
			}

			if s.leading > 0, a.startIndex != s.range.lowerBound {
				inserts.append((s.range.lowerBound, nl(s.leading, base)))
			}

			prev = s
		}

		for (i, v) in inserts.sorted(by: { $0.0 > $1.0 }) {
			a.insert(v, at: i)
		}
	}

	func configure(
		_ intent: PresentationIntent,
		_ s: inout Style,
		_ provider: (PresentationIntent.Kind, PresentationIntent) -> AttributeContainer?,
	) {
		for c in s.components {
			switch c.kind {

			case .blockQuote:
				s.quote = c.identity
				s.attrs = provider(c.kind, intent)
				s.prefix = "┃ "

			case .codeBlock:
				s.attrs = provider(c.kind, intent)
				s.leading += 1

			case .header:
				s.attrs = provider(c.kind, intent)
				s.leading += 1; s.trailing += 1

			case .paragraph:
				s.paragraph = c.identity

			case let .listItem(n):
				if s.ordinal == nil {
					s.ordinal = n
					s.attrs = provider(c.kind, intent)
				}

			case .orderedList:
				s.list = c.identity
				s.ordered = s.ordered ?? true

			case .unorderedList:
				s.list = c.identity
				s.ordered = s.ordered ?? false

			default: break
			}
		}
	}

	func space(_ s: inout Style, _ p: Style?) {

		if s.paragraph != p?.paragraph {
			s.trailing += 1
			if s.isOnlyParagraph, p?.isOnlyParagraph == true {
				s.trailing += 1
			}
		}

		switch (s.quote, p?.quote) {
		case let (.some(a), .some(b)) where a != b: s.trailing += 1
		case (.none, .some),
		     (.some, .none): s.trailing += 1
		default: break
		}

		if let n = s.ordinal {
			s.prefix += (s.ordered == true ? "\(n)." : "•") + "\t"
			if p?.list != s.list {
				s.trailing += 1
			}
		} else if p?.list != nil {
			s.trailing += 1
		}
	}

	func nl(_ count: Int, _ base: AttributeContainer) -> AttributedString {
		AttributedString(String(repeating: "\n", count: count), attributes: base)
	}
}

// MARK: - Links

private extension Markdown {
	func fixLinks(_ a: AttributedString) -> AttributedString {
		a.transformingAttributes(\.link) {
			guard let u = $0.value, u.scheme == nil, u.host == nil else {
				return
			}
			$0.value = URL(string: "https://" + u.absoluteString)
		}
	}
}

// MARK: - Options

public extension Markdown {
	struct ParsingOptions {

		// MARK: Lifecycle

		public init(layoutDirectionLeftToRight: Bool = true) {
			self.layoutDirectionLeftToRight = layoutDirectionLeftToRight
		}

		// MARK: Public

		public var layoutDirectionLeftToRight = true
	}
}

// MARK: - AttributedString Helpers

private extension AttributedString {

	func containsMarkdown() -> Bool {
		runs.contains {
			$0.inlinePresentationIntent != nil ||
				$0.presentationIntent != nil ||
				$0.link != nil
		}
	}

	func isInsideCodeBlock(_ r: Range<Index>) -> Bool {
		runs[\.presentationIntent].contains { intent, range in
			guard let intent, range.overlaps(r) else {
				return false
			}
			return intent.components
				.contains { if case .codeBlock = $0.kind {
					true
				} else {
					false
				} }
		}
	}

	mutating func trimNewlines() {
		guard let s = characters.firstIndex(where: { !$0.isNewline }),
		      let e = characters.lastIndex(where: { !$0.isNewline })
		else {
			return
		}
		self = AttributedString(self[s ... e])
	}
}

// MARK: - Style Model

private struct Style {

	let range: Range<AttributedString.Index>
	let components: [PresentationIntent.IntentType]

	var paragraph: Int?
	var quote: Int?
	var list: Int?

	var ordinal: Int?
	var ordered: Bool?

	var leading = 0
	var trailing = 0

	var attrs: AttributeContainer?
	var prefix = ""

	var isOnlyParagraph: Bool {
		components.count == 1 && components.allSatisfy { $0.kind == .paragraph }
	}
}
