//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct NativeMarkdownView: View {
    private let text: String
    public init(_ markdownText: String) {
        text = markdownText
    }

    public var body: some View {
        Text(.init(text))
            .tint(.link)
    }
}

public struct MarkdownView: View {
    let markdownText: String
    @State private var elements: [MarkdownElement] = []

    public init(markdownText: String) {
        self.markdownText = markdownText
        elements = MarkdownParser.parse(markdownText)
    }

    public init(elements: [MarkdownElement], text: String) {
        self.elements = elements
        markdownText = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(elements.enumerated()), id: \.offset) { _, element in
                renderElement(element)
            }
        }
        .equatable(by: markdownText)
    }

    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element {
        case let .heading(level, text):
            HeadingView(level: level, text: text)
        case let .paragraph(text):
            ParagraphView(text: text)
        case let .codeBlock(language, content):
            CodeBlockView(language: language, content: content)
                .textScale(.secondary)
        case let .listItem(text):
            ListItemView(text: text)
        case let .blockquote(text):
            BlockquoteView(text: text)
        case .horizontalRule:
            EmptyView()
        case let .unknown(text):
            Text(text)
                .foregroundColor(.gray)
        case let .orderedListItem(index: index, text: text):
            OrderedListItemView(index: index, text: text)
                .textScale(.secondary)
        case let .mention(username: username):
            Label(username, systemImage: "person.and.background.striped.horizontal")
                .labelIconToTitleSpacing(0)
                .fontWidth(.condensed)
                .imageScale(.small)
                .foregroundStyle(username.color.mix(with: Color.accentColor, by: 0.3))
                .symbolRenderingMode(.hierarchical)
        case let .hashtag(topic: topic):
            Label(topic, systemImage: "tag.square")
                .labelIconToTitleSpacing(4)
                .foregroundStyle(Color.link.mix(with: Color.accentColor, by: 0.2))
                .imageScale(.small)
                .symbolRenderingMode(.hierarchical)
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
                .font(
                    .system(
                        size: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize,
                        weight: .medium
                    )
                )
                .lineHeight(.loose)
        case 2:
            Text(text)
                .font(
                    .system(
                        size: UIFont.preferredFont(forTextStyle: .title1).pointSize,
                        weight: .medium
                    )
                )
                .lineHeight(.loose)
        case 3:
            Text(text)
                .font(
                    .system(
                        size: UIFont.preferredFont(forTextStyle: .title2).pointSize,
                        weight: .medium
                    )
                )
                .lineHeight(.loose)
        case 4:
            Text(text)
                .font(
                    .system(
                        size: UIFont.preferredFont(forTextStyle: .title3).pointSize,
                        weight: .medium
                    )
                )
                .lineHeight(.loose)
        default:
            Text(text)
                .font(
                    .system(
                        size: UIFont.preferredFont(forTextStyle: .headline).pointSize,
                        weight: .semibold
                    )
                )
                .lineHeight(.loose)
        }
    }
}

private struct ParagraphView: View {
    let text: String

    var body: some View {
        Text(.init(text))
    }
}

public struct CodeBlockView: View {
    let language: String?
    let content: String

    public init(language: String?, content: String) {
        self.language = language
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language {
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
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("∙")
                .bold()
            Text(.init(text))
        }
        .padding(.leading, 4)
        .lineSpacing(0)
    }
}

private struct OrderedListItemView: View {
    let index: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(index)")
            Text(.init(text))
        }
        .lineSpacing(0)
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
            .tint(.indigo)
            .underline()
    }
}

// MARK: - Preview

public extension MarkdownView {
    struct ExampleView: View {
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
        
        ## Links
        
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
