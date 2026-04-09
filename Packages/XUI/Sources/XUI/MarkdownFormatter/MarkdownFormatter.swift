import SwiftUI
public struct GitHubMarkdownStyle {

	public init() {}

	// MARK: - Base

	public let base = AttributeContainer.base

	// MARK: - Inline

	public func inline(_ intent: InlinePresentationIntent) -> AttributeContainer? {
		var container = AttributeContainer()

		switch intent {

		case .code:
			container.font =
				.system(size: UIFont.labelFontSize-1, weight: .regular, design: .monospaced)
				.width(.condensed)
			container.foregroundColor = Color(.secondaryLabel)
		case .emphasized:
			container.font = .system(size: UIFont.labelFontSize)
		case .stronglyEmphasized:
			container.font = .system(size: UIFont.labelFontSize, weight: .medium)
		case .strikethrough:
			container.strikethroughStyle = .single
		case .inlineHTML:
			container.font = .system(size: UIFont.labelFontSize, design: .serif)
		default:
			return nil
		}

		return container
	}

	// MARK: - Block

	public func block(
		_ kind: PresentationIntent.Kind,
		_ intent: PresentationIntent
	) -> AttributeContainer? {

		var container = base

		switch kind {

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
					return .subheadline
				}
			}()
			let foregroundColor: Color? = level >= 6 ? Color.secondary : nil
			if let foregroundColor {
				return container
					.font(font)
					.foregroundColor(foregroundColor)
			} else {
				container.lineHeight = .tight
				return container.font(font)
			}
		case .codeBlock, .blockQuote, .orderedList, .unorderedList:
			container.font =
				.system(size: UIFont.labelFontSize - 1)
			container.lineHeight = .loose
		default:
			return container
		}
		return container
	}
}
public struct MarkdownFormatter {
	private let markdownParser: Markdown

	public init() {
		markdownParser = Markdown()
	}

	public func format(
		_ string: String,
		layoutDirection: LayoutDirection = .leftToRight
	) -> AttributedString {
		let style = GitHubMarkdownStyle()
		do {
			return try markdownParser.style(
				markdown: string,
				options: Markdown.ParsingOptions(
					layoutDirectionLeftToRight: layoutDirection == .leftToRight
				),
				attributes: style.base,
				inline: style.inline(_:),
				block: style.block(_:_:)
			)
		} catch {
			return AttributedString(string, attributes: style.base)
		}
	}
}

extension AttributeContainer {
	public static let base: AttributeContainer = {
		var container = AttributeContainer()
		container.font = .system(size: UIFont.labelFontSize).leading(.tight)
		container.lineHeight = .multiple(factor: 1.3)
		container.foregroundColor = Color.label
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineBreakMode = .byWordWrapping
		paragraphStyle.lineSpacing = 0
		paragraphStyle.lineBreakStrategy = .hangulWordPriority
		paragraphStyle.allowsDefaultTighteningForTruncation = true
		paragraphStyle.lineHeightMultiple = 1.3
		container.paragraphStyle = paragraphStyle
		return container
	}()
}
