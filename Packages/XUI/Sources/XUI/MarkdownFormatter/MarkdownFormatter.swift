import SwiftUI

public struct MarkdownFormatter {

	let attributes: AttributeContainer = {
		var container = AttributeContainer()
		container.font = .system(size: UIFont.preferredFont(forTextStyle: .body).pointSize)
		container.lineHeight = .multiple(factor: 1.2)
		var paragraph = NSMutableParagraphStyle()
		paragraph.lineBreakMode = .byWordWrapping
		paragraph.lineSpacing = 0
		paragraph.paragraphSpacing = 0
		container.paragraphStyle = paragraph
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
			var container = AttributeContainer()
			container.font =
				.system(
					size: UIFont.preferredFont(forTextStyle: .callout).pointSize,
					weight: .regular, design: .serif
				).italic()
				.leading(.tight)
			return container
		case .codeBlock:
			var container = AttributeContainer()
			container.font =
				.system(
					size: UIFont.preferredFont(forTextStyle: .caption1).pointSize,
					weight: .medium, design: .monospaced
				)
				.width(.condensed)
				.leading(.tight)

			return container
		case .header(let level):
			let font: Font = {
				switch level {
				case 1:
					return .system(
						size: UIFont.preferredFont(forTextStyle: .title1).pointSize,
						weight: .semibold
					)
				case 2:
					return .system(
						size: UIFont.preferredFont(forTextStyle: .title2).pointSize,
						weight: .semibold
					)
				case 3:
					return .system(
						size: UIFont.preferredFont(forTextStyle: .title3).pointSize,
						weight: .semibold
					)
				case 4:
					return .system(
						size: UIFont.preferredFont(forTextStyle: .headline).pointSize,
						weight: .medium
					)
				case 5:
					return .system(
						size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize,
						weight: .regular
					)
				default:
					return .footnote
				}
			}()
			let foregroundColor: Color? = level >= 6 ? Color.secondary : nil
			if let foregroundColor {
				return attributes
					.font(font)
					.foregroundColor(foregroundColor)
			} else {
				return attributes
					.font(font)
			}
		default:
			return nil
		}
	}
}
