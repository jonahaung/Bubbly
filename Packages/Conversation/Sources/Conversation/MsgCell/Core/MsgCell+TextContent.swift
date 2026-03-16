//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import XUI
import Services

extension MsgCell {

	struct TextContent: View {

		@Environment(MsgCellViewModel.self) private var viewModel
		private var state: MsgCellViewModel.State { viewModel.state }

		var body: some View {
			if let text = state.text {
				Group {
					if state.containsMarkdown {
						Text(
							DefaultMarkdownFormatter()
								.format(
									text,
									attributes: .init(),
									layoutDirection: .leftToRight
								)
						)
					} else {
						Text(text)
					}
				}
				.fixedSize(horizontal: false, vertical: true)
			}
		}
	}
}

extension String {
	var containsTallMarksOrEmoji: Bool {
		for character in self {
			for scalar in character.unicodeScalars {
				if scalar.properties.generalCategory == .nonspacingMark { return true }
				if scalar.properties.isEmojiPresentation { return true }
			}
		}
		return false
	}
}
/// Converts markdown string to AttributedString with styling attributes.
open class DefaultMarkdownFormatter {

	let fonts = Fonts()

	private let markdownParser: Markdown

	public init() {
		markdownParser = Markdown()
	}

	@available(iOS 15, *)
	open func format(
		_ string: String,
		attributes: AttributeContainer,
		layoutDirection: LayoutDirection
	) -> AttributedString {
		do {
			return try markdownParser.style(
				markdown: string,
				options: Markdown.ParsingOptions(layoutDirectionLeftToRight: layoutDirection == .leftToRight),
				attributes: attributes,
				inlinePresentationIntentAttributes: inlinePresentationIntentAttributes(for:),
				presentationIntentAttributes: presentationIntentAttributes(for:in:)
			)
		} catch {

			return AttributedString(string, attributes: attributes)
		}
	}

	// MARK: - Styling Attributes

	@available(iOS 15, *)
	private func inlinePresentationIntentAttributes(
		for inlinePresentationIntent: InlinePresentationIntent
	) -> AttributeContainer? {
		nil // use default attributes
	}

	@available(iOS 15, *)
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
				.font(fonts.body)
		case let .header(level):
			let font: Font = {
				switch level {
				case 1:
					return fonts.title
				case 2:
					return fonts.title2
				case 3:
					return fonts.title3
				case 4:
					return fonts.headline
				case 5:
					return fonts.subheadline
				default:
					return fonts.footnote
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
