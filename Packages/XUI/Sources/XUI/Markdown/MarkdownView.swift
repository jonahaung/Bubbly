//
//  MarkdownView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 28/2/25.
//

import SwiftUI

public struct MarkdownView: View {
	let markdownText: String
	let elements: [MarkdownElement]

	public init(markdownText: String) {
		self.markdownText = markdownText
		self.elements = MarkdownParser.parse(markdownText)
	}
	public init(elements: [MarkdownElement], text: String) {
		self.elements = elements
		self.markdownText = text
	}
	public var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			ForEach(Array(elements.enumerated()), id: \.offset) { _, element in
				renderElement(element)
			}
		}
		.allowsTightening(true)
		.compositingGroup()
		.equatable(by: markdownText)
	}

	@ViewBuilder
	private func renderElement(_ element: MarkdownElement) -> some View {
		switch element {
		case .heading(let level, let text):
			HeadingView(level: level, text: text)
				.padding(.top, CGFloat(level))
				.textScale(.secondary)
		case .paragraph(let text):
			ParagraphView(text: text)
		case .codeBlock(let language, let content):
			CodeBlockView(language: language, content: content)
				.textScale(.secondary)
		case .listItem(let text):
			ListItemView(text: text)
		case .blockquote(let text):
			BlockquoteView(text: text)
		case .horizontalRule:
			EmptyView()
		case .unknown(let text):
			Text(text)
				.font(.body)
				.foregroundColor(.gray)
		case .orderedListItem(index: let index, text: let text):
			OrderedListItemView(index: index, text: text)
		case .mention(username: let username):
			Text("@\(username)")
				.font(.system(.subheadline, design: .rounded, weight: .medium))
				.underline()
				.foregroundStyle(Color.indigo)
		case .hashtag(topic: let topic):
			Text("#\(topic)")
				.font(.system(.subheadline, design: .rounded, weight: .medium))
				.underline()
				.foregroundStyle(Color.indigo )
		}
	}
}

// MARK: - Subviews

private struct HeadingView: View {
	let level: Int
	let text: String

	var body: some View {
		switch level {
		case 1:
			Text(text)
				.font(.largeTitle)
				.bold()
		case 2:
			Text(text)
				.font(.title)
				.bold()
		case 3:
			Text(text)
				.font(.title2)
				.bold()
		case 4:
			Text(text)
				.font(.title3)
				.bold()
		default:
			Text(text)
				.font(.headline)
				.bold()
		}
	}
}

private struct ParagraphView: View {
	let text: String

	var body: some View {
		Text(.init(text))
			.font(.body)
			.fixedSize(horizontal: false, vertical: true)
	}
}

private struct CodeBlockView: View {
	let language: String?
	let content: String

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			if let language = language {
				Text(language.capitalized)
					.font(.system(size: 11, weight: .medium, design: .rounded))
					.underline()
			}
			ZStack {
				HStack(spacing: 0) {
					Text(content)
						.font(.system(size: 10, weight: .medium, design: .monospaced))
						.foregroundStyle(.white)

					Spacer()
				}
			}
			.padding(8)
			.padding(.vertical, 8)
			.background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.2)))

		}
		.flexible(.horizontal)
	}
}

private struct ListItemView: View {
	let text: String

	var body: some View {
		Text(.init("✦ \(text)"))
			.font(.system(.callout, design: .default, weight: .regular))
	}
}
private struct OrderedListItemView: View {
	let index: Int
	let text: String

	var body: some View {
		Text(.init(" **\(index)**    \(text)"))
			.font(.system(.callout, design: .default, weight: .regular))
	}
}
private struct BlockquoteView: View {
	let text: String

	var body: some View {
		HStack {
			Rectangle()
				.frame(width: 2)
				.foregroundColor(.secondary)
			Text(.init(text))
				.font(.system(.body, design: .serif, weight: .light))
				.italic()
				.foregroundColor(.secondary)
		}
		.padding(.leading, 4)
	}
}
private struct MarkLinkView: View {
	let text: String
	let url: String

	var body: some View {
		Link(text, destination: URL(string: url)!)
			.foregroundColor(.indigo)
			.underline()
	}
}

// MARK: - Preview

public extension MarkdownView {
	struct ContentView: View {
		public static let markdownText = """

# Welcome to Markdown

Markdown is a lightweight markup language for creating formatted text. It’s easy to read and write, making it perfect for documentation, notes, and more.

## Features of Markdown

- **Headings**: Use `#` for headings.
- **Paragraphs**: Write plain text for paragraphs.
- **Lists**: Use `-` or `*` for unordered lists and numbers for ordered lists.
- **Code Blocks**: Use triple backticks (```` ``` ````) for code blocks.
- **Blockquotes**: Use `>` for blockquotes.
- **Links**: Use `[text](url)` for links.
- **Horizontal Rules**: Use `---` or `***` for horizontal rules.

---


### Example Code Block
Here’s an example of a Swift code block:
### Blockquotes
> Markdown is a great way to write content quickly and efficiently. It’s widely supported in many platforms, including GitHub, Reddit, and more.

### Lists

#### Unordered List

- Item 1
- Item 2
- Item 3

#### Ordered List

1. First item
2. Second item
3. Third item

### Links

Here are some useful links:

- [Markdown Guide](https://www.markdownguide.org)
- [Swift Documentation](https://developer.apple.com/swift/)
- [GitHub](https://github.com)

### Horizontal Rules

---

@Aung 's work place is #SimplyGo


### More Code Examples

#### Python

```python
def fibonacci(n):
 if n <= 1:
  return n
 else:
  return fibonacci(n-1) + fibonacci(n-2)

print(fibonacci(10))
"""

		public init() {}

		public var body: some View {
			ScrollView {
				MarkdownView(markdownText: Self.markdownText)
					.padding()
			}
			.navigationTitle("MarkdownView")
		}
	}
}
