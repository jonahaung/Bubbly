import SwiftUI

public struct MarkdownFormatter {

	let attributes: AttributeContainer = {
		var container = AttributeContainer()
		container.font = .system(size: UIFont.preferredFont(forTextStyle: .body).pointSize)
		container.lineHeight = .multiple(factor: 1.2)
		return container
	}()

	let font: Font = .system(size: UIFont.preferredFont(forTextStyle: .body).pointSize)

	private let markdownParser: Markdown

	public init() {
		markdownParser = Markdown()
	}

	public func format(
		_ string: String,
		layoutDirection: LayoutDirection = .leftToRight
	) -> AttributedString {
		do {
			return try markdownParser.style(
				markdown: string,
				options: Markdown.ParsingOptions(
					layoutDirectionLeftToRight: layoutDirection == .leftToRight
				),
				attributes: attributes,
				inlinePresentationIntentAttributes: inlinePresentationIntentAttributes(for:),
				presentationIntentAttributes: presentationIntentAttributes(for:in:)
			)
		} catch {

			return AttributedString(string, attributes: attributes)
		}
	}

	private func inlinePresentationIntentAttributes(
		for inlinePresentationIntent: InlinePresentationIntent
	) -> AttributeContainer? {
		nil
	}

	private func presentationIntentAttributes(
		for presentationKind: PresentationIntent.Kind,
		in presentationIntent: PresentationIntent
	) -> AttributeContainer? {
		switch presentationKind {
		case .blockQuote:
			return AttributeContainer()
				.foregroundColor(Color.secondary)
		case .codeBlock:
			return AttributeContainer()
				.font(font)
		case .header(let level):
			let font: Font = {
				switch level {
				case 1:
					return .title
				case 2:
					return .title2
				case 3:
					return .title3
				case 4:
					return .headline
				case 5:
					return .subheadline
				default:
					return .footnote
				}
			}()
			let foregroundColor: Color? = level >= 6 ? Color.secondary : nil
			if let foregroundColor {
				return AttributeContainer()
					.font(font)
					.foregroundColor(foregroundColor)
			} else {
				return AttributeContainer()
					.font(font)
			}
		default:
			return nil
		}
	}
}
